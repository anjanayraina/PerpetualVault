pragma solidity 0.8.20;

// testnet oracle : https://sepolia.etherscan.io/address/0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD
// wBTC/USDC pool
// how is the value of a share of the pool set ??

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract PerpetualVault  is ERC4626{
    using Counters for Counters.Counter;
    Counters.Counter private currentPositionID;
    uint8 public constant MAX_LEVERAGE = 20;
    IERC20 public BTCToken;
    
    struct Position {
        address creator;
        uint collateral;
        bool long;
        uint size;
        uint256 positionID;
    }
    constructor(IERC20 LPTokenAddress ,IERC20 BTCTokenAddress , string memory name , string memory symbol) ERC4626(LPTokenAddress) ERC20(name , symbol){
        BTCToken = BTCTokenAddress;
        currentPositionID.increment();
    }
    


    
}