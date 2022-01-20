// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "./VotingRights.sol";
import "./VotingMachine.sol";
import "./OpenZeppelin/ERC20.sol";
import "./OpenZeppelin/ERC1155Holder.sol";
import "./Executors.sol";

contract Democratized is ERC1155Holder {
  VotingMachine voting;
  VotingRights rightsContract;
  BEP20Executor BEP20Executor;
//  BEP721Executor BEP721Executor;
//  BEP1155Executor BEP1155Executor;

  constructor(address _machineAddr) {
    voting = VotingMachine(_machineAddr);
  }
  // Request a withdraw of BEP-20 tokens
  function _requestWithdraw20(address token, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = BEP20Executor.request(address(this), token, amt, receiver);
    ERC20(token).increaseAllowance(address(BEP20Executor), amt);
    return voting.addProposition(msg.sender, address(BEP20Executor), threshold, requestID, startTime, endTime);
  }
  /*
  // Request a withdraw of BEP-721 tokens
  function _requestWithdraw721(address token, uint id, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = BEP721Executor.request(token, id, receiver);
    return voting.addProposition(msg.sender, BEP721Executor, threshold, requestID, startTime, endTime);
  }
  // Request a withdraw of BEP-1155 tokens: should add an option for batch withdraw too maybe
  function _requestWithdraw1155(address token, uint id, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = BEP1155Executor.request(token, id, amt, receiver);
    return voting.addProposition(msg.sender, BEP1155Executor, threshold, requestID, startTime, endTime);
  }
  */
  // External versions which default to 50% simple vote
  function requestWithdraw20(address token, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  /*
  function requestWithdraw721(address token, uint id, uint threshold, address receiver) internal returns (uint propositionID) {
    return _requestWithdraw721(token, id, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdraw1155(address token, uint id, uint amt, uint threshold, address receiver) internal returns (uint propositionID) {
    return _requestWithdraw1155(token, id, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  */
}
