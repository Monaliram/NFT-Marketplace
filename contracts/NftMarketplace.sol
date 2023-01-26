// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftMarketplace is ReentrancyGuard, Ownable {

    ERC721 public nfts;
    
    mapping(uint256 => NFT) private _idToNFT;
    mapping(uint256 => bool) private isFixedPrice;
    mapping(uint256 => Auction) private _idAuction;
    mapping(address => mapping(uint256 => uint256)) bidRefunds;
    mapping(uint256 => address) private _owners;
    mapping(address => mapping(uint256 => uint256)) MakeOffer;
    mapping(address => uint256) offerTime;
 
    //Nft listing struct
    struct NFT{
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
        bool sold;
    }

    //Auction struct
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        bool isFirstBid;
        uint256 highestBid;
        address highestBidder;
        uint256 bidCount;
        uint256 minPrice;
        mapping(address => uint) userBid;
    }
    Auction[] private auctions;

    //Listing event
    event NFTListed(
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );
    //Buy nft event
    event Nftbought(
        address nftContract,
        uint256 tokenId,  
        address buyer, 
        address seller,
        uint256 price,
        uint256 offerPeriod,
        uint256 PayToSellerOfNft,
        uint256 adminRoyalty
    );
    //Offer Created
    event Offer(
        address nftContract,
        uint256 tokenId,
        uint256 offerPrice,
        address offerer,
        uint256 period
    );
    //accept offer
    event OfferAccepted(
        uint256 tokenId,
        address nftContract,
        address offerer,
        uint256 price,
        uint256 PayToSellerOfNft,
        uint256 AdminRoyalty
    );
    //withdraw offer
    event OfferWithdraw(
        uint256 tokenId,
        address offerere,
        uint256 amount
    );
    //nft auction event 
    event Auctionbid(
        address _creator, 
        uint256 amount
    );
    //Bidwithdraw event
    event BidWithdraw(
        uint256 tokenIdHash, 
        address bidder, 
        uint256 amount
    );
    //nft bid event
    event bidEnd(
        address highestBid,
        uint256 highestbidder,
        uint256 bidPayToSellerOfNft,
        uint256 bidAdminRoyalty
    );

    //Modifier Not owner
    modifier notNftOwner(uint256 _tokenId) {
        require(msg.sender != _owners[_tokenId], "Owner should not buy or bid NFT ");
        _;
    }
    //Modifier only owner
    modifier onlyNftOwner(uint256 _tokenId) {
         require(msg.sender == _owners[_tokenId], "Only owner can offer Nft");
        _;
    }

    //List Nft
    function listNft(address _nftContract, uint256 _tokenId, uint256 _price, bool isDirectBuy) public payable nonReentrant {
       require(_price > 0, "Price must be at least 1 wei");
       
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        _owners[_tokenId] = msg.sender;
    
        if(isDirectBuy){
            _idToNFT[_tokenId] = NFT(

            _nftContract,
            _tokenId, 
            payable(msg.sender),
            payable(address(this)),
            _price,
            true,
            false
        );
        isFixedPrice[_tokenId] = true;
        }
        else{
        _idAuction[_tokenId].tokenId = _tokenId;
        _idAuction[_tokenId].seller= msg.sender;
        _idAuction[_tokenId].minPrice =  _price;
        }
        emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), _price);
   }

    //Buy NFT
    function directBuy(uint256 _tokenId, address _nftContract, uint256 offerPeriod) public payable notNftOwner(_tokenId) nonReentrant{
        NFT storage nft = _idToNFT[_tokenId];
        
        require(isFixedPrice[_tokenId] , "NFT is not for direct buy or offer");
        require(!_idToNFT[_tokenId].sold, "Already sold");
        if(msg.value >= nft.price){ 
              
              uint256 buyPrice = msg.value;
              IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId );
              uint256 adminRoyaltyPercentage = 10;
              uint256 adminRoyalty = buyPrice * (adminRoyaltyPercentage) / 100;
              uint256 PayToSellerOfNft = buyPrice - adminRoyalty;

        address buyer = msg.sender;
        payable(nft.seller).transfer(PayToSellerOfNft);
        payable(owner()).transfer(adminRoyalty);
        nft.sold = true;

        emit Nftbought(_nftContract, nft.tokenId, nft.seller, buyer, msg.value, offerPeriod, PayToSellerOfNft, adminRoyalty);
        }
        else{ 
            require(msg.value > 0, "value must be greater than zero");
            MakeOffer[msg.sender][_tokenId] = msg.value;
            offerTime[msg.sender] = offerPeriod;
            emit Offer(_nftContract, _tokenId, msg.value,msg.sender,offerPeriod);
        }
    }

    //accept
    function acceptOffer(address _nftContract, uint256 _tokenId, address offerer) public onlyNftOwner(_tokenId) {

        require(!_idToNFT[_tokenId].sold, "Already sold");
        uint256 time = offerTime[offerer];

        require(block.timestamp <= time, "offer already ended");
        
        uint256 nftPrice = MakeOffer[offerer][_tokenId];
        
        uint256 adminRoyaltyPercentage = 10;
        uint256 adminRoyalty = nftPrice * (adminRoyaltyPercentage) / 100;
        uint256 PayToSellerOfNft =  nftPrice - adminRoyalty;

        IERC721(_nftContract).transferFrom(address(this), offerer,_tokenId);
        payable(owner()).transfer(adminRoyalty);
        payable(_idToNFT[_tokenId].seller).transfer(PayToSellerOfNft);

        _idToNFT[_tokenId].sold = true;

        emit OfferAccepted(_tokenId, _nftContract, offerer, nftPrice, PayToSellerOfNft, adminRoyalty);   

    }

    // withdraw offer
    function withdrawOffer(uint256 _tokenId) external {
        
        uint256 returnAmount = MakeOffer[msg.sender][_tokenId];

        require(returnAmount > 0, "No refund");

        MakeOffer[msg.sender][_tokenId] = 0;

        payable(msg.sender).transfer(returnAmount);

        emit OfferWithdraw(_tokenId, msg.sender, returnAmount);
    }

    //Resell nft
    function resellNft(address _nftContract, uint256 _tokenId, uint256 _price) public payable nonReentrant{
        
        require(_price > 0, "Price must be at least 1 wei");
        
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        NFT storage nft = _idToNFT[_tokenId];
        
        nft.seller = payable(msg.sender);
        nft.owner = payable(address(this));
        nft.listed = true;
        nft.price = _price;

        emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), _price);
    }

    //Bid nft
    function bid(uint256 _tokenId)public payable notNftOwner(_tokenId) {

        require(!isFixedPrice[_tokenId] , "Nft is not for auction.");
        
        if( _idAuction[_tokenId].isFirstBid == false) {
            require(msg.value >= _idAuction[_tokenId].minPrice, "Amount should be correct");
            _idAuction[_tokenId].endTime = block.timestamp+300; 
            _idAuction[_tokenId].isFirstBid = true;
        }
        else{
            require(block.timestamp < _idAuction[_tokenId].endTime, "Auction already ended");
            uint256 incremented_amount = (_idAuction[_tokenId].highestBid * 10) /100;
            uint256 amount =  _idAuction[_tokenId].highestBid + incremented_amount;
            require( msg.value >= amount, "Incremented amount should be maximum");
        }
        uint256 highestBid = _idAuction[_tokenId].highestBid;
        address highestBidder = _idAuction[_tokenId].highestBidder;

        uint256 _userPreviousBid =  _idAuction[_tokenId].userBid[msg.sender];
    
        _idAuction[_tokenId].userBid[msg.sender] = _userPreviousBid + msg.value;
        _idAuction[_tokenId].highestBid += _userPreviousBid + msg.value;
        

        if(highestBidder != address(0) && highestBidder != msg.sender){
            bidRefunds[highestBidder][_tokenId] += highestBid; // Record the refund that this user can claim
        }
       
        _idAuction[_tokenId].highestBid = msg.value;
        _idAuction[_tokenId].highestBidder = msg.sender;
        _idAuction[_tokenId].bidCount = _idAuction[_tokenId].bidCount + 1;
    
        emit Auctionbid(msg.sender, msg.value);
    }

    //withdraw
    function withdrawBidRefunds(uint256 _tokenId) external {

        require(_idAuction[_tokenId].isFirstBid , "Bid not started");
        require(block.timestamp >= _idAuction[_tokenId].endTime, "Auction not ended");
        uint256 refund = bidRefunds[msg.sender][_tokenId];
        require(refund > 0, "No refund");

        bidRefunds[msg.sender][_tokenId] = 0;

        payable(msg.sender).transfer(refund);

        emit BidWithdraw(_tokenId, msg.sender, refund);
    }

    // Claim Bid
    function claimBid(address _nftContract, uint256 _tokenId) external {

        require(block.timestamp >= _idAuction[_tokenId].endTime, "Auction not ended");
        require(msg.sender == _idAuction[_tokenId].highestBidder,"not winner");

        uint256 adminRoyaltyPercentage = 10;
        uint256 adminRoyalty = _idAuction[_tokenId].highestBid * (adminRoyaltyPercentage) / 100;
        uint256 PayToSellerOfNft = _idAuction[_tokenId].highestBid - adminRoyalty;

        IERC721(_nftContract).transferFrom(address(this), msg.sender,_tokenId);
        payable(owner()).transfer(adminRoyalty);
        payable(_idAuction[_tokenId].seller).transfer(PayToSellerOfNft);

        emit bidEnd(_idAuction[_tokenId].highestBidder, _idAuction[_tokenId].highestBid, PayToSellerOfNft, adminRoyalty);   
    }

}