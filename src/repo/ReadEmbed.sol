// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "solidity-cbor/ReadCbor.sol";
import "solidity-cbor/tags/ReadCidSha256.sol";

import "./ReadStrongRef.sol";

using ReadCbor for bytes;
using ReadStrongRef for bytes;

// Subparser for embed in `post` object
library ReadEmbed {
    function readSimpleRef(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32, string memory link) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(mapLen == 1, "expected exactly 1 field in simple ref");
        bytes32 mapKey;
        (byteIdx, mapKey, ) = cborData.String32(byteIdx, 5);
        require(mapKey == "$link", "expected ref to have $link key");
        (byteIdx, link) = cborData.String(byteIdx);
        return (byteIdx, link);
    }

    function readEmbedImageAspectRatio(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32, uint16 width, uint16 height) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(
            mapLen == 2,
            "expected exactly 2 required fields in image aspect ratio"
        );

        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 6);
            if (mapKey == "width") {
                (byteIdx, width) = cborData.UInt16(byteIdx);
            } else if (mapKey == "height") {
                (byteIdx, height) = cborData.UInt16(byteIdx);
            } else {
                revert("unexpected record key in facet index");
            }
        }
        return (byteIdx, width, height);
    }

    function readEmbedImageImage(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(mapLen == 4, "expected exactly 4 required fields in image");
        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 9);
            if (mapKey == "$type") {
                // Should be `blob`
                (byteIdx, , ) = cborData.String32(byteIdx, 4);
            } else if (mapKey == "mimeType") {
                // image/jpeg
                (byteIdx, , ) = cborData.String32(byteIdx, 10);
            } else if (mapKey == "ref") {
                (byteIdx, ) = readSimpleRef(cborData, byteIdx);
            } else if (mapKey == "size") {
                uint32 size;
                (byteIdx, size) = cborData.UInt32(byteIdx);
            } else {
                revert("unexpected record key in image image");
            }
        }

        return byteIdx;
    }

    function readEmbedImage(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 11);
            if (mapKey == "alt") {
                // skip alt
                byteIdx = cborData.skipString(byteIdx);
            } else if (mapKey == "image") {
                byteIdx = readEmbedImageImage(cborData, byteIdx);
            } else if (mapKey == "aspectRatio") {
                (byteIdx, , ) = readEmbedImageAspectRatio(cborData, byteIdx);
            } else {
                console.log("unexpected record key in image");
                revert("unexpected record key in image");
            }
        }
        return byteIdx;
    }

    function readEmbed(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen == 2, "expected 2 required fields in embed");

        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 6);
            if (mapKey == "$type") {
                (byteIdx, , ) = cborData.String32(byteIdx, 21);
                // TODO: act differently based on type...
            } else if (mapKey == "images") {
                // We have an array of images!
                uint facetsLength;
                (byteIdx, facetsLength) = cborData.Array(byteIdx);
                for (uint j = 0; j < facetsLength; j++) {
                    byteIdx = readEmbedImage(cborData, byteIdx);
                }
            } else if (mapKey == "record") {
                (byteIdx, ) = cborData.readStrongRef(byteIdx);
            } else {
                revert("unexpected record key in embed");
            }
        }

        return byteIdx;
    }
}
