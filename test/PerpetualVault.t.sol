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

    PerpetualVault vault;

    function setUp() public {
        usdcToken = new USDC(address(1));
        wBTCToken = new WBTCToken(address(1));
        vault = new PerpetualVault(usdcToken , wBTCToken , usdcToken.name() , usdcToken.symbol() , address(1) );
    }

    function test_BTCOracle() public {
        assertEq(address(vault.getBTCAddress()), address(wBTCToken));
    }

    function test_USDCOracle() public {
        assertEq(address(vault.getUSDCAddress()), address(usdcToken));
    }

    function test_USDCPrice() public {
        assertEq(vault._getUSDCPrice(), 10 ** 6);
    }

    function test_USDCDecimals() public {
        assertEq(usdcToken.decimals(), 6);
    }

    function test_GasStipend() public {
        assertEq(vault._getGasStipend(), 5 * 10 ** 6);
    }

    function test_USDCOwner() public {
        assertEq(usdcToken.owner(), address(1));
    }

    function test_openPosition() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        vm.stopPrank();
    }

    function test_ReturnPositionValues() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        PerpetualVault.Position memory position = vault.getPosition(hashValue);
        assertEq(tempHash, hashValue);
        assertEq(position.collateralInUSD, 100);
        assertEq(position.creationSizeInUSD, 1000);
        assertEq(position.isLong, true);
        assertEq(position.positionID ,hashValue);
        assertEq(position.positionOwner, address(2));
        assertEq(position.size , 1000/(100));
        vm.stopPrank();
    }

    function testFail_OpenPositionLessUSDC() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        vm.stopPrank();
    }

    function testFail_OpenPositionMaxLeverageExceeded() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 10000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        vm.stopPrank();
    }
}
