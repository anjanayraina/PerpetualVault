// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {WBTCToken} from "../src/Tokens/WBTCToken.sol";

contract wBTCTokenTest is Test {

    WBTCToken public contractAddress;
    function setUp() public {
        contractAddress = new WBTCToken(address(1));

    }

    function test_Owner() public view  {
        assert(contractAddress.owner() == address(1));

    }

    function test_decimals() public view {
        assert(contractAddress.decimals() == 8);
    }

    function test_Name() public {
        assertEq(contractAddress.name() , "BTC Token" );
    }

    function test_Symbol() public {
        assertEq(contractAddress.symbol() , "wBTC" );
    }

    function test_Mint(uint amount , address testAddr) public {
        vm.prank(address(1));
        contractAddress.mint(  testAddr, amount);
        assertEq(contractAddress.balanceOf(testAddr) , amount);      
    }

    function testFail_OtherMint(uint amount , address testAddr) public {
        contractAddress.mint(  testAddr, amount);
        assertEq(contractAddress.balanceOf(testAddr), amount);     
    }

    function test_Transfer(address to , uint amount) public {
        vm.prank(address(1));
        contractAddress.mint(address(2), amount);
        vm.prank(address(2));
        assert(contractAddress.transfer(to , amount));
        assert(contractAddress.balanceOf(to) == amount);
    }

}