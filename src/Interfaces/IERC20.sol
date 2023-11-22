pragma solidity 0.8.7;
interface IERC20 {
    function transferFrom(address from , address to , uint amount) external returns (bool);
    function approve() external returns(bool);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to , uint amount) external returns(bool);

}