// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "solidity-cbor/ReadCbor.sol";
import "solidity-cbor/tags/ReadCidSha256.sol";

import "./ReadStrongRef.sol";

using ReadCbor for bytes;
using ReadStrongRef for bytes;

import "hardhat/console.sol";

// Subparser for facets in `post` object
// This has 2 objects: root and parent, each containing a com.atproto.repo.strongRef
library ReadFacet {
    bytes23 internal constant nsidFacet = "app.bsky.richtext.facet";

    function readFacetFeature(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        bytes32 mapKey;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 5); // did, uri or tag
            if (mapKey == "$type") {
                bytes32 _type;
                (byteIdx, _type, ) = cborData.String32(byteIdx, 31); //app.bsky.richtext.facet#mention
                // TODO: use the _type to decide what mapKey to expect!
            } else if (mapKey == "did") {
                (byteIdx, , ) = cborData.String32(byteIdx, 32);
                // Got a did!
            } else if (mapKey == "tag") {
                // Got a tag!
            } else if (mapKey == "uri") {
                // Got a uri!
            } else {
                revert("unexpected record key in facet feature");
            }
        }
        return byteIdx;
    }

    function readFacetIndex(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32, uint32 byteStart, uint32 byteEnd) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(
            mapLen == 2,
            "expected exactly 2 required fields in facet index"
        );

        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 9);
            if (mapKey == "byteStart") {
                (byteIdx, byteStart) = cborData.UInt8(byteIdx);
            } else if (mapKey == "byteEnd") {
                (byteIdx, byteEnd) = cborData.UInt8(byteIdx);
            } else {
                revert("unexpected record key in facet index");
            }
        }
        return (byteIdx, byteStart, byteEnd);
    }

    function readFacet(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32, string memory, string memory) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(mapLen >= 2, "expected at least 2 required fields in facet");

        bytes32 mapKey;

        string memory parent;
        string memory root;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 8);
            if (mapKey == "$type") {
                bytes32 _type;
                (byteIdx, _type, ) = cborData.String32(byteIdx, 23);
                require(_type == nsidFacet, "unexpected record type");
            } else if (mapKey == "index") {
                // Start and end for now!
                (byteIdx, , ) = readFacetIndex(cborData, byteIdx);
            } else if (mapKey == "features") {
                uint facetsLength;
                (byteIdx, facetsLength) = cborData.Array(byteIdx);
                for (uint j = 0; j < facetsLength; j++) {
                    byteIdx = readFacetFeature(cborData, byteIdx);
                }
            } else {
                revert("unexpected record key in facet");
            }
        }

        return (byteIdx, parent, root);
    }
}
