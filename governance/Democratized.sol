// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "./VotingMachine.sol";
import "../openZeppelin/ERC20.sol";
import "../openZeppelin/ERC721.sol";
import "../openZeppelin/ERC721Holder.sol";
import "../openZeppelin/ERC1155Holder.sol";

/// @dev Still need to implement ERC1155 functionality. 
contract Democratized is ERC721Holder {
  VotingMachine voting;
  uint erc20RequestCount;
  uint erc721RequestCount;

  struct ERC20Request {
    address token;
    uint amt;
    address receiver;
    uint propositionID;
  }
  struct ERC721Request {
    address token;
    uint tokenID;
    address receiver;
    uint propositionID;
  }

  mapping (uint => ERC20Request) erc20Requests;
  mapping (uint => ERC721Request) erc721Requests;

  constructor(address _machineAddr) {
    voting = VotingMachine(_machineAddr);
  }
  
  function _requestWithdraw20(address token, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc20RequestCount;
    erc20RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc20Requests[requestID] = ERC20Request(token, amt, receiver, propID);
    return propID;
  }
  function _requestWithdraw721(address token, uint tokenID, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc721RequestCount;
    erc721RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc721Requests[requestID] = ERC721Request(token, tokenID, receiver, propID);
    return propID;
  }
  // External versions which default to 50% simple vote
  function requestWithdrawERC20(address token, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC721(address token, uint tokenID, address receiver) public returns (uint propositionID) {
    return _requestWithdraw721(token, tokenID, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }

  function executeWithdrawERC20(uint requestID) public {
    require(requestID < erc20RequestCount, "No such request.");
    ERC20Request memory request = erc20Requests[requestID];
    // Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    ERC20 token = ERC20(request.token);
    token.transferFrom(address(this), request.receiver, request.amt);
  }
  function executeWithdrawERC721(uint requestID) public {
    require(requestID < erc721RequestCount, "No such request.");
    ERC721Request memory request = erc721Requests[requestID];
    // Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    ERC721 token = ERC721(request.token);
    token.safeTransferFrom(address(this), request.receiver, request.tokenID);
  }
}

// Will preset Voting Machine address but should I allow change of voting machine by vote too?
// Note: Until final testing is done, the addresses will be the contracts on TESTNET!
contract DefaultDemocratized is Democratized {
  constructor() Democratized(address(0x515459E34780a4d3FBaa14B8191f72A307A890a3)) {

  }
}
