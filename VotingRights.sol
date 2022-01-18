pragma solidity ^0.8.0;

interface VotingRights {
  // Gets the voting weight of the associated voterID
  function getVotingWejight(uint voterID) public view returns (uint power);
  // Gets whether the address is allowed to vote using the given ID 
  function hasFiduciaryPower(address addr, uint voterID) public view returns (bool hasFiduciary);
}
