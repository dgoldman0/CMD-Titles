pragma solidity ^0.8.0;
import "./OpenZeppelin/ERC721.sol";
import "./OpenZeppelin/SafeERC20.sol";
import "./OpenZeppelin/Address.sol";
import "./VotingRights.sol"
import "./Democretized.sol";

contract WRLDTitles is ERC721, VotingRights, Democratized {
	using Address for address;

  uint64 titleCount;

	mapping(address => uint) private _addressCMDBalance;
  uint private _reserveBalance; // The amount of CMD reserved to pay for CMDBalance

	event TitleMinted(uint64 titleID, uint8 rank, uint parentID, address minter);
	event CMDClaim(address minter, uint amount);

	//tight packing would allow for multiple attributes to be stored in a single uint256 slot in evm.
	struct Title {
		uint8 rank;
		uint64 titleID; // Global ID of this token
		uint64 parentTitleID; // Global ID of parent token
		uint64 localID; // (parentTitleId, localId) rather than single global mint ID
    uint64 childCount; // Number of children currently minted by this title
		address minterAddress;
	}

  mapping(uint => Title) _titles;

  // Gives details about how many children a title of a given rank can mint and how much it costs to mint
  struct Rank {
    uint mintCost; // The cost to mint a new title of the given rank
    uint64 maxChildren; // The maximum number of child titles the rank can have
  }

  mapping (uint8 => Rank) ranks;

  constructor() {
    // Initial settings for ranks
  }

  function mintCost(uint8 rank) public view returns (uint cost) {
    require(rank < 13, "No such rank!");
    return ranks[rank].mintCost;
  }

  function mintTitle(uint64 _parentID) public returns (uint64 id) {
    // Mint the title
    Title parent = _titles[_parentID];
    require(ownerOf(parent) == msg.sender, "User does not own this title.");
    uint8 rank = parent.rank + 1;
    require(rank < 12, "Provincial titles cannot mint lower tier titles.");
    uint cost = ranks[rank].mintCost;
    require(cmd_contract.balanceOf(msg.sender) >= cost, "Insufficient Funds");
    require(cmd_contract.allowance(msg.sender, address(this)) >= cost, "Insufficient Approval");
    uint64 lid = parent.childCount;
    require(lid < ranks[rank].maxChildren, "This title has reached its maximum mint count.");
    parent.childCount++;
    uint64 id = titleCount;
    titleCount++;
    Title child = Title(rank, id, _parentID, lid, 0, msg.sender);
    _titles[id] = child;
    _safeMint(msg.sender, id);

    // Distribute CMD
    cmd_contract.transferFrom(msg.sender, address(this), cost);
    // Automatically reserve 1/3 for the DAO: uses 1/3 rather than 2/3 because I divide yield by 2 AFTER distributing
    uint yield = cost * 1 / 3;
    Title memory curtitle = parent;
    do {
      _reserveBalance += yield;
      address owner = ownerOf(curtitle.titleID);
      _addressCMDBalance[owner] += yield;
      curtitle = _titles[curtitle._parentID];
      yield = yield / 2;
    } while (curtitle.rank != 0);
  }

  function withdrawCMD() public returns (uint amt) {
    uint cmd = _addressCMDBalance[msg.sender];
    _addressCMDBalance[msg.sender] = 0;
    _reserveBalance -= cmd;
    cmd_contract.transferFrom(address(this), msg.sender, cmd);
  }
}
