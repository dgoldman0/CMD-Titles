pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

contract ARCToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 100 KEM per 1 ARC, 10K KEM limit per forge, initial 100,000 ARC
    constructor() MultiERC20Forgable("Arcadium", "ARC", 10000000, address(0), 100, 100000000000000000000000, 1000000000000000000000) {

    }
}