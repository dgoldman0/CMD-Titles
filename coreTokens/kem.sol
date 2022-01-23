pragma solidity ^0.8.0;

import "../openZeppelin/ERC20.sol";
import "../governance/Democratized.sol";

contract KemToken is ERC20, DefaultDemocratized {
    constructor() ERC20("kemet", "kem") {
        // Initially mint 100K kem
        _mint(msg.sender, 100000000000000000000000);
    }
}