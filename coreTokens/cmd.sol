pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

/// @dev Might be interesting to have an alternative for "canSmith" 
contract CMDToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 100 KEM per 1 CMD, 10K KEM limit per forge, initial 100,000 CMD
    constructor() MultiERC20Forgable("Command", "CMD", 100000000000000000, address(0x478d5Cc45BA8B3F7703162fa8b7a89DfE1D2837F), 100, 100000000000000000000000, 1000000000000000000000) {

    }
}