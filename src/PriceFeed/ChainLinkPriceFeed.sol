pragma solidity 0.8.21;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle/AggregatorV3Contract.sol";
contract ChainLinkPriceFeed is Ownable{
    struct PriceFeeds{
        address primaryPriceFeed;
        address secondaryPriceFeed;
        int256 lastGoodPrice;
    }
    mapping(string=>PriceFeeds) tokenNameToPriceFeed;
    constructor(address owner) Ownable(owner){

    }

    function addToken(string calldata tokenName , address primaryFeedAddress ,address secondaryFeedAddress) external onlyOwner{
        PriceFeeds storage feed = tokenNameToPriceFeed[tokenName];
        feed.primaryPriceFeed = primaryFeedAddress;
        feed.secondaryPriceFeed = secondaryPriceFeed; 
    }

    function changePrimaryFeed(string calldata tokenName , address primaryFeedAddress) external onlyOwner{
        feed.primaryFeedAddress = primaryFeedAddress;
    }

    function changeSecondaryFeed(string calldata tokenName , address secondaryFeedAddress) external onlyOwner {
        feed.secondaryFeedAddress = secondaryFeedAddress;
    }



}