pragma solidity ^0.8.0;
import "../openZeppelin/ERC721.sol";
import "./CMDTitles.sol";
import "./Democratized.sol";
import "./VotingRights.sol";
import "./VotingMachine.sol";

/// @title A contract to allow using CMD Titles to mint local control titles as an alternative to needing standard governance.
contract LocalTitles is ERC721, VotingRights, Democratized, VotingMachine {
  uint _titleCount; 
  CMDTitles _baseTitles; // The address of the base titles (CMDTitles)
  ERC20 _mintResource;
  uint _mintPrice;
  mapping (uint => bool) _titleUsed; // To check whether the CMD title was already used to mint a local title.
  mapping (uint => uint) _titleMintedBy; // To check which CMD title minted the local title. Will be 0 if minted using resource.

  struct MintPriceChangeRequest {
    uint newPrice;
    uint propositionID;
  }

  mapping (uint => MintPriceChangeRequest) _mintPriceChangeRequests;
  uint _mintPriceChangeRequestCNT;

  event MintPriceChangeRequested(address requestedBy, uint requestID, uint price);
  event MintPriceChanged(address executedBy, uint requestID, uint price);

  constructor(string memory name_, string memory symbol_, CMDTitles cmd_, ERC20 resource_, uint price_) ERC721(name_, symbol_) Democratized(this) VotingMachine(this) {
    _baseTitles = cmd_;
    _mintResource = resource_;
    _mintPrice = price_;
  }

  function getVotingWeight(uint titleID) external view override returns (uint weight) {
    return 1;
  }
  function hasFiduciaryPower(address addr, uint titleID) external view override returns (bool hasPower) {
    return ownerOf(titleID) == addr;
  }
  function electorateSize() external view override returns (uint size) {
    return _titleCount;
  }
  function requestMintPriceChange(uint newPrice_) public returns (uint requestID) {
    uint requestID = _mintPriceChangeRequestCNT;
    uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
    _mintPriceChangeRequestCNT++;
    _mintPriceChangeRequests[requestID] = MintPriceChangeRequest(newPrice_, propID);
    emit MintPriceChangeRequested(msg.sender, propID, newPrice_);
    return requestID;
  }
  function executeMintChangeRequest(uint requestID_) public {
    require(requestID_ < _mintPriceChangeRequestCNT, "No such request.");
    MintPriceChangeRequest memory request = _mintPriceChangeRequests[requestID_];
    voting.executeProposition(request.propositionID, msg.sender);
    _mintPrice = request.newPrice;
    emit MintPriceChanged(msg.sender, requestID_, request.newPrice);
  }
  function mintTitle() public returns (uint titleID) {
    require(_mintResource.balanceOf(msg.sender) >= _mintPrice, "Insufficient funds for minting.");
    require(_mintResource.allowance(msg.sender, address(this)) >= _mintPrice, "Insufficient allowance for transfer of funds.");
    _mintResource.transferFrom(msg.sender, address(this), _mintPrice);
    uint titleID = _titleCount;
    _titleCount++;
    _mint(msg.sender, titleID);
    return titleID;

  }
  function mintTitle(uint _originalID) public returns (uint titleID) {
    require(_baseTitles.ownerOf(_originalID) == msg.sender, "User does not own this title.");
    require(_titleUsed[_originalID], "Global title already used to mint local title.");
    _titleUsed[_originalID] = true;
    uint titleID = _titleCount;
    _titleCount++;
    _mint(msg.sender, titleID);
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, Democratized) returns (bool) {
    return Democratized.supportsInterface(interfaceId);
  }
}
