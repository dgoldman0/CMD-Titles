pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

/// @dev Might be interesting to have an alternative for "canSmith" 
contract CMDToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 100 KEM per 1 CMD, 10K KEM limit per forge, initial 1000,000 CMD
    constructor() MultiERC20Forgable("Command", "CMD", 100000000000000000, address(0x403063238206062435547c8B57D401509dd5c647), 100, 10000000000000000000000, 1000000000000000000000000) {

    }
}