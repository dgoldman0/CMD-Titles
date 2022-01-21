pragma solidity ^0.8.0;
import "../openZeppelin/IERC20.sol";
import "./IERC20Forgable.sol";
import "../openZeppelin/Address.sol";
import "../Democratized.sol";

abstract class ERC20Forgable is ERC20, IERC20Forgable, DefaultDemocratized {
    ERC20 resourceToken; // The token that will be used in the forging process.
}