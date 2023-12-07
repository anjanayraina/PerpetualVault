pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ChainLinkPriceFeed} from "../src/PriceFeed/ChainLinkPriceFeed.sol";
import {USDC} from "../src/Tokens/USDCToken.sol";
import {WBTCToken} from "../src/Tokens/WBTCToken.sol";
import {AggregatorV3Contract} from "../src/Oracle/AggregatorV3Contract.sol";

contract ChainLinkPriceFeedTest is Test {
    USDC usdcToken;
    AggregatorV3Contract usdcOracle1;
    AggregatorV3Contract usdcOracle2;
    ChainLinkPriceFeed feed ;

     function setUp() public {
        usdcToken = new USDC(address(1));
        usdcOracle1 = new AggregatorV3Contract(address(1) , usdcToken.decimals() , 1 , "USDC Oracle");
        usdcOracle2 = new AggregatorV3Contract(address(1) , usdcToken.decimals() , 1, "USDC Oracle");
        feed = new ChainLinkPriceFeed(address(1));
        vm.startPrank(address(1));
        feed.addToken("USDC" , address(usdcOracle1) ,address(usdcOracle2) , 1 , usdcToken.decimals());


    }

    function test_PriceCheck() public {
        
    }

}