pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";
import "../governance/LocalTitles.sol";

contract PHCToken is MultiERC20Forgable {
    // Smith fee 0.1BNB, 1000 KEM per 1 PHC, 10K KEM limit per forge, initial 100,000 PHC
    constructor(CMDTitles cmd_) MultiERC20Forgable("Promote.Health", "PHC", 100000000000000000, address(0xee7922AA8c3a76922706fc2D1D9E7084E11F9906), 100, 100000000000000000000000, 100000000000000000000000) {
        voting = new LocalTitles("PHCTitles", "PHT", cmd_, this, 1000);
    }
}