pragma solidity 0.8.21;

// testnet oracle : https://sepolia.etherscan.io/address/0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD
// wBTC/USDC pool
// how is the value of a share of the pool set ??
// GOALS
// - 1. Liquidity Providers can deposit and withdraw liquidity []
// - 2. Traders can open a perpetual position for BTC, with a given size and collateral [Done]
// - 3. A way to get the realtime price of the asset being traded [Done]
// - 4. Traders cannot utilize more than a configured percentage of the deposited liquidity []
// - 5. Traders can increase the size of a perpetual position [Done]
// - 6. Traders can increase the collateral of a perpetual position [Done]
// - 7. Liquidity providers cannot withdraw liquidity that is reserved for positions  []
// - 8. Traders can decrease the size of their position and realize a proportional amount of their PnL [Done]
// - 9. Traders can decrease the collateral of their position [Done]
// - 10. Individual position’s can be liquidated with a liquidate function, any address may invoke the liquidate function [Done]
// - 11. A liquidatorFee is taken from the position’s remaining collateral upon liquidation with the liquidate function and given to the caller of the liquidate function []
// - 12. Traders can never modify their position such that it would make the position liquidatable [Done]
// - 13. Traders are charged a borrowingFee which accrues as a function of their position size and the length of time the position is open []
// - 14. Traders are charged a positionFee from their collateral whenever they change the size of their position, the positionFee is a percentage of the position size delta (USD converted to collateral token). — Optional/Bonus []
// - 15. Implement Double Oracle System in the contract [Done]
// - 16. Interagte the Double Oracle System in PerpetualVault Contract [Done]
// problem with wBTC decimals

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "../PriceFeed/ChainLinkPriceFeed.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle/AggregatorV3Contract.sol";

