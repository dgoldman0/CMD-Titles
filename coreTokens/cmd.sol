pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

contract CmdToken is MultiERC20Forgable {
    // 100 kem per 1 cmd, 10K kem limit per forge, initial 10000 cmd
    constructor() MultiERC20Forgable("Command", "cmd", address(0), 100, 10000000000000000000000, 1000000000000000000000) {

    }
}