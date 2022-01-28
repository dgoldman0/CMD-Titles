pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

contract ARCToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 100 KEM per 1 ARC, 10K KEM limit per forge, initial 100,000 ARC
    constructor() MultiERC20Forgable("Arcadium", "ARC", 100000000000000000, address(0xee7922AA8c3a76922706fc2D1D9E7084E11F9906), 100, 10000000000000000000000, 100000000000000000000000) {

    }
}