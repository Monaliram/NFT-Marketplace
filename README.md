# NFT Marketplace

## Quick Walkthrough

The ERC721 token and URI storage are handled by the OpenZeppelin libraries, and the creation of unique token IDs is handled by the Counters library. To stop reentrant attacks, it also makes use of the ReentrancyGuard contract.

## Functions

The contract includes several functions for buying and selling NFTs, including listNft(), directBuy(), acceptOffer(), withdrawOffer(), resellNft(), bid(), withdrawBidRefunds() and claimBid(). These functions allow users to list an NFT for sale, purchase an NFT, resell an NFT, and offer a listed NFT, Bid a listed NFT respectively. 

Overall, this contract provides a simple implementation of an NFT marketplace where users can buy and sell NFTs.
