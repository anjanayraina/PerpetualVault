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
        usdcOracle1 = new AggregatorV3Contract(address(1) , usdcToken.decimals() , int256(1*(10**usdcToken.decimals())) , "USDC Oracle");
        usdcOracle2 = new AggregatorV3Contract(address(1) , usdcToken.decimals() , int256(1*(10**usdcToken.decimals())), "USDC Oracle");
        feed = new ChainLinkPriceFeed(address(1));
        vm.startPrank(address(1));
        feed.addToken("USDC" , address(usdcOracle1) ,address(usdcOracle2) , int256(1*(10**usdcToken.decimals())) , usdcToken.decimals());
        vm.stopPrank();


    }

    function test_DecimalCheck() public {
        assertEq(feed.decimals("USDC") , 6);
    }

    function test_PriceCheck() public {
        assertEq(feed.getPrice("USDC") , int256(1*(10**usdcToken.decimals())));
    }

    function test_ChangeTokenPrice() public {
        vm.startPrank(address(1));
        usdcOracle1.changePrice(int256(11*(10**(usdcOracle1.decimals()-1))));
        usdcOracle2.changePrice(int256(11*(10**(usdcOracle2.decimals()-1))));
        assertEq(feed.getPrice("USDC") , int256(11*(10**(usdcOracle1.decimals()-1))));
        vm.stopPrank();

    }

    function testFail_UnAuthorizedAccess() public {
        vm.startPrank(address(2));
        usdcOracle1.changePrice(int256(11*(10**(usdcOracle1.decimals()-1))));
        vm.stopPrank();
    }

    function test_OtherOracleCheck() public {
        vm.startPrank(address(1));
        usdcOracle1.changePrice(int256(1100*(10**(usdcOracle1.decimals()-1))));
        usdcOracle2.changePrice(int256(11*(10**(usdcOracle2.decimals()-1))));
        assertEq(feed.getPrice("USDC") , int256(11*(10**(usdcOracle1.decimals()-1))));
        vm.stopPrank();
    }

}