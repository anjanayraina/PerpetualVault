// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PerpetualVault} from "../../src/Contracts/PerpetualVault.sol";

contract PerpetualVaultHarness is PerpetualVault {
    constructor(
        address LPTokenAddress,
        address BTCTokenAddress,
        string memory name,
        string memory symbol,
        address owner
    ) PerpetualVault(LPTokenAddress, BTCTokenAddress, name, symbol, owner) {}

    function _calculatePositionOpeningFeeInternal(uint256 positionSize) public view returns (uint256) {
        return super._calculatePositionOpeningFee(positionSize);
    }

    function _getGasStipendInternal() public view returns (uint256) {
        return super._getGasStipend();
    }

    function _absouluteValueInternal(int256 value) public pure returns (uint256) {
        return super._absoluteValue(value);
    }

    function _canChangeSizeInternal(bytes32 positionID, uint256 sizeChange, bool isIncerement)
        public
        view
        returns (bool)
    {
        return super._canChangeSize(positionID, sizeChange, isIncerement);
    }

    function _canChangeCollateralInternal(bytes32 positionID, uint256 sizeChange, bool isIncement)
        public
        view
        returns (bool)
    {
        return super._canChangeCollateral(positionID, sizeChange, isIncement);
    }

    function _getPositionHashInternal(address owner, uint256 collateralInUSD, uint256 sizeInUSD, bool isLong)
        public
        pure
        returns (bytes32)
    {
        return super._getPositionHash(owner, collateralInUSD, sizeInUSD, isLong);
    }

    function _isHealthyPositionInternal(bytes32 positionID) public view returns (bool) {
        return super._isHealthyPosition(positionID);
    }
}
