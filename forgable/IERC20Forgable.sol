pragma solidity ^0.8.0;
import "../openZeppelin/IERC20.sol";

interface IERC20Forgable is IERC20 {
  event Forged(address indexed to, uint cost, uint amt);
  event NewSmith(address indexed, uint fee);

  function forge(uint amt_) external returns (uint256 amt);
  function forgeLimit() external view returns (uint256 amount);
  function conversionRate() external view returns (uint256 rate);
  function timeToForge(address addr) external view returns (uint256 time);
  function smithCount() external view returns (uint256 count);
  function smithFee() external view returns (uint256 paid);
  function canSmith() external view returns (bool able);
  function canSmith(address addr_) external view returns (bool);
  function totalMaterialUsed() external view returns (uint256 totalUsed);
  function lastMint() external view returns (uint256 date);
  function paySmithingFee() external payable returns (bool fee);
}