// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AggregatorV3Contract} from "../src/Oracle/AggregatorV3Contract.sol";

contract AggregatorV3ContractTest is Test {
    AggregatorV3Contract oracle;

    function setUp() public {
        oracle = new AggregatorV3Contract(address(1) , 6 , 100 , "Oracle");
    }

    function test_CheckDecimal() public {
        assertEq(oracle.decimals(), 6);
    }

    function test_checkVersion() public {
        assertEq(oracle.version(), 1);
    }

    function test_checkPrice() public {
        (, int256 price,,,) = oracle.latestRoundData();
        assertEq(price, 100 * (10 ** 6));
    }
}
