// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {USDC} from "../src/Tokens/USDCToken.sol";

contract USDCTokenTest is Test {
    USDC public contractAddress;

    function setUp() public {
        contractAddress = new USDC(address(1));
    }

    function test_Owner() public view {
        assert(contractAddress.owner() == address(1));
    }

    function test_decimals() public view {
        assert(contractAddress.decimals() == 6);
    }

    function test_Name() public {
        assertEq(contractAddress.name(), "USDC Token");
    }

    function test_Symbol() public {
        assertEq(contractAddress.symbol(), "USDC");
    }

    function test_Mint(uint256 amount, address testAddr) public {
        vm.prank(address(1));
        contractAddress.mint(testAddr, amount);
        assertEq(contractAddress.balanceOf(testAddr), amount);
    }

    function testFail_OtherMint(uint256 amount, address testAddr) public {
        vm.prank(address(2));
        contractAddress.mint(testAddr, amount);
        assertEq(contractAddress.balanceOf(testAddr), amount);
    }

    function test_Transfer(address to, uint256 amount) public {
        vm.prank(address(1));
        contractAddress.mint(address(2), amount);
        vm.prank(address(2));
        assert(contractAddress.transfer(to, amount));
        assert(contractAddress.balanceOf(to) == amount);
    }
}