contract PerpetualVault is ERC4626, Ownable {
    uint8 public constant MAX_LEVERAGE = 20;
    uint8 public constant GAS_STIPEND = 5;
    uint8 public MIN_POSITION_SIZE = 20;
    IERC20 public wBTCToken;
    IERC20 public USDCToken;
    ChainLinkPriceFeed priceFeed;
    uint256 initialBTCInUSDLong;
    uint256 initialBTCInUSDShort;
    uint256 btcSizeOpenedLong;
    uint256 btcSizeOpenedShort;
    uint256 initialBTCInUSD;

    struct Position {
        address positionOwner;
        uint256 collateralInUSD;
        bool isLong;
        uint256 creationSizeInUSD;
        bytes32 positionID;
        uint256 size;
    }

    mapping(bytes32 => Position) private openPositons;

    error MaxLeverageExcedded();
    error LowCollateral();
    error LowPositionSize();
    error NotThePositionOwner();
    error PositionDoesNotExist();
    error LowPositionCollateral();
    error PositionHealthy();
    error CannotChangeCollateral();
    error CannotChangeSize();
    error TestRevert(uint256);

    constructor(IERC20 LPTokenAddress, IERC20 BTCTokenAddress, string memory name, string memory symbol, address owner)
        ERC4626(LPTokenAddress)
        ERC20(name, symbol)
        Ownable(owner)
    {
        wBTCToken = BTCTokenAddress;
        USDCToken = LPTokenAddress;
        priceFeed = new ChainLinkPriceFeed(address(this));
        priceFeed.addToken(
            "USDC",
            address(
                new AggregatorV3Contract(msg.sender , USDCToken.decimals() , int256(1*(10**USDCToken.decimals())) , "Oracle")
            ),
            address(
                new AggregatorV3Contract(msg.sender , USDCToken.decimals() , int256(1*(10**USDCToken.decimals())) , "Oracle")
            ),
            1,
            USDCToken.decimals()
        );
        priceFeed.addToken(
            "WBTC",
            address(
                new AggregatorV3Contract(msg.sender , wBTCToken.decimals() , int256(100*(10**wBTCToken.decimals())) , "Oracle")
            ),
            address(
                new AggregatorV3Contract(msg.sender , wBTCToken.decimals() , int256(100*(10**wBTCToken.decimals())) , "Oracle")
            ),
            int256(100 * (10 ** wBTCToken.decimals())),
            wBTCToken.decimals()
        );
    }

    modifier onlyPositionOwner(bytes32 positionID) {
        if (openPositons[positionID].positionOwner != msg.sender) {
            revert NotThePositionOwner();
        }
        _;
    }

    function getBTCAddress() public view returns (IERC20) {
        return wBTCToken;
    }

    function getUSDCAddress() public view returns (IERC20) {
        return USDCToken;
    }

    function totalAssets() public view override(ERC4626) returns (uint256) {
        int256 pnl = getSystemPNL();
        if (pnl <= 0) {
            return super.totalAssets();
        }
        return super.totalAssets() - _absoluteValue(pnl);
    }

    function withdraw(uint256 assets, address reciever, address owner) public override(ERC4626) returns (uint256) {}

    function openPosition(uint256 collateralInUSD, uint256 sizeInUSD, bool isLong) external returns (bytes32) {
        if (collateralInUSD == 0) {
            revert LowCollateral();
        }
        if (sizeInUSD < MIN_POSITION_SIZE) {
            revert LowPositionSize();
        }
        if (sizeInUSD / collateralInUSD > MAX_LEVERAGE) {
            revert MaxLeverageExcedded();
        }

        bytes32 positionHash = _getPositionHash(msg.sender, collateralInUSD, sizeInUSD, isLong);
        uint256 usdcPrice = _getUSDCPrice() / (10 ** priceFeed.decimals("USDC"));
        uint256 btcPrice = _getBTCPrice() / (10 ** priceFeed.decimals("WBTC"));
        USDCToken.transferFrom(msg.sender, address(this), (collateralInUSD + _getGasStipend()) / usdcPrice);
        openPositons[positionHash] =
            Position(msg.sender, collateralInUSD, isLong, sizeInUSD, positionHash, sizeInUSD / btcPrice);
        return positionHash;
    }

    function increasePositionSize(bytes32 positionID, uint256 sizeChange) external onlyPositionOwner(positionID) {
        Position storage position = _getPosition(positionID);
        if (!_canChangeSize(positionID, sizeChange, true)) {
            revert CannotChangeSize();
        }

        position.size = position.size + sizeChange;
        uint256 btcPrice = _getBTCPrice() / ((10**priceFeed.decimals("WBTC")));
        position.creationSizeInUSD = position.size * btcPrice ;
        
    }

    function decreasePositionSize(bytes32 positionID, uint256 sizeChange) external onlyPositionOwner(positionID) {
        Position storage position = _getPosition(positionID);
        if (!_canChangeSize(positionID, sizeChange, false)) {
            revert CannotChangeSize();
        }

        position.size = position.size - sizeChange;
        if(position.size!=9){
            revert("test revert");
        }
        uint256 btcPrice = _getBTCPrice() / ((10**priceFeed.decimals("WBTC")));
        position.creationSizeInUSD = position.creationSizeInUSD - sizeChange * btcPrice;
    }

    function increasePositionCollateral(bytes32 positionID, uint256 collateralChange)
        external
        onlyPositionOwner(positionID)
    {
        Position storage position = _getPosition(positionID);
        if (!_canChangeCollateral(positionID, collateralChange, true)) {
            revert CannotChangeCollateral();
        }
        uint256 usdcPrice = _getUSDCPrice() / priceFeed.decimals("USDC");
        position.collateralInUSD = position.collateralInUSD + collateralChange * usdcPrice;
    }

    function decreasePositionCollateral(bytes32 positionID, uint256 collateralChange)
        external
        onlyPositionOwner(positionID)
    {
        Position storage position = _getPosition(positionID);
        if (!_canChangeCollateral(positionID, collateralChange, false)) {
            revert CannotChangeCollateral();
        }
        uint256 usdcPrice = _getUSDCPrice() / priceFeed.decimals("USDC");
        position.collateralInUSD = position.collateralInUSD - collateralChange * usdcPrice;
    }

    function liquidate(bytes32 positionID) external {
        Position memory position = getPosition(positionID);
        if (_isHealthyPosition(positionID) && position.positionOwner != msg.sender) {
            revert PositionHealthy();
        }
        uint256 usdcPrice = _getUSDCPrice() / priceFeed.decimals("USDC");
        int256 pnl = _getPNL(positionID);
        uint256 amountToReturn;
        if (pnl < 0) {
            if (_absoluteValue(pnl) > position.collateralInUSD) {
                amountToReturn = position.collateralInUSD;
            } else {
                amountToReturn = position.collateralInUSD - _absoluteValue(pnl);
            }
        } else {
            amountToReturn = position.collateralInUSD + uint256(pnl);
        }

        uint256 gasStipend = _getGasStipend();
        USDCToken.transferFrom(address(this), position.positionOwner, amountToReturn / usdcPrice);
        USDCToken.transferFrom(address(this), msg.sender, gasStipend);
    }

    function _getBTCPrice() internal view returns (uint256) {
        int256 price = priceFeed.getPrice("WBTC");
        return uint256(price);
    }

    function _getUSDCPrice() public view returns (uint256) {
        int256 price = priceFeed.getPrice("USDC");
        return uint256(price);
    }

    function _getETHPrice() internal view returns (uint256) {
        int256 price = priceFeed.getPrice("ETH");
        return uint256(price);
    }

    function _getPNL(bytes32 positionID) public view returns (int256) {
        Position memory position = _getPosition(positionID);
        uint256 btcPrice = _getBTCPrice() / priceFeed.decimals("WBTC");
        uint256 currentPositionPrice = position.size * btcPrice;
        if (position.isLong) {
            return int256(int256(currentPositionPrice) - int256(position.creationSizeInUSD));
        }

        return int256(int256(position.creationSizeInUSD) - int256(currentPositionPrice));
    }

    function getSystemPNL() public view returns (int256) {
        return getLongPNL() + getShortPNL();
    }

    function getLongPNL() public view returns (int256) {
        uint256 btcPrice = _getBTCPrice() / priceFeed.decimals("WBTC");
        return int256(initialBTCInUSDLong) - int256(btcSizeOpenedLong * btcPrice);
    }

    function getShortPNL() public view returns (int256) {
        uint256 btcPrice = _getBTCPrice() / priceFeed.decimals("WBTC");
        return int256(btcSizeOpenedShort * btcPrice) - int256(initialBTCInUSDShort);
    }

    function getPosition(bytes32 positionID) public view returns (Position memory) {
        return openPositons[positionID];
    }

    function _getPosition(bytes32 positionID) internal view returns (Position storage) {
        return openPositons[positionID];
    }

    function _isHealthyPosition(bytes32 positionID) public view returns (bool) {
        int256 pnl = _getPNL(positionID);
        Position memory position = getPosition(positionID);
        uint256 adjustedCollateral;
        if (pnl < 0) {
            adjustedCollateral = position.collateralInUSD - _absoluteValue(pnl);
        } else {
            adjustedCollateral = position.collateralInUSD + uint256(pnl);
        }
        uint256 btcPrice = _getBTCPrice() / priceFeed.decimals("WBTC");
        uint256 leverage = (position.size * btcPrice) / adjustedCollateral;
        return leverage <= MAX_LEVERAGE;
    }

    function _getPositionHash(address owner, uint256 collateralInUSD, uint256 sizeInUSD, bool isLong)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, collateralInUSD, sizeInUSD, isLong));
    }

    function _getGasStipend() public returns (uint256 amount) {
        uint256 usdcPrice = _getUSDCPrice();
        amount = (GAS_STIPEND * (10 ** USDCToken.decimals()) * (10 ** priceFeed.decimals("USDC"))) / usdcPrice;
    }

    function _absoluteValue(int256 value) internal pure returns (uint256) {
        return uint256(value >= 0 ? value : -value);
    }

    function _canChangeCollateral(bytes32 positionID, uint256 sizeChange, bool isIncement) public view returns (bool) {
        Position memory position = getPosition(positionID);
        int256 pnl = _getPNL(positionID);
        uint256 usdcPrice = _getUSDCPrice() / priceFeed.decimals("USDC");
        uint256 adjustedCollateral;
        if (pnl < 0) {
            if (isIncement) {
                adjustedCollateral = position.collateralInUSD - _absoluteValue(pnl) + sizeChange;
            } else {
                adjustedCollateral = position.collateralInUSD - _absoluteValue(pnl) - sizeChange;
            }
        } else {
            if (isIncement) {
                adjustedCollateral = position.collateralInUSD + uint256(pnl) + sizeChange;
            } else {
                adjustedCollateral = position.collateralInUSD + uint256(pnl) - sizeChange;
            }
        }
        if (adjustedCollateral == 0) return false;
        uint256 btcPrice = _getBTCPrice() / priceFeed.decimals("WBTC");
        uint256 leverage = (position.size * btcPrice) / adjustedCollateral;
        return leverage <= MAX_LEVERAGE;
    }

    function _canChangeSize(bytes32 positionID, uint256 sizeChange, bool isIncerement) public view returns (bool) {
        Position memory position = getPosition(positionID);
        int256 pnl = _getPNL(positionID);
        
        uint256 adjustedCollateral;
        if (pnl < 0) {
            adjustedCollateral = position.collateralInUSD - _absoluteValue(pnl);
        } else {
            adjustedCollateral = position.collateralInUSD + uint256(pnl);
        }

        if (adjustedCollateral == 0) {
            return false;
        }
        uint256 adjustedSize;
        uint256 btcPrice = _getBTCPrice() / (10**priceFeed.decimals("WBTC"));
        if (isIncerement) {
            adjustedSize = (position.size + sizeChange) * btcPrice  ;
        } else {
            adjustedSize = (position.size - sizeChange) * btcPrice;
        }
        if (adjustedSize == 0) return false;

        uint256 leverage = adjustedSize / adjustedCollateral;
        return leverage <= MAX_LEVERAGE;
    }
}
