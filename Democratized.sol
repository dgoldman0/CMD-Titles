// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "VotingRights.sol";
import "iDemocretized.sol";

/* This could rely on a library since they're reusable code segments on chain.
** It could be dangerous but I could "executor" contracts and when the vote is decided, a call to that executor's contract can be called.
**
** For instance:
**
** Set executor to ERC20Withdraw contract address
**
*/

contract VotingMachine {
  VotingRights rightsContract
  uint propositionCount;
  uint voteCount;
  struct Proposition {
    uint id;
    address sender;
    address executor;
    uint requestID;
    uint threshold; // vote threshold for confirmation in increments of 0.00001
  }
  struct Vote {
    int id;
    address voter;
    uint voterID;
    bool vote; // True for yes and false for no
    uint weight;
  }
  mapping (uint => Proposition) propositions;
  mapping (uint => Vote) votes;
  constructor(address rights) {
    rightsContract = VotingRights(rights);
  }
  function addProposition(address sender, address executor, uint threshold, requestID) public returns (uint propositionID) {
    uint propID = propositionCount;
    propositions[propID] = Proposition(propID, sender, exeuctor, threshold, requestID);
    propositionCount++;
    emit NewProposition(propID, sender, executor, threshold, requestID);
    return propID;
  }
  function castVote(uint propositionID, uint voterID, bool vote) public returns (uint voteID) {
    uint weight = rightsContract.getVotingWeight(voterID);
    require(weight > 0, "This voter has no voting weight.");
    require(rightsContract.hasFiduciary(msg.sender, voterID), "The sender does not have power to vote under this ID.");
    uint voteID = voteCount;
    votes[voteID] = Vote(voteID, msg.sender, voterID, vote, weight);
    voteCount++;
    emit NewVote(voteID, msg.sender, voterID, vote, weight);
  }
}

abstract contract Democratized is ERC1155Holder, iDemocretized {
  VotingMachine voting;
  VotingRights rightsContract;
  constructor(address _machineAddr) {
    voting = VotingMachine(_machineAddr);
  }
  // Request a withdraw of TRC-20 tokens
  function _requestWithdraw20(address contract, uint amt, address receiver) internal returns (uint propositionID) {
    uint requestID = trc20Executor.request(contract, amt, receiver);
    return voting.addProposition(msg.sender, trc20Executor, threshold, requestID);
  }
  // Request a withdraw of TRC-721 tokens
  function _requestWithdraw721(IERC721 contract, uint id, uint threshold, address receiver) internal returns (uint propositionID) {
    uint requestID = trc721Executor.request(contract, id, receiver);
    return voting.addProposition(msg.sender, trc721Executor, threshold, requestID);
  }
  // Request a withdraw of TRC-1155 tokens: should add an option for batch withdraw too maybe
  function _requestWithdraw1155(IERC1155 contract, uint id, uint amt, uint threshold, address receiver) internal returns (uint propositionID) {
    uint requestID = trc1155Executor.request(contract, id, amt, receiver);
    return voting.addProposition(msg.sender, trc1155Executor, threshold, requestID);
  }
  // External versions which default to 50%
  function requestWithdraw20(address contract, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw20(contract, amt, 5000000, receiver);
  }
  function requestWithdraw721(IERC721 contract, uint id, uint threshold, address receiver) internal returns (uint propositionID) {
    return _requestWithdraw721(contract, id, 5000000, receiver);
  }
}
