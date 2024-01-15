// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
// import {PerpetualVault} from "../../src/Contracts/PerpetualVault.sol";
import {USDC} from "../../src/Tokens/USDCToken.sol";
import {WBTCToken} from "../../src/Tokens/WBTCToken.sol";
import {AggregatorV3Contract} from "../../src/Oracle/AggregatorV3Contract.sol";
import {PerpetualVaultHarness} from "./PerpetualVaultHarness.sol";

contract PerpetualVaultInternalTest is Test {
    USDC usdcToken;
    WBTCToken wBTCToken;

    PerpetualVaultHarness vault;

    error MaxLeverageExcedded();
    error LowPositionSize();

    function setUp() public {
        usdcToken = new USDC(address(1));
        wBTCToken = new WBTCToken(address(1));
        vault =
        new PerpetualVaultHarness(address(usdcToken) , address(wBTCToken) , usdcToken.name() , usdcToken.symbol() , address(1) );
    }

    function test_PositionOpeningFee(uint256 positionSize) public {
        vm.assume(positionSize < type(uint256).max / 100);
        assertEq(positionSize / 500, vault._calculatePositionOpeningFeeInternal(positionSize));
    }

    function test_GasStipend() public {
        assertEq(vault._getGasStipend(), 5 * 10 ** 6);
    }

    function test_absoluteValue() public {
        assertEq(vault._absouluteValueInternal(-100), 100);
        assertEq(vault._absouluteValueInternal(100), 100);
        assertEq(vault._absouluteValueInternal(0), 0);
    }

    function test_canSizeChange() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        assertEq(vault._canChangeSizeInternal(hashValue, 100, true), true);
        vm.stopPrank();
    }

    function test_CanChangeCollateral() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        assertEq(vault._canChangeCollateralInternal(hashValue, 20, true), true);
        vm.stopPrank();
    }

    function test_IsHealthyPosition() public {
        vm.startPrank(address(1));
        usdcToken.mint(address(2), 1000 * (10 ** usdcToken.decimals()));
        vm.stopPrank();
        vm.startPrank(address(2));
        usdcToken.approve(address(vault), 150 * (10 ** usdcToken.decimals()));
        bytes32 hashValue = vault.openPosition(100, 1000, true);
        bytes32 tempHash = vault._getPositionHash(address(2), 100, 1000, true);
        assertEq(tempHash, hashValue);
        assertEq(vault._isHealthyPositionInternal(hashValue), true);
        vm.stopPrank();
    }
}
