// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "./VotingMachine.sol";
import "./openZeppelin/ERC20.sol";
import "./openZeppelin/ERC1155Holder.sol";

// Will extend  is ERC1155Holder when working on 1155 contracts
contract Democratized {
  VotingMachine voting;
  uint bep20RequestCount;

  struct BEP20Request {
    address token;
    uint amt;
    address receiver;
    uint propositionID;
  }

  mapping (uint => BEP20Request) bep20Requests;

  constructor(address _machineAddr) {
    voting = VotingMachine(_machineAddr);
  }
  
  // Request a withdraw of BEP-20 tokens
  function _requestWithdraw20(address token, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = bep20RequestCount;
    bep20RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    bep20Requests[requestID] = BEP20Request(token, amt, receiver, propID);
    return propID;
  }
  // External versions which default to 50% simple vote
  function requestWithdraw20(address token, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function executeWithdraw20(uint requestID) public {
    require(requestID < bep20RequestCount, "No such request.");
    BEP20Request memory request = bep20Requests[requestID];
    // Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    ERC20 token = ERC20(request.token);
    token.transferFrom(address(this), request.receiver, request.amt);
  }
}

// Will preset Voting Machine address but should I allow change of voting machine by vote too?
// Note: Until final testing is done, the addresses will be the contracts on TESTNET!
contract DefaultDemocratized is Democratized {
  constructor() Democratized(address(0xf8e81D47203A594245E36C48e151709F0C19fBe8)) {

  }
}
