import { ethers } from "hardhat";
// Get all the post
// parse them one by one!
import { BskyHandler } from "../typechain-types/BskyHandler";

import cbor from "cbor";

describe("Bluesky posts", () => {
  let bsky: BskyHandler;

  before(async () => {
    bsky = await ethers.deployContract("BskyHandler", []);
  });

  it("should parse them all", async () => {
    const endpoint = `https://bsky.social/xrpc/com.atproto.repo.listRecords?repo=did:plc:4lhnf4celyqbbchcsoi7i4vo&collection=app.bsky.feed.post&limit=100`;
    const response = await fetch(endpoint);
    const { records } = await response.json();
    for (let i = 24; i < records.length; i++) {
      const value = cbor.encode(records[i].value);
      try {
        await bsky.parse(value);
      } catch (error) {
        console.error(
          `Failed to parse record ${i}: ${records[i].uri} with value:`,
          JSON.stringify(records[i].value, null, 2)
        );
        throw error;
      }
    }
  });
});
