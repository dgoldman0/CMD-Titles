// A general DAO contract integrating titles
pragma solidity ^0.8.0;
import "./VotingMachine.sol";
import "../openZeppelin/ERC20.sol";
import "../openZeppelin/ERC721.sol";
import "../openZeppelin/IERC721Enumerable.sol";
import "../openZeppelin/IERC721Metadata.sol";
import "../openZeppelin/ERC1155.sol";
import "../openZeppelin/ERC721Holder.sol";
import "../openZeppelin/ERC1155Holder.sol";

/// @dev At some point we'll add Democratized systems that will allow easy voting on whether to add or remove liquidity in pools.

/// @dev Forgot to add requests to transfer out ETH itself!

contract Democratized is ERC721Holder, ERC1155Holder {
  VotingMachine voting;

  struct ETHRequest {
    uint amt;
    address payable receiver;
    uint propositionID;
  }
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

  // We don't need 2^256 potential requests and using 32 might help with tight packing
  mapping (uint32 => ETHRequest) ethRequests;
  mapping (uint32 => ERC20Request) erc20Requests;
  mapping (uint32 => ERC721Request) erc721Requests;
  mapping (uint32 => ERC1155Request) erc1155Requests;
  mapping (uint32 => ERC1155BatchRequest) erc1155BatchRequests;

  uint32 ethRequestCount;
  uint32 erc20RequestCount;
  uint32 erc721RequestCount;
  uint32 erc1155RequestCount;
  uint32 erc1155BatchRequestCount;


  /// @dev Not sure if additional or less information should be made available. Include sender?
  event ETHWithdrawRequested(uint amt, uint requestID);
  event ERC20WithdrawRequested(address token, uint amt, uint32 requestID);
  event ERC721WithdrawRequested(address token, uint tokeNID, uint32 requestID);
  event ERC1155WithdrawRequested(address token, uint tokenID, uint amt, uint32 requestID);
  event ERC1155WithdrawRequested(address token, uint[] tokenIDs, uint[] amts, uint32 requestID);
  event ERC20WithdrawExecuted(address token, uint amt, uint64 requestID);
  event ERC721WithdrawExecuted(address token, uint tokenID, uint32 requestID);
  event ERC1155WithdrawExecuted(address token, uint tokenID, uint amt, uint32 requestID);
  event ERC1155WithdrawExecuted(address token, uint[] tokenIDs, uint[] amts, uint32 requestID);
  
  constructor(VotingMachine machine_) {
    voting = machine_;
  }
  function getVotingMachine() public view returns (address machine) {
    return address(voting);
  }
  function _requestETHWithdraw(uint amt, uint threshold, address payable receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint32 requestID = ethRequestCount;
    ethRequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    ethRequests[requestID] = ETHRequest(amt, receiver, propID);
    emit ETHWithdrawRequested(amt, requestID);
    return propID;
  }
  function _requestWithdraw20(address token, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint32 requestID = erc20RequestCount;
    erc20RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc20Requests[requestID] = ERC20Request(token, amt, receiver, propID);
    emit ERC20WithdrawRequested(token, amt, requestID);
    return propID;
  }
  function _requestWithdraw721(address token, uint tokenID, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint32 requestID = erc721RequestCount;
    erc721RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc721Requests[requestID] = ERC721Request(token, tokenID, receiver, propID);
    return propID;
  }
  function _requestWithdraw1155(address token, uint tokenID, uint amt, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint32 requestID = erc1155RequestCount;
    erc1155RequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc1155Requests[requestID] = ERC1155Request(token, tokenID, amt, receiver, propID);
    return propID;
  }
  function _requestWithdraw1155(address token, uint[] memory tokenIDs, uint[] memory amts, uint threshold, address receiver, uint startTime, uint endTime) internal returns (uint propositionID) {
    uint32 requestID = erc1155BatchRequestCount;
    erc1155BatchRequestCount++;
    uint propID = voting.addProposition(msg.sender, threshold, startTime, endTime);
    erc1155BatchRequests[requestID] = ERC1155BatchRequest(token, tokenIDs, amts, receiver, propID);
    return propID;
  }
  /// @dev External versions which default to 50% simple vote
  function requestETHWithdraw(uint amt, address payable receiver) public virtual returns (uint propositionID) {
    return _requestETHWithdraw(amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC20(address token, uint amt, address receiver) public virtual returns (uint propositionID) {
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC721(address token, uint tokenID, address receiver) public virtual returns (uint propositionID) {
    return _requestWithdraw721(token, tokenID, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint tokenID, uint amt, address receiver) public virtual returns (uint propositionID) {
    return _requestWithdraw1155(token, tokenID, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint[] memory tokenIDs, uint[] memory amts, address receiver) public virtual returns (uint propositionID) {
    return _requestWithdraw1155(token, tokenIDs, amts, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function executeETHWithdraw(uint32 requestID) public {
    require(requestID < ethRequestCount, "No such request.");
    ETHRequest memory request = ethRequests[requestID];
    /// @dev Make sure proposition is set to executed FIRST
    voting.executeProposition(request.propositionID, msg.sender);
    request.receiver.transfer(request.amt);
  }
  function executeWithdrawERC20(uint32 requestID) public {
    require(requestID < erc20RequestCount, "No such request.");
    ERC20Request memory request = erc20Requests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    ERC20 token = ERC20(request.token);
    token.transferFrom(address(this), request.receiver, request.amt);
  }
  function executeWithdrawERC721(uint32 requestID) public {
    require(requestID < erc721RequestCount, "No such request.");
    ERC721Request memory request = erc721Requests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    ERC721 token = ERC721(request.token);
    token.safeTransferFrom(address(this), request.receiver, request.tokenID);
  }
  function executeWithdrawERC1155(uint32 requestID) public {
    require(requestID < erc1155RequestCount, "No such request.");
    ERC1155Request memory request = erc1155Requests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    ERC1155 token = ERC1155(request.token);
    /// @dev I'm not sure if I should include the data parameter or not.
    token.safeTransferFrom(address(this), request.receiver, request.tokenID, request.amt, "");
  }  
  function executeWithdrawERC1155Batch(uint32 requestID) public {
    require(requestID < erc1155BatchRequestCount, "No such request.");
    ERC1155BatchRequest memory request = erc1155BatchRequests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    ERC1155 token = ERC1155(request.token);
    token.safeBatchTransferFrom(address(this), request.receiver, request.tokenIDs, request.amts, "");
  }  
  /// @dev I need to figure out how to ensure that it works with either 721 or 1155
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId
      || interfaceId == type(IERC721Enumerable).interfaceId
      || interfaceId == type(IERC1155).interfaceId
      || super.supportsInterface(interfaceId);
  }

  /// @dev Don't forget to add fallback functions to allow ETH
}

// Will preset Voting Machine address but should I allow change of voting machine by vote too?
// Note: Until final testing is done, the addresses will be the contracts on TESTNET!
contract DefaultDemocratized is Democratized {
  constructor() Democratized(VotingMachine(address(0))) {
  }
}

contract DefaultEscrow is DefaultDemocratized {
  uint lockedUntil;
  constructor(uint holdingPeriod_) DefaultDemocratized() {
    lockedUntil = block.timestamp + holdingPeriod_;
  }
  function requestETHWithdraw(uint amt, address payable receiver) public override returns (uint propositionID) {
    require(lockedUntil < block.timestamp, "Lockout period not finished.");
    return _requestETHWithdraw(amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC20(address token, uint amt, address receiver) public override returns (uint propositionID) {
    require(lockedUntil < block.timestamp, "Lockout period not finished.");
    return _requestWithdraw20(token, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC721(address token, uint tokenID, address receiver) public override returns (uint propositionID) {
    require(lockedUntil < block.timestamp, "Lockout period not finished.");
    return _requestWithdraw721(token, tokenID, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint tokenID, uint amt, address receiver) public override returns (uint propositionID) {
    require(lockedUntil < block.timestamp, "Lockout period not finished.");
    return _requestWithdraw1155(token, tokenID, amt, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  function requestWithdrawERC1155(address token, uint[] memory tokenIDs, uint[] memory amts, address receiver) public override returns (uint propositionID) {
    require(lockedUntil < block.timestamp, "Lockout period not finished.");
    return _requestWithdraw1155(token, tokenIDs, amts, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
}