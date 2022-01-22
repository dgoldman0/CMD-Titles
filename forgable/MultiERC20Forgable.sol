pragma solidity ^0.8.0;
import "../openZeppelin/IERC20.sol";
import "./IERC20Forgable.sol";
import "../openZeppelin/Address.sol";
import "../governance/Democratized.sol";

// ERC20Forgable token that allows for additional minting resources and with built in governance control. 
/// @dev Since external view functions won't be altering anything, there's no need to check if a resource token is actually set.
contract MultiERC20Forgable is ERC20, IERC20Forgable, DefaultDemocratized {
    struct ResourceToken {
        ERC20 tokenAddress;
        uint256 conversionRate;
        uint256 forgeLimit;
        uint256 totalUsed;
    }
    uint256 _resourceTokenCount;
    mapping (uint256 => ResourceToken) _resourceTokens; // The token that will be used in the forging process.
    mapping (address => uint256) _lastMinted;
    uint256 _smithCount;
    uint256 _smithFee;
    mapping (address => bool) _registered;

    constructor(string memory name_, string memory symbol_, address resourceToken_, uint256 rate_, uint256 limit_, uint256 initial_) ERC20(name_, symbol_) {
        _resourceTokens[0] = ResourceToken(ERC20(resourceToken_), rate_, limit_, 0);
        _mint(msg.sender, initial_);
    }
    function forge(uint256 amt_) external override returns (uint256 amt) {
        return _forge(0, amt_);
    }
    function forge(uint256 tokenID_, uint256 amt_) external returns (uint256 amt) {
        return _forge(tokenID_, amt_);
    }
    function forgeLimit() public view override returns (uint256) {
        return _resourceTokens[0].forgeLimit;
    }
    function forgeLimit(uint256 tokenID_) external view returns (uint256 limit) {
        return _resourceTokens[tokenID_].forgeLimit;
    }
    function conversionRate() external view override returns (uint256 price) {
        return _resourceTokens[0].conversionRate;
    }
    function conversionRate(uint256 tokenID_) external view returns (uint256 price) {
        return _resourceTokens[tokenID_].conversionRate;
    }
    function timeToForge(address addr) external view override returns (uint256 time) {
        uint256 dif = (block.timestamp - _lastMinted[addr]);
        if (dif > 3600) return 0;
        return 3600 - dif;
    }
    function smithCount() external view override returns (uint256 count) {
        return _smithCount;
    }
    function smithFee() external view override returns (uint256 fee) {
        return _smithFee;
    }
    function canSmith() external view override returns (bool able) {
        return _registered[msg.sender];
    }
    function canSmith(address addr_) external view override returns (bool) {
        return _registered[addr_];
    }
    function totalMaterialUsed() external view override returns (uint256 totalUsed) {
        return _resourceTokens[0].totalUsed;
    }
    function totalMaterialUsed(uint256 tokenID_) external view returns (uint256 totalUsed) {
        return _resourceTokens[tokenID_].totalUsed;
    }
    function lastMint() external view override returns (uint256 date) {
        return _lastMinted[msg.sender];
    }
    function paySmithingFee() external payable override returns (bool paid) {
        require(!_registered[msg.sender], "This smith is already registered.");
        require(msg.value == _smithFee, "Incorrect fee.");
        _registered[msg.sender] = true;
        return true;
    }
    function _forge(uint256 tokenID_, uint256 amt_) internal returns (uint256 amt) {
        require(tokenID_ < _resourceTokenCount, "No such resource token.");
        ResourceToken memory token = _resourceTokens[tokenID_];
        require(amt_ <= token.forgeLimit, "The forge is too small to fit the amount of material requested.");
        ERC20 rt = token.tokenAddress;
        require(rt.balanceOf(msg.sender) >= amt_, "Insufficient funds to mint.");
        require(rt.allowance(msg.sender, address(this)) >= amt_, "Insufficient approved funds.");
        rt.transferFrom(msg.sender, address(this), amt_);
        uint256 amt = amt_ / token.conversionRate;
        emit Forged(msg.sender, amt_, amt);
        _mint(msg.sender, amt);        
        return amt;
    }
    /* Goverance */
    struct NewResourceRequest {
        address tokenAddress;
        uint256 conversionRate;
        uint256 forgeLimit;
        uint256 propositionID;
    }
    mapping (uint256 => NewResourceRequest) _newResourceRequests;
    uint256 _newResourceRequestCNT;
    function requestNewResource(address addr_, uint256 rate_, uint256 limit_) public returns (uint256 requestID) {
        uint256 requestID = _newResourceRequestCNT;
        _newResourceRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _newResourceRequests[requestID] = NewResourceRequest(addr_, rate_, limit_, propID);
        return requestID;
    }
    function executeAddResource(uint256 requestID_) returns (uint256 resourceID) {
        require(requestID < _newResourceRequestCNT, "No such request.");

    }
}