// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "solidity-cbor/ReadCbor.sol";
import "solidity-cbor/tags/ReadCidSha256.sol";

import "./ReadStrongRef.sol";

using ReadCbor for bytes;
using ReadStrongRef for bytes;

// Subparser for reply in `post` object
// This has 2 objects: root and parent, each containing a com.atproto.repo.strongRef
library ReadReply {
    function readReply(
        bytes memory cborData,
        uint32 byteIdx
    ) internal pure returns (uint32, string memory, string memory) {
        uint32 mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen == 2, "expected 2 required fields in reply");

        bytes32 mapKey;

        string memory parent;
        string memory root;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, ) = cborData.String32(byteIdx, 6);
            if (mapKey == "parent") {
                (byteIdx, parent) = cborData.readStrongRef(byteIdx);
            } else if (mapKey == "root") {
                (byteIdx, root) = cborData.readStrongRef(byteIdx);
            } else {
                revert("unexpected record key in reply");
            }
        }

        return (byteIdx, parent, root);
    }
}
