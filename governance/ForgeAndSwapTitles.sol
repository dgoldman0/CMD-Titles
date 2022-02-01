pragma solidity ^0.8.0;

/// @dev Might be interesting to create a secondary system that allows swapping provincial titles from CMD Titles for a more local voting title so that the local titles can be minted with a different asset OR through swapping. Essentially, it's like token forge only forging through swapping titles.
/// @dev This approach might be nice if a project wants to interface with the global democratized system but also have its own voting titles.
/// @dev Might take this apporach for each of the forgable tokens actually so that there's some disconnect but some overlap too.
/// @dev Like with MultiERC20Forgable, I could allow multiple resources, but I'm not sure yet.

contract ForgeAndSwapTitles is MultiERC721Forgable, VotingRights, DefaultDemocratized {
  ERC721 _baseTitles; // The address of the base titles (CMDTitles)
  ERC20 _mintResource;
  uint _mintPrice;

  function mintTitle() public returns (uint titleID) {

  }
  function mintTitle(uint _originalID) public returns (uint titleID) {
    
  }
}