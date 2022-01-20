pragma solidity ^0.8.0;
import "./OpenZeppelin/ERC20.sol";

interface IExecutor {
  function execute(uint requestID) external;
}

contract BEP20Executor is IExecutor {
  struct Request {
    address store; // The storage location that's holding the tokens that will be transferred
    address token;
    uint amt;
    address receiver;
    bool executed;
  }
  uint requestCount;
  mapping (uint => Request) requests;

  function execute(uint requestID) external override {
    require(requestID < requestCount, "No such request");
    Request memory req = requests[requestID];
    require(!req.executed, "Request already executed.");
    ERC20 token = ERC20(req.token);
    token.transferFrom(address(this), req.receiver, req.amt);
  }

  function request(address store, address token, uint amt, address receiver) public returns (uint requestID) {
    uint requestID = requestCount;
    requestCount++;
    requests[requestID] = Request(store, token, amt, receiver, false);
    return requestID;
  }
}
/*
contract BEP721Executor is IExecutor {
  struct Request {
    address store; // The storage location that's holding the tokens that will be transferred
    bool executed;
  }
  uint requestCount;
  mapping (uint => Request) requests;

  function execute(uint requestID) external override {
    require(requestID < requestCount, "No such request");
    Request memory req = requests[requestID];
    require(!req.executed, "Request already executed.");

  }
}
contract BEP1155Executor is IExecutor {
  struct Request {
    address store; // The storage location that's holding the tokens that will be transferred
    bool executed;
  }
  uint requestCount;
  mapping (uint => Request) requests;

  function execute(uint requestID) external override {
    require(requestID < requestCount, "No such request");
    Request memory req = requests[requestID];
    require(!req.executed, "Request already executed.");

  }
}
*/
