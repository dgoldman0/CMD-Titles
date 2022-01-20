pragma solidity ^0.8.0;
import "./openZeppelin/ERC20.sol";
import "./openZeppelin/Address.sol";
import "./openZeppelin/ERC721.sol";
import "./openZeppelin/ERC721Enumerable.sol";
import "./VotingRights.sol";
import "./Democratized.sol";

contract WRLDTitles is ERC721Enumerable, VotingRights, DefaultDemocratized {
	using Address for address;
  ERC20 cmd_contract;
  uint64 titleCount;

	mapping(address => uint) private _addressCMDBalance;
  uint private _reserveBalance; // The amount of CMD reserved to pay for CMDBalance
	uint private _reservedForExecutor; // Amount of CMD reserved for the executor

	event TitleMinted(uint64 titleID, uint8 rank, uint parentID, address minter);
	event CMDClaim(address minter, uint amount);

	//Tight packing would allow for multiple attributes to be stored in a single uint256 slot in evm.
	struct Title {
		uint8 rank;
		uint titleID; // Global ID of this token
		uint parentTitleID; // Global ID of parent token
		uint64 localID; // (parentTitleId, localId) rather than single global mint ID
    uint64 childCount; // Number of children currently minted by this title
		address minterAddress;
	}

  mapping(uint => Title) titles;

  // Gives details about how many children a title of a given rank can mint and how much it costs to mint
  struct Rank {
    uint64 mintCost; // The cost to mint a new title of the given rank
    uint64 maxChildren; // The maximum number of child titles the rank can have
  }

  mapping (uint8 => Rank) ranks;

  // Requests
  struct RankChangeRequest {
    uint8 rank;
    uint64 cost;
    uint propositionID;
  }
  uint rankChangeRequestCNT;
  mapping (uint => RankChangeRequest) rankChangeRequests;

  constructor() ERC721("CMD Title", "TTL") public {
    // Initial settings for ranks
    uint8 i;
    uint64 cost = 1000000000000; // Cost of god title is 1M CMD
    uint64 maxChildren = 10; // Only ten children titles per title
    for (i = 0; i < 13; i++) {
      ranks[i] = Rank(cost, maxChildren);
      cost = cost / 10; // Each lower rank costs 1/10th the cost of the previous rank
    }
  }
  function getVotingWeight(uint titleID) external view override returns (uint weight) {
    if (titles[titleID].rank == 12) return 1;
    return 0;
  }
  function hasFiduciaryPower(address addr, uint titleID) external view override returns (bool hasPower) {
    return ownerOf(titleID) == addr;
  }
  function mintCost(uint8 rank) public view returns (uint cost) {
    require(rank < 13, "No such rank!");
    return ranks[rank].mintCost;
  }

  function mintTitle(uint _parentID) public returns (uint64 id) {
    // Mint the title
    Title storage parent = titles[_parentID];
    require(ownerOf(_parentID) == msg.sender, "User does not own this title.");
    uint8 rank = parent.rank + 1;
    require(rank < 12, "Provincial titles cannot mint lower tier titles.");
    uint cost = ranks[rank].mintCost;
    require(cmd_contract.balanceOf(msg.sender) >= cost, "Insufficient Funds");
    require(cmd_contract.allowance(msg.sender, address(this)) >= cost, "Insufficient Approval");
    uint64 lid = parent.childCount;
    require(lid < ranks[rank].maxChildren, "This title has reached its maximum mint count.");
    parent.childCount++;
    uint id = titleCount;
    titleCount++;
    titles[id] = Title(rank, id, _parentID, lid, 0, msg.sender);
    _safeMint(msg.sender, id);

    // Distribute CMD
    cmd_contract.transferFrom(msg.sender, address(this), cost);
    // Automatically reserve 1/3 for the DAO: uses 1/3 rather than 2/3 because I divide yield by 2 AFTER distributing
    uint yield = cost * 1 / 3;
    Title storage curtitle = parent;
    do {
      _reserveBalance += yield;
      address owner = ownerOf(curtitle.titleID);
      _addressCMDBalance[owner] += yield;
      curtitle = titles[curtitle.parentTitleID];
      yield = yield / 2;
    } while (curtitle.rank != 0);
  }
	// Withdraws the available CMD held in reserve for the user
  function withdrawCMD() public returns (uint amt) {
    uint cmd = _addressCMDBalance[msg.sender];
    _addressCMDBalance[msg.sender] = 0;
    _reserveBalance -= cmd;
    cmd_contract.transferFrom(address(this), msg.sender, cmd);
  }
	// Override ERC20 withdraw to prevent CMD from being withdrawn or otherwise ensure that the DAO is not drained of CMD needed or _reserveBalance

	// Democretized Controls
	function requestRankChange(uint8 rank, uint cost) public returns (uint requestID) {
    require(rank < 13, "No such rank exists.");
    require(cost > 0, "Free minting is never allowed."); // Should I set a higher floor though? 1/10^6 is still a VERY small fee!
    uint requestID = rankChangeRequestCNT;
    rankChangeRequestCNT++;
    uint propID = voting.addProposition(msg.sender, 5000000, startTime, endTime);
    rankChangeRequests[requestID] = RankChangeRequest(rank, cost, propID);
    return requestID;
	}
	function requestMintLimitChange(uint8 rank, uint64 limit) public returns (uint propositionID) {

	}
	function requestGotMint(address receiver) public returns (uint requestID) {

	}
}
