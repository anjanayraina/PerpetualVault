// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PerpetualVault} from "../src/Contracts/PerpetualVault.sol";
import {USDC} from "../src/Tokens/USDCToken.sol";
import {WBTCToken} from "../src/Tokens/WBTCToken.sol";
import {AggregatorV3Contract} from "../src/Oracle/AggregatorV3Contract.sol";
contract PerpetualVaultTest is Test {
    USDC usdcToken;
    WBTCToken wBTCToken;
    AggregatorV3Contract usdcOracle;
    AggregatorV3Contract btcOracle;
    AggregatorV3Contract ethOracle;

    PerpetualVault vault;

    function setUp() public {
        usdcToken = new USDC(address(1));
        wBTCToken = new WBTCToken(address(1));
        usdcOracle = new AggregatorV3Contract(address(1) , usdcToken.decimals() , 100 , "USDC Oracle");
        btcOracle = new AggregatorV3Contract(address(1) , wBTCToken.decimals() , 1000, "BTC Oracle");
        ethOracle = new AggregatorV3Contract(address(1) , 18 , 600 , "ETH Oracle");

        vault = new PerpetualVault(usdcToken , wBTCToken , usdcToken.name() , usdcToken.symbol() , address(btcOracle) , address(usdcOracle) ,address(ethOracle) , address(1) );
    }

    function test_BTCOracle() public {
    assertEq(address(vault.getBTCAddress()) ,address(wBTCToken));
    }

    function test_USDCOracle() public {
        assertEq(address(vault.getUSDCAddress()) ,address(usdcToken));
    }

    function test_GasStipend() public {

    }
    function test_openPosition() public {

    }

}