pragma solidity ^0.8.0;

interface VotingRights {
  // Gets the voting weight of the associated voterID
  function getVotingWeight(uint voterID) external view returns (uint power);
  // Gets whether the address is allowed to vote using the given ID
  function hasFiduciaryPower(address addr, uint voterID) external view returns (bool hasFiduciary);
  // Get the total size of the electorate
  function electorateSize() external view returns (uint size);
}
