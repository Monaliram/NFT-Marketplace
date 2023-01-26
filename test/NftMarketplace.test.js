const { expect, assert } = require("chai");
const helper = require("./helper");

const myNFT = artifacts.require("myNFT");
const NftMarketplace = artifacts.require("NftMarketplace");

contract("myNFT", async (accounts) => {
  let nft;
  let marketplace;
  const URI = "https://test.com";
  const URI1 = "https://test1.com";
  const URI2 = "https://test2.com";

  beforeEach(async () => {
    nft = await myNFT.deployed();
    marketplace = await NftMarketplace.deployed();
  });

  describe("Deployment", function () {
    it("Should track name and symbol of the nft collection", async function () {
      const nftName = "wbmNFTs";
      const nftSymbol = "WBM";
      expect(await nft.name()).to.equal(nftName);
      expect(await nft.symbol()).to.equal(nftSymbol);
    });
  });

  describe("Minting NFts", function () {
    before(async () => {
      await nft.Mint(URI, {
        from: accounts[0],
      });
    });

    it("first token should point to the correct tokenURI", async () => {
      const actualTokenURI = await nft.tokenURI(1);

      assert.equal(actualTokenURI, URI, "tokenURI is not correctly set");
    });

    it("owner of the first token should be address[0]", async () => {
      const owner = await nft.ownerOf(1);
      assert.equal(
        owner,
        accounts[0],
        "Owner of token is not matching address[0]"
      );
    });

    it("should not be possible to create a NFT with used tokenURI", async () => {
      //negative
      try {
        await nft.Mint(URI, {
          from: accounts[0],
        });
      } catch (error) {
        assert(error, "NFT was minted with previously used tokenURI");
      }
    });
  });

  describe("Nft Listing", function () {
    it("should list the minted nft", async () => {
      const tokenId = 1;
      const price = 10;
      await marketplace.listNft(nft.address, tokenId, price, true, {
        from: accounts[0],
      });
    });
    it("should mint and list second minted nft", async () => {
      await nft.Mint(URI1, { from: accounts[0] });
      const tokenId1 = 2;
      const price = 10;
      await marketplace.listNft(nft.address, tokenId1, price, false, {
        from: accounts[0],
      });
    });
  });

  describe("Buying and reselling", function () {
    tokenId = 1;
    _nftPrice = 10;
    before(async () => {
      await marketplace.directBuyNft(tokenId, nft.address, {
        from: accounts[1],
        value: _nftPrice,
      });
    });
    it("NFT is not for direct buy", async () => {
      //negative
      tokenId1 = 2;
      try {
        const res = await marketplace.directBuyNft(tokenId1, nft.address, {
          from: accounts[2],
          value: 10,
        });
      } catch (error) {
        assert(error, "Nft is not for direct buy");
      }
    });
    it("should change the owner", async () => {
      const currentOwner = await nft.ownerOf(1);
      assert.equal(currentOwner, accounts[1], "Item is still listed");
    });
    it("Should approve nft for resell", async () => {
      await nft.approve(marketplace.address, tokenId, {
        from: accounts[1],
      });
    });
    it("resell the Nft", async () => {
      await marketplace.resellNft(nft.address, tokenId, _nftPrice, {
        from: accounts[1],
        value: 100,
      });
    });
  });
  describe("Nft Auction", async () => {
    it("Check minted and listed NFt is for auction", async () => {
      //negative
      tokenId = 1;
      try {
        const res = await marketplace.bid(tokenId, {
          from: accounts[2],
          value: 10,
        });
      } catch (error) {
        assert(error, "Nft is not for auction");
      }
    });
    it("Auction creator should not bid", async () => {
      tokenId1 = 2;
      try {
        const res = await marketplace.bid(tokenId1, {
          from: accounts[0],
          value: 10,
        });
      } catch (error) {
        assert(error, "Auction owner should not bid");
      }
    });
    it("bid first Nft successfully", async () => {
      tokenid1 = 2;
      await marketplace.bid(tokenId1, {
        from: accounts[2],
        value: 100,
      });
    });
    it("should throw for bids if price is below 10% than previous price", async function () {
      tokenId1 = 2;
      _nftPrice = 10;
      try {
        const res = await marketplace.bid(tokenid1, {
          from: accounts[2],
          value: _nftPrice,
        });
      } catch (error) {
        assert(error, "Nft price should be maximum");
      }
    });
    it("Should throw if bid is already ended", async () => {
      tokenId1 = 2;
      _nftPrice = 100;
      try {
        const res = await marketplace.bid(tokenId1, {
          from: accounts[2],
          value: _nftPrice,
        });
      } catch (error) {
        assert(error, "Auction already ended");
      }
    });
    it("Auction winner can claim nft", async () => {
      tokenId2 = 3;
      price = 10;
     

      await nft.Mint(URI2, {
        from: accounts[0],
      });
      await marketplace.listNft(nft.address, tokenId2, price, false, {
        from: accounts[0],
      });
      await marketplace.bid(tokenId2, {
        from: accounts[1],
        value: 100,
      });
      await marketplace.bid(tokenId2, {
        from: accounts[2],
        value: 1000,
      });
        await helper.advanceTimeAndBlock(60 * 3);
        const res = await marketplace.claimBid(nft.address, tokenId2, {
          from: accounts[2],
        });
        const withdraw = await marketplace.withdrawBidRefunds(tokenId2 , {
          from: accounts[1],
        });
    });
  });
});
