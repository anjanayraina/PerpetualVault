pragma solidity 0.8.21;

// testnet oracle : https://sepolia.etherscan.io/address/0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD
// wBTC/USDC pool
// how is the value of a share of the pool set ??
// GOALS
// - 1. Liquidity Providers can deposit and withdraw liquidity []
// - 2. Traders can open a perpetual position for BTC, with a given size and collateral []
// - 3. A way to get the realtime price of the asset being traded [Done]
// - 4. Traders cannot utilize more than a configured percentage of the deposited liquidity []
// - 5. Traders can increase the size of a perpetual position []
// - 6. Traders can increase the collateral of a perpetual position []
// - 7. Liquidity providers cannot withdraw liquidity that is reserved for positions [] 
// - 8. Traders can decrease the size of their position and realize a proportional amount of their PnL []
// - 9. Traders can decrease the collateral of their position []
// - 10. Individual position’s can be liquidated with a liquidate function, any address may invoke the liquidate function []
// - 11. A liquidatorFee is taken from the position’s remaining collateral upon liquidation with the liquidate function and given to the caller of the liquidate function []
// - 12. Traders can never modify their position such that it would make the position liquidatable []
// - 13. Traders are charged a borrowingFee which accrues as a function of their position size and the length of time the position is open []
// - 14. Traders are charged a positionFee from their collateral whenever they change the size of their position, the positionFee is a percentage of the position size delta (USD converted to collateral token). — Optional/Bonus []



import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "../Interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract PerpetualVault  is ERC4626 , Ownable{
    uint8 public constant MAX_LEVERAGE = 20;
    uint public constant GAS_STIPEND = 10;
    uint8 public gasStipend;
    IERC20 public wBTCToken;
    IERC20 public USDCToken;
    AggregatorV3Interface btcPriceFeed;
    AggregatorV3Interface usdcPriceFeed;
    AggregatorV3Interface ethPriceFeed;
    struct Position {
        address positionOwner;
        uint256 collateral;
        bool isLong;
        uint256 size;
        uint256 currentPrice;
        bytes32 positionID;
    }

    mapping(bytes32 => Position) private openPositons;
    constructor(IERC20 LPTokenAddress ,IERC20 BTCTokenAddress , string memory name , string memory symbol , address _btcPriceFeed , address _usdcPriceFeed , address _ethPriceFeed, address owner) ERC4626(LPTokenAddress) ERC20(name , symbol) Ownable(owner){
        wBTCToken = BTCTokenAddress;
        USDCToken= LPTokenAddress;
        btcPriceFeed = AggregatorV3Interface(_btcPriceFeed);
        usdcPriceFeed = AggregatorV3Interface(_usdcPriceFeed);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);

    }

    function getBTCAddress() public view  returns(IERC20){
        return wBTCToken;
    }

    function getUSDCAddress() public view returns(IERC20){
        return USDCToken;
    }

    function getGasStipend() public returns(uint256 amount ){
        uint ethPrice = _getETHPrice()/ethPriceFeed.decimals();
        uint256 usdcPrice = _getUSDCPrice()/usdcPriceFeed.decimals();
        amount = (ethPrice*GAS_STIPEND*USDCToken.decimals())/(usdcPrice*1e9);
    }


    function openPosition(uint256 collateral , uint256 size , bool isLong) payable external returns(bytes32){
        require(size/collateral <=MAX_LEVERAGE , "Cant open a Position");
        uint256 totalAmountToDeposit = collateral + getGasStipend();
    
        return "";
    }

    function _getBTCPrice() internal view returns(uint256  ) {
        (, int price , , , ) = btcPriceFeed.latestRoundData();
        return uint(price);
    }

    function _getUSDCPrice() internal view returns(uint256 ) {
        (, int price , , , ) = usdcPriceFeed.latestRoundData();
        return uint(price);
    }

    function _getETHPrice() internal view returns(uint256  ) {
        (, int price , , , ) = ethPriceFeed.latestRoundData();
        return uint(price);
    }

    function _getPNL(bytes32 positionID) internal returns(uint256){
        
    }

    function _getPosition(bytes32 positionID) internal returns(Position storage ){
        return openPositons[positionID];
    }


    
}