pragma solidity ^0.8.0;

interface iDemocretized {
  event NewProposition(uint id, address sender, address executor, uint threshold, uint requestID);
  event NewVote(uint id, address votingAddress, uint voterID, uint propositionID, uint vote);
  function addProposition(address sender, address executor, uint threshold, requestID) public returns (uint propositionID);
  function castVote(uint propositionID, uint voterID, bool vote) public returns (uint voteID);
}
