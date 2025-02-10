pragma solidity ^0.8.28;
import {AppBsky} from "./records/app/bsky/Feed.sol";

// SPDX-License-Identifier: Unlicense
contract BskyHandler {
    function parse(bytes memory skeet) public pure {
        AppBsky.readFeedPost(skeet);
    }
}
