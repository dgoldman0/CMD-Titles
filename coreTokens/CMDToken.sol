pragma solidity ^0.8.0;

import "../openZeppelin/ERC20.sol";
import "../governance/CMDTitles.sol";
import "../governance/LocalTitles.sol";
import "../forgable/MultiERC20Forgable.sol";
/// @dev Might be interesting to have an alternative for "canSmith" 
contract CMDToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 100 KEM per 1 CMD, 10K KEM limit per forge, initial 1000,000 CMD
    constructor(CMDTitles cmd_, ERC20 kem_) MultiERC20Forgable("Command", "CMD", 100000000000000000, kem_, 100, 10000000000000000000000, 1000000000000000000000000) Democratized(VotingMachine(cmd_)) {
    }
}