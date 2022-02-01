pragma solidity ^0.8.0;
import "../openZeppelin/Address.sol";
import "../openZeppelin/ERC721Enumerable.sol";
import "./Democratized.sol";
import "./VotingRights.sol";
import "./VotingMachine.sol";

/// @title A contract to allow using CMD Titles to mint local control titles as an alternative to needing standard governance.
contract ForgeAndSwapTitles is ERC721Enumerable, VotingRights, Democratized, VotingMachine {
	using Address for address;
  ERC721 _baseTitles; // The address of the base titles (CMDTitles)
  ERC20 _mintResource;
  uint _mintPrice;
  mapping (uint => bool) _titleUsed; // To check whether the CMD title was already used to mint a local title.
  mapping (uint => uint) _titleMintedBy; // To check which CMD title minted the local title.

  function mintTitle() public returns (uint titleID) {
    require(_mintResource.balanceOf(msg.sender) >= _mintPrice, "Insufficient funds for minting.");
    require(_mintResource.allowance(msg.sender, address(this)) >= _mintPrice, "Insufficient allowance for transfer of funds.");
    _mintResource.transferFrom(msg.sender, address(this), _mintPrice);

  }
  function mintTitle(uint _originalID) public returns (uint titleID) {
    require(_baseTitles.ownerOf(_originalID) == msg.sender, "User does not own this title.");
    require(_titleUsed[_originalID], "Global title already used to mint local title.");
  }
}
