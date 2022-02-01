pragma solidity ^0.8.0;

/// @dev Might be interesting to create a secondary system that allows swapping provincial titles from CMD Titles for a more local voting title so that the local titles can be minted with a different asset OR through swapping. Essentially, it's like token forge only forging through swapping titles.
/// @dev This approach might be nice if a project wants to interface with the global democratized system but also have its own voting titles.
/// @dev Might take this apporach for each of the forgable tokens actually so that there's some disconnect but some overlap too.
/// @dev Like with MultiERC20Forgable, I could allow multiple resources, but I'm not sure yet.

/// @notice This system might not work because people might not be willing to give up princincial titles. It should be fine though since the only way for them to access these contracts, which might be valuable, is to do so.

contract ForgeAndSwapTitles is ERC721Enumerable, VotingRights, DefaultDemocratized {
  ERC721 _baseTitles; // The address of the base titles (CMDTitles)
  ERC20 _mintResource;
  uint _mintPrice;

  function mintTitle() public returns (uint titleID) {

  }
  function mintTitle(uint _originalID) public returns (uint titleID) {

  }

  /// Should we allow removal of base titles, at least by vote? Someone could conceivably repeatedly withdraw them to create more local governance titles.
  // But at the same time it could be quite valiable to the DAO to be able to gain access to all those titles.
  function requestWithdrawERC721(address token, uint tokenID, address receiver) public override returns (uint propositionID) {
    require(token != _baseTitles, "Titles cannot be removed!");
    return _requestWithdraw721(token, tokenID, 5000000, receiver, block.timestamp + 24 hours , block.timestamp + 48 hours);
  }
  // To ensure that value is kept, allow the contract to vote on CMD DAO stuff!

}
