// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "solidity-cbor/ReadCbor.sol";
import "solidity-cbor/tags/ReadCidSha256.sol";

import "./ReadStrongRef.sol";

using ReadCbor for bytes;
using ReadStrongRef for bytes;

// Subparser for embed in `post` object
library ReadEmbed {
    function readEmbedImage(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        bytes32 mapKey;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 6);
            if (mapKey == "alt") {
                // skip alt
                byteIdx = cborData.skipString(byteIdx);
            } else if (mapKey == "image") {} else if (
                mapKey == "aspectRatio"
            ) {} else {
                revert("unexpected record key in image");
            }
        }
        // {
        //   alt: '',
        //   image: {
        //     '$type': 'blob',
        //     ref: {
        //       '$link': 'bafkreig5l2tdy6b43ukibqxbmlb7v54lgwrqyjtp2sojax46y2s74jpqti'
        //     },
        //     mimeType: 'image/jpeg',
        //     size: 878014
        //   },
        //   aspectRatio: { width: 1836, height: 1928 }
        // }
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
            } else {
                revert("unexpected record key in embed");
            }
        }

        return byteIdx;
    }
}
