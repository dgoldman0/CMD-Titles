pragma solidity ^0.8.0;
import "../openZeppelin/ERC20.sol";
import "../openZeppelin/Address.sol";
import "../openZeppelin/ERC721.sol";
import "../openZeppelin/ERC721Enumerable.sol";
import "./VotingRights.sol";
import "./Democratized.sol";


/// @dev withdrawCMD balance (clearly not calculating right there)
contract CMDTitles is ERC721Enumerable, VotingRights, VotingMachine, Democratized {
	using Address for address;
  ERC20 cmd;
  uint64 titleCount;
  mapping (uint8 => uint64) rankTitleCount;
  address private _creator;
	mapping(address => uint) private _addressCMDBalance;
  uint private _reserveBalance; // The amount of CMD reserved to pay for CMDBalance

	event TitleMinted(uint titleID, address minter);
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
    uint256 mintCost; // The cost to mint a new title of the given rank
    uint64 maxChildren; // The maximum number of child titles the rank can have
  }

  mapping (uint8 => Rank) ranks;

  constructor() ERC721("CMD Title", "TTL") Democratized(this) VotingMachine(this) public {
    // Initial settings for ranks
    _creator = msg.sender;
    uint8 i;
    uint256 cost = 40960000000000000000000; // Cost of god title is 40960 CMD
    uint64 maxChildren = 10; // Only ten children titles per title
    for (i = 0; i < 13; i++) {
      ranks[i] = Rank(cost, maxChildren);
      cost = cost / 2; // Each lower rank costs 1/2 the cost of the previous rank
    }
    for (i = 0; i < 50; i++) {
      _mintGodTitle(msg.sender);
    }
  }
  function setCMD(address addr_) external {
    require(msg.sender == _creator, "Not creator!");
    if (address(cmd) == address(0)) cmd = ERC20(addr_);
  }
  function getVotingWeight(uint titleID) external view override returns (uint weight) {
    if (titles[titleID].rank == 12) return 1;
    return 0;
  }
  function hasFiduciaryPower(address addr, uint titleID) external view override returns (bool hasPower) {
    return ownerOf(titleID) == addr;
  }
  function electorateSize() external view override returns (uint size) {
    return rankTitleCount[12];
  }
  function mintCost(uint8 rank) public view returns (uint cost) {
    require(rank < 13, "No such rank!");
    return ranks[rank].mintCost;
  }
  /// @dev Should even this be changable by vote? Maybe.
  function _baseURI() internal view override virtual returns (string memory) {
    return "https://titles.wrldcoin.io/";
  }
  function mintTitle(uint _parentID) public returns (uint id) {
    // Mint the title
    Title storage parent = titles[_parentID];
    require(ownerOf(_parentID) == msg.sender, "User does not own this title.");
    uint8 rank = parent.rank + 1;
    require(rank > 0, "God titles must be minted through vote.");
    require(rank < 12, "Provincial titles cannot mint lower tier titles.");
    uint cost = ranks[rank].mintCost;
    require(cmd.balanceOf(msg.sender) >= cost, "Insufficient Funds");
    require(cmd.allowance(msg.sender, address(this)) >= cost, "Insufficient Approval");
    uint64 lid = parent.childCount;
    require(lid < ranks[rank].maxChildren, "This title has reached its maximum mint count.");
    parent.childCount++;
    uint id = titleCount;
    titleCount++;
    titles[id] = Title(rank, id, _parentID, lid, 0, msg.sender);
    _safeMint(msg.sender, id);
    rankTitleCount[rank]++;

    // Distribute CMD
    cmd.transferFrom(msg.sender, address(this), cost);
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
    emit TitleMinted(id, msg.sender); 
    return id;
  }
  function _mintGodTitle(address receiver) private returns (uint tokenID) {
    uint id = titleCount;
    titleCount++;
    titles[id] = Title(0, id, 0, rankTitleCount[0], 0, msg.sender);
    rankTitleCount[0]++;
    _safeMint(receiver, id);
    emit TitleMinted(id, msg.sender);
    return id;
  }
  function availableCMD() public returns (uint available) {
    return _addressCMDBalance[msg.sender];
  }
	// Withdraws the available CMD held in reserve for the user
  function withdrawCMD() public returns (uint amt) {
    uint amt = _addressCMDBalance[msg.sender];
    assert(_reserveBalance >= amt);
    _addressCMDBalance[msg.sender] = 0;
    _reserveBalance -= amt;
    cmd.transferFrom(address(this), msg.sender, amt);
    return amt;
  }
  /* Governance */
  // Requests
  struct RankChangeRequest {
    uint8 rank;
    uint256 val;
    /// @dev Rename as toggle and roll the two request functions into one function.
    bool cost_children; // Whether the request is to change the cost or the max child limit. True/false=cost/children
    uint propositionID;
  }
  struct GodMintRequest {
    uint8 amt; // Number of god titles to mint: Max 255 at a time
    address receiver;
    uint propositionID;
  }
  uint rankChangeRequestCNT;
  uint godMintRequestCNT;
  mapping (uint => RankChangeRequest) rankChangeRequests;
  mapping (uint => GodMintRequest) godMintRequests;

  function rankOf(uint tokenID_) public view returns (uint8 rank) {
    require(tokenID_ < ERC721Enumerable.totalSupply(), "No such title!");
    return titles[tokenID_].rank;
  }
	// Override ERC20 withdraw to prevent CMD from being withdrawn or otherwise ensure that the DAO is not drained of CMD needed or _reserveBalance

	// Democretized Controls
  // Could roll these two into one function
	function requestRankCostChange(uint8 rank, uint256 cost) public returns (uint requestID) {
    require(rank < 13, "No such rank exists.");
    require(cost > 0, "Free minting is never allowed."); // Should I set a higher floor though? 1/10^6 is still a VERY small fee!
    uint requestID = rankChangeRequestCNT;
    rankChangeRequestCNT++;
    // Simple majority vote starting 24 hours after request and ending one week after request
    uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
    rankChangeRequests[requestID] = RankChangeRequest(rank, cost, true, propID);
    return requestID;
	}
	function requestMintLimitChange(uint8 rank, uint64 limit) public returns (uint propositionID) {
    require(rank > 0, "Can't set mint limit for god titles.");
    require(rank < 12, "Only titles higher than a provincial title can be minted.");
    uint requestID = rankChangeRequestCNT;
    rankChangeRequestCNT++;
    // Simple majority vote starting 24 hours after request and ending one week after request
    uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
    rankChangeRequests[requestID] = RankChangeRequest(rank, limit, false, propID);
    return requestID;
	}
	function requestGodMint(uint8 amt, address receiver) public returns (uint requestID) {
    uint requestID = godMintRequestCNT;
    godMintRequestCNT++;
    uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
    godMintRequests[requestID] = GodMintRequest(amt, receiver, propID);
    return requestID;
	}
  function executeRankChange(uint requestID) public {
    require(requestID < rankChangeRequestCNT, "No such request.");
    RankChangeRequest memory request = rankChangeRequests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    if (request.cost_children)
      ranks[request.rank].mintCost = request.val;
    else ranks[request.rank].maxChildren = uint64(request.val);
  }
  function executeGodMint(uint requestID) public {
    require(requestID < godMintRequestCNT, "No such request.");
    GodMintRequest memory request = godMintRequests[requestID];
    voting.executeProposition(request.propositionID, msg.sender);
    for (uint8 i = 0; i < request.amt; i++) {
      _mintGodTitle(request.receiver);
    }
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, Democratized) returns (bool) {
    return Democratized.supportsInterface(interfaceId);
  }
}