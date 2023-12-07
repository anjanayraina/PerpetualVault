pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle/AggregatorV3Contract.sol";
import "../Interfaces/AggregatorV3Interface.sol";

contract ChainLinkPriceFeed is Ownable {
    struct PriceFeeds {
        AggregatorV3Interface primaryPriceFeed;
        AggregatorV3Interface secondaryPriceFeed;
        int256 lastGoodPrice;
        uint8 decimals;
    }

    uint256 constant TIMEOUT = 1000;
    uint256 constant MAX_ALLOWED_DEVIATION = 10;
    mapping(string => PriceFeeds) tokenNameToPriceFeed;

    constructor(address owner) Ownable(owner) {}

    function addToken(
        string calldata tokenName,
        address primaryFeedAddress,
        address secondaryFeedAddress,
        int256 intialPrice,
        uint8 decimal
    ) external onlyOwner {
        PriceFeeds storage feed = tokenNameToPriceFeed[tokenName];
        feed.primaryPriceFeed = AggregatorV3Interface(primaryFeedAddress);
        feed.secondaryPriceFeed = AggregatorV3Interface(secondaryFeedAddress);
        feed.lastGoodPrice = intialPrice;
        feed.decimals = decimal;
    }

    function getPrice(string calldata tokenName) external view returns (int256) {
        PriceFeeds memory feed = tokenNameToPriceFeed[tokenName];
        (uint80 roundID, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.primaryPriceFeed.latestRoundData();
        if (
            roundID != 0 && price >= 0 && updatedAt <= block.timestamp && (block.timestamp - updatedAt) < TIMEOUT
                && _absoluteValue(price - feed.lastGoodPrice) < MAX_ALLOWED_DEVIATION*(10**decimals(tokenName))
        ) {
            feed.lastGoodPrice = price;
            return price * int256(10 ** decimals(tokenName));
        }

        (roundID, price, startedAt, updatedAt, answeredInRound) = feed.secondaryPriceFeed.latestRoundData();
        if (
            roundID != 0 && price >= 0 && updatedAt <= block.timestamp && (block.timestamp - updatedAt) < TIMEOUT
                && _absoluteValue(price - feed.lastGoodPrice) < MAX_ALLOWED_DEVIATION
        ) {
            feed.lastGoodPrice = price;
            return price * int256(10 ** decimals(tokenName));
        }

        return feed.lastGoodPrice * int256(10 ** decimals(tokenName));
    }

    function _absoluteValue(int256 value) internal pure returns (uint256) {
        return uint256(value >= 0 ? value : -value);
    }

    function decimals(string calldata tokenName) public view returns (uint8) {
        return tokenNameToPriceFeed[tokenName].decimals;
    }
}
