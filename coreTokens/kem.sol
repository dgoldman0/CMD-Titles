pragma solidity ^0.8.0;

import "../forgable/MultiERC20Forgable.sol";

contract KemToken is ERC20, DefaultDemocratized {
    constructor() ERC20("kemet", "kem") {
        // Initially mint 100K kem
        _mint(msg.sender, 100000000000000000000000);
    }
}