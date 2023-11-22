pragma solidity 0.8.21;

// testnet oracle : https://sepolia.etherscan.io/address/0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD
// wBTC/USDC pool
// how is the value of a share of the pool set ??


import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract PerpetualVault  is ERC4626{
    // using Counters for Counters.Counter;
    // Counters.Counter private currentPositionID;
    uint8 public constant MAX_LEVERAGE = 20;
    uint8 public gasStipend;
    IERC20 public wBTCToken;
    IERC20 public USDCToken;
    struct Position {
        address creator;
        uint collateral;
        bool isLong;
        uint size;
        uint256 positionID;
    }
    constructor(IERC20 LPTokenAddress ,IERC20 BTCTokenAddress , string memory name , string memory symbol) ERC4626(LPTokenAddress) ERC20(name , symbol){
        wBTCToken = BTCTokenAddress;
        USDCToken= LPTokenAddress;
        
    }

    function getBTCAddress() public view  returns(IERC20){
        return wBTCToken;
    }

    function getUSDCAddress() public view returns(IERC20){
        return USDCToken;
    }
    


    
}