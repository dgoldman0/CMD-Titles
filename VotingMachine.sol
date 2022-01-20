pragma solidity ^0.8.0;
import "VotingRights.sol";
import "Executors.sol";

// Should reduce some uints to uint64 to save gas

contract VotingMachine {
  VotingRights rightsContract;
  uint propositionCount;
  uint voteCount;
  struct Proposition {
    uint id;
    address sender;
    address executor;
    uint requestID;
    uint threshold; // vote threshold for confirmation in increments of 0.00001
    uint startTime;
    uint endTime;
    bool executed;
  }
  struct Vote {
    uint id;
    address voter;
    uint voterID;
    uint propositionID;
    uint propositionVoteID;
    bool vote; // True for yes and false for no
    uint weight;
  }
  mapping (uint => Proposition) propositions;
  mapping (uint => uint) propVoteCount;
  mapping (uint => mapping (uint => Vote)) propVotes;
  mapping (uint => Vote) votes;

  // Rolling tally
  mapping (uint => uint) votesForProp;
  mapping (uint => uint) votesAgainstProp;

  event NewProposition(uint id, address sender, address executor, uint threshold, uint requestID, uint startTime, uint endTime);
  event PropositionExecuted(uint propositionID, address executedBy);
  event NewVote(uint id, address votingAddress, uint voterID, uint propositionID, uint propositionVoteID, bool vote, uint weight);
  constructor(address rights) {
    rightsContract = VotingRights(rights);
  }
  function addProposition(address sender, address executor, uint threshold, uint requestID, uint startTime, uint endTime) public returns (uint propositionID) {
    uint propID = propositionCount;
    propositionCount++;
    propositions[propID] = Proposition(propID, sender, executor, threshold, requestID, startTime, endTime, false);
    emit NewProposition(propID, sender, executor, threshold, requestID, startTime, endTime);
    return propID;
  }
  function castVote(uint propositionID, uint voterID, bool vote) public returns (uint voteID) {
    uint weight = rightsContract.getVotingWeight(voterID);
    require(weight > 0, "This voter has no voting weight.");
    require(rightsContract.hasFiduciaryPower(msg.sender, voterID), "The sender does not have power to vote under this ID.");
    Proposition storage prop = propositions[propositionID];
    require(prop.startTime <= block.timestamp && block.timestamp < prop.endTime, "Inactive proposition.");

    uint voteID = voteCount;
    voteCount++;
    uint propVoteID = propVoteCount[propositionID];
    propVoteCount[propositionID]++;
    votes[voteID] = Vote(voteID, msg.sender, voterID, propositionID, propVoteID, vote, weight);
    propVotes[propositionID][propVoteID] = votes[voteID];

    if (vote) {
      votesForProp[propositionID] += weight;
    } else votesAgainstProp[propositionID] += weight;

    emit NewVote(voteID, msg.sender, voterID, propositionID, propVoteID, vote, weight);
  }
  function propositionOpen(uint propositionID) public view returns (bool open) {
    return block.timestamp < propositions[propositionID].endTime;
  }
  function totalVotes(uint propositionID) public view returns (uint votes) {
    return propVoteCount[propositionID];
  }
  function propositionApproved(uint propositionID) public view returns (bool approval) {
    Proposition memory prop = propositions[propositionID];
    if (prop.startTime > block.timestamp || block.timestamp >= prop.endTime) return false;
    return _checkPropositionThreshold(propositionID);
  }
  function _checkPropositionThreshold(uint propositionID) private view returns (bool reached) {
    // Need to be careful to make sure that I'm calculating the threshold properly since floating point arithemtic is not allowed
    return votesForProp[propositionID] * 100000 / votesAgainstProp[propositionID] >= propositions[propositionID].threshold;
  }
  function executeProposition(uint propositionID) public returns (bool success) {
    Proposition storage prop = propositions[propositionID];
    require(block.timestamp > prop.endTime, "Proposition voting is still ongoing.");
    require(_checkPropositionThreshold(propositionID), "Proposition has not been approved.");
    require(!prop.executed, "Proposition already executed.");
    prop.executed = true;
    IExecutor executor = IExecutor(prop.executor);
    executor.execute(prop.requestID);
    emit PropositionExecuted(propositionID, msg.sender);
  }
}
