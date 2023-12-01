// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AggregatorV3Contract is Ownable {
    uint8 decimal;
    int256 price;

    string desc;

    uint256 versionOfOracle = 1;

    constructor(address _owner, uint8 _decimal, int256 _price, string memory _description) Ownable(_owner) {
        decimal = _decimal;
        price = _price;
        desc = _description;
    }

    function decimals() external view returns (uint8) {
        return decimal;
    }

    function description() external view returns (string memory) {
        return desc;
    }

    function version() external view returns (uint256) {
        return versionOfOracle;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundID, int256 _price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundID = _roundId;
        _price = price ** decimal;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 3;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundID, int256 _price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundID = 1;
        _price = int256(uint256(price) * (10 ** decimal));
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 3;
    }

    function changePrice(int256 newPrice) external onlyOwner {
        price = newPrice;
    }
}
