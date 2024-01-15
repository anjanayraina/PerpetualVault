// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
// import {PerpetualVault} from "../../src/Contracts/PerpetualVault.sol";
import {USDC} from "../../src/Tokens/USDCToken.sol";
import {WBTCToken} from "../../src/Tokens/WBTCToken.sol";
import {AggregatorV3Contract} from "../../src/Oracle/AggregatorV3Contract.sol";
import {PerpetualVaultHarness} from "./PerpetualVaultHarness.sol";

contract PerpetualVaultInternalTest is  Test {
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
        assertEq(positionSize / 500 , vault._calculatePositionOpeningFeeInternal(positionSize));
    }

    function test_GasStipend() public {
        assertEq(vault._getGasStipend(), 5 * 10 ** 6);
    }

}