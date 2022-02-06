pragma solidity ^0.8.0;

import "../openZeppelin/ERC20.sol";
import "../governance/Democratized.sol";
import "../governance/CMDTitles.sol";
import "./CMDToken.sol";

// I want to change the construction paradigm and get rid of DefaultDemocratized and when I launch KemToken it will 
// initialize CMDTitles, etc. 

contract KemToken is ERC20, Democratized {
    constructor() ERC20("Kemet", "KEM") Democratized(VotingMachine(address(0))) {
        CMDTitles titles = new CMDTitles(msg.sender);
        CMDToken cmd = new CMDToken(titles, this, msg.sender);
        titles.setCMD(cmd);
        voting = titles;
        // Initially mint 100M kem
        _mint(msg.sender, 100000000000000000000000000);
    }
    // Goverance
    struct MintRequest {
        address receiver;
        uint256 amt;
        uint256 propID;
    }
    mapping (uint256 => MintRequest) _mintRequests;
    uint256 _mintRequestCNT;
    function requestMint(address receiver_, uint256 amt_ ) public returns (uint256 propID) {
        uint256 requestID = _mintRequestCNT;
        _mintRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _mintRequests[requestID] = MintRequest(receiver_, amt_, propID);
        return propID;
    }
    function executeMint(uint256 requestID_) public {
        require(requestID_ < _mintRequestCNT, "No such request.");
        MintRequest memory request = _mintRequests[requestID_];
        voting.executeProposition(request.propID, msg.sender);
        _mint(request.receiver, request.amt);
    }
}