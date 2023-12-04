pragma solidity 0.8.21;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle/AggregatorV3Contract.sol";
import "../Interfaces/AggregatorV3Interface.sol";
contract ChainLinkPriceFeed is Ownable{

    struct PriceFeeds{
        AggregatorV3Interface primaryPriceFeed;
        AggregatorV3Interface secondaryPriceFeed;
        int256 lastGoodPrice;
    }

    uint256 constant TIMEOUT = 1000; 
    mapping(string=>PriceFeeds) tokenNameToPriceFeed;
    constructor(address owner) Ownable(owner){

    }
    function addToken(string calldata tokenName , address primaryFeedAddress ,address secondaryFeedAddress , int256 intialPrice) external onlyOwner{
        PriceFeeds storage feed = tokenNameToPriceFeed[tokenName];
        feed.primaryPriceFeed = AggregatorV3Interface(primaryFeedAddress);
        feed.secondaryPriceFeed = AggregatorV3Interface(secondaryFeedAddress); 
        feed.lastGoodPrice = intialPrice;
    }

    // function changePrimaryFeed(string calldata tokenName , address primaryFeedAddress) external onlyOwner{
    //     feed.primaryFeedAddress = AggregatorV3Interface(primaryFeedAddress);
    // }

    // function changeSecondaryFeed(string calldata tokenName , address secondaryFeedAddress) external onlyOwner {
    //     feed.secondaryFeedAddress = AggregatorV3Interface(secondaryFeedAddress);
    // }


    function getPrice(string calldata tokenName ) external returns(int256 )  {
        PriceFeeds memory feed = tokenNameToPriceFeed[tokenName];
        (uint80 roundID , int256 price , uint256 startedAt , uint256 updatedAt , uint80 answeredInRound) = feed.primaryPriceFeed.latestRoundData();
        if(roundID != 0 && price >=0 && updatedAt <= block.timestamp && (block.timestamp - updatedAt) <TIMEOUT ){
            feed.lastGoodPrice = price;
            return price;
        }

       ( roundID ,  price ,  startedAt ,  updatedAt ,  answeredInRound) = feed.secondaryPriceFeed.latestRoundData();
       if(roundID != 0 && price >=0 && updatedAt <= block.timestamp && (block.timestamp - updatedAt) <TIMEOUT ){
            feed.lastGoodPrice = price;
            return price;
        }

        return feed.lastGoodPrice;

    }

    


}