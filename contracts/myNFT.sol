//SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract myNFT is ERC721URIStorage {

    uint256 public tokenCount;
    address marketplaceContract;
    
    mapping(uint => address) public tokenOwner;
    mapping(string => bool) private _usedTokenURIs;
   
    //mint nft event
    event Minted(
        uint256 nftID, 
        string uri
    );

    //admin mint nft event
    event adminMinted(
        uint256 nftId,
        string uri
    );

    constructor(address _marketplaceContract) ERC721("wbmNFTs", "WBM") {
        marketplaceContract = _marketplaceContract;
    }

    function tokenURIExists(string memory _tokenURI) public view returns (bool) {
    return _usedTokenURIs[_tokenURI] == true;
   }
    
    //Allows to Mint nft

    function Mint(string memory _tokenURI) public returns(uint256) {
        require(!tokenURIExists(_tokenURI), "Token URI already exists");
        tokenCount++;
        uint256 _tokenId = tokenCount;
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _usedTokenURIs[_tokenURI] = true;
        setApprovalForAll(marketplaceContract, true);

       
        emit Minted(_tokenId, _tokenURI);
        return _tokenId;  
    }
    
    //Allow to mint NFT 
    function adminMint(address _minter, string memory _tokenURI) external returns(uint256) {
        require(!tokenURIExists(_tokenURI), "Token URI already exists");
        tokenCount++;
        _mint(_minter, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        _usedTokenURIs[_tokenURI] = true;
        setApprovalForAll(marketplaceContract, true);
        
        emit adminMinted(tokenCount, _tokenURI);
        return tokenCount;
    }

}
