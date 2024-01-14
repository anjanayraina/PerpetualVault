// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PerpetualVault} from "../../src/Contracts/PerpetualVault.sol";
import {USDC} from "../../src/Tokens/USDCToken.sol";
import {WBTCToken} from "../../src/Tokens/WBTCToken.sol";
import {AggregatorV3Contract} from "../../src/Oracle/AggregatorV3Contract.sol";

contract PerpetualVaultInvariantTest is Test {
    USDC usdcToken;
    WBTCToken wBTCToken;

    PerpetualVault vault;

    error MaxLeverageExcedded();
    error LowPositionSize();

    function setUp() public {
        usdcToken = new USDC(address(1));
        wBTCToken = new WBTCToken(address(1));
        vault =
        new PerpetualVault(address(usdcToken) , address(wBTCToken) , usdcToken.name() , usdcToken.symbol() , address(1) );
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

    function test_openPosition(uint256 collateral, uint256 size) public {
        vm.assume(collateral != 0);
        vm.assume(size != 0);
        vm.assume(size > 100);
        vm.assume(size < type(uint128).max);
        vm.assume(size > collateral);
        vm.assume((collateral) / (10 ** (usdcToken.decimals() + 1)) < type(uint256).max);
        vm.assume(size / collateral < 21);
        vm.startPrank(address(1));
        usdcToken.mint(address(2), (collateral *2) * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        uint256 prevBalance = usdcToken.balanceOf(address(vault));
        usdcToken.approve(address(vault), (collateral*2) * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(collateral, size, true);
        bytes32 tempHash = vault._getPositionHash(address(2), collateral, size, true);
        assertEq(tempHash, hashValue);
        assertGt(usdcToken.balanceOf(address(vault)), prevBalance);
        vm.stopPrank();
    }

    function testFail_openPositionLimitExcedded(uint256 collateral, uint256 size) public {
        vm.assume(collateral != 0);
        vm.assume(size != 0);
        vm.assume(size > 100);
        vm.assume(size < type(uint128).max);
        vm.assume(size > collateral);
        vm.assume((collateral) / (10 ** (usdcToken.decimals() + 1)) < type(uint256).max);
        vm.assume(size / collateral > 20);

        vm.startPrank(address(1));
        usdcToken.mint(address(2), (collateral + 1) * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        uint256 prevBalance = usdcToken.balanceOf(address(vault));
        usdcToken.approve(address(vault), collateral * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(collateral, size, true);
        bytes32 tempHash = vault._getPositionHash(address(2), collateral, size, true);
        assertEq(tempHash, hashValue);
        assertGt(usdcToken.balanceOf(address(vault)), prevBalance);
        vm.stopPrank();
    }

    function testFail_openPositionLowPositionSize(uint256 collateral, uint256 size) public {
        vm.assume(collateral != 0);
        vm.assume(size != 0);
        vm.assume(size < 100);
        vm.assume(size < type(uint128).max);
        vm.assume(size > collateral);
        vm.assume((collateral) / (10 ** (usdcToken.decimals() + 1)) < type(uint256).max);
        vm.assume(size / collateral < 21);

        vm.startPrank(address(1));
        usdcToken.mint(address(2), (collateral + 1) * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        uint256 prevBalance = usdcToken.balanceOf(address(vault));
        usdcToken.approve(address(vault), collateral * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(collateral, size, true);
        bytes32 tempHash = vault._getPositionHash(address(2), collateral, size, true);
        assertEq(tempHash, hashValue);
        assertGt(usdcToken.balanceOf(address(vault)), prevBalance);
        vm.stopPrank();
    }
}
