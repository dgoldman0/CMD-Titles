// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "./VotingMachine.sol";
import "../openZeppelin/ERC20.sol";
import "../openZeppelin/ERC721.sol";
import "../openZeppelin/ERC1155.sol";
import "../openZeppelin/ERC721Holder.sol";
import "../openZeppelin/ERC1155Holder.sol";

/// @dev Still need to implement ERC1155 functionality. 
contract Democratized is ERC721Holder, ERC1155Holder {
  VotingMachine voting;
  uint erc20RequestCount;
  uint erc721RequestCount;
  uint erc1155RequestCount;
  uint erc1155BatchRequestCount;

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
  struct ERC1155Request {
    address token;
    uint tokenID;
    uint amt;
    address receiver;
    uint propositionID;
  }
  struct ERC1155BatchRequest {
    address token;
    uint[] tokenIDs;
    uint[] amts;
    address receiver;
    uint propositionID;
  }

  mapping (uint => ERC20Request) erc20Requests;
  mapping (uint => ERC721Request) erc721Requests;
  mapping (uint => ERC1155Request) erc1155Requests;
  mapping (uint => ERC1155BatchRequest) erc1155BatchRequests;

  /// @dev Not sure if additional or less information should be made available. Include sender?
  event ERC20WithdrawRequested(address token, uint amt, uint requestID);
  event ERC721WithdrawRequested(address token, uint tokeNID, uint requestID);
  event ERC1155WithdrawRequested(address token, uint tokenID, uint amt, uint requestID);
  event ERC1155WithdrawRequested(address token, uint[] tokenIDs, uint[] amts, uint requestID);
  event ERC20WithdrawExecuted(address token, uint amt, uint requestID);
  event ERC721WithdrawExecuted(address token, uint tokenID, uint requestID);
  event ERC1155WithdrawExecuted(address token, uint tokenID, uint amt, uint requestID);
  event ERC1155WithdrawExecuted(address token, uint[] tokenIDs, uint[] amts, uint requestID);

  constructor(address _machineAddr) {
    voting = VotingMachine(_machineAddr);
  }
  
  function _requestWithdraw20(address token, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc20RequestCount;
    erc20RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc20Requests[requestID] = ERC20Request(token, amt, receiver, propID);
    emit ERC20WithdrawRequested(token, amt, requestID);
    return propID;
  }
  function _requestWithdraw721(address token, uint tokenID, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc721RequestCount;
    erc721RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc721Requests[requestID] = ERC721Request(token, tokenID, receiver, propID);
    return propID;
  }
  function _requestWithdraw1155(address token, uint tokenID, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc1155RequestCount;
    erc1155RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc1155Requests[requestID] = ERC1155Request(token, tokenID, amt, receiver, propID);
    return propID;
  }
  function _requestWithdraw1155(address token, uint[] memory tokenIDs, uint[] memory amts, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint requestID = erc1155BatchRequestCount;
    erc1155BatchRequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc1155BatchRequests[requestID] = ERC1155BatchRequest(token, tokenIDs, amts, receiver, propID);
    return propID;
  }
  // External versions which default to 50% simple vote
  function requestWithdrawERC20(address token, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC721(address token, uint tokenID, address receiver) public returns (uint propositionID) {
    return _requestWithdraw721(token, tokenID, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint tokenID, uint amt, address receiver) public returns (uint propositionID) {
    return _requestWithdraw1155(token, tokenID, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint[] memory tokenIDs, uint[] memory amts, address receiver) public returns (uint propositionID) {
    return _requestWithdraw1155(token, tokenIDs, amts, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
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
  function executeWithdrawERC1155(uint requestID) public {
    require(requestID < erc1155RequestCount, "No such request.");
    ERC1155Request memory request = erc1155Requests[requestID];
    // Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    ERC1155 token = ERC1155(request.token);
    /// @dev I'm not sure if I should include the data parameter or not.
    token.safeTransferFrom(address(this), request.receiver, request.tokenID, request.amt, "");
  }  
  function executeWithdrawERC1155Batch(uint requestID) public {
    require(requestID < erc1155BatchRequestCount, "No such request.");
    ERC1155BatchRequest memory request = erc1155BatchRequests[requestID];
    // Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    ERC1155 token = ERC1155(request.token);
    /// @dev I'm not sure if I should include the data parameter or not.
    token.safeBatchTransferFrom(address(this), request.receiver, request.tokenIDs, request.amts, "");
  }  
}

// Will preset Voting Machine address but should I allow change of voting machine by vote too?
// Note: Until final testing is done, the addresses will be the contracts on TESTNET!
contract DefaultDemocratized is Democratized {
  constructor() Democratized(address(0x76C55cE393dbeBe2d2BD531892a586ed628A196B)) {

  }
}
