pragma solidity ^0.8.0;
import "../openZeppelin/IERC20.sol";
import "./IERC20Forgable.sol";
import "../openZeppelin/Address.sol";
import "../governance/Democratized.sol";

/// @title An ERC20 token standard that allows minting the token upon receiving ERC20 resource tokens

/// @dev It would be useful to add preForge and postForge hooks to allow additional functionality. This feature will be important with CUR token as additional tokens will be minted after the forge process.
/// @dev Adding activeFrom and activeUntil and removing bool active, allowing, without further voting, temporary use of resources
abstract contract MultiERC20Forgable is ERC20, IERC20Forgable, Democratized {
    uint256 UINT_MAX = 2**256 - 1;
    struct ResourceToken {
        ERC20 tokenAddress;
        uint256 conversionRate;
        uint256 forgeLimit;
        uint256 totalUsed;
        uint256 activeFrom;
        uint256 activeUntil;
    }
    /// @dev We really don't need 2^256 possible resource tokens! Change to uint8 or uint16 at most!
    uint256 private _resourceTokenCount;
    mapping (uint256 => ResourceToken) private _resourceTokens; // The token that will be used in the forging process.
    mapping (address => uint256) private _reverseLookup;

    mapping (address => uint256) private _lastMinted;
    uint256 private _smithCount;
    uint256 private _smithFee;
    mapping (address => bool) private _registered;

    /// @dev Need to set request to change the lock time
    uint _forgeLockTime = 3600 seconds;

    constructor(string memory name_, string memory symbol_, uint256 smithFee_, ERC20 resourceToken_, uint256 rate_, uint256 limit_, uint256 initial_) ERC20(name_, symbol_) {
        _resourceTokens[0] = ResourceToken(resourceToken_, rate_, limit_, 0, true);
        _resourceTokenCount = 1;
        _smithFee = smithFee_;
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
        if (dif > _forgeLockTime) return 0;
        return _forgeLockTime - dif;
    }
    function smithCount() external view override returns (uint256 count) {
        return _smithCount;
    }
    function smithFee() external view override returns (uint256 fee) {
        return _smithFee;
    }
    /// @dev Might want to have a _isRegistered function that can be overwritten
    // This way we can do things like allowing smithing based on whether a person has a title
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
        require(block.timestamp >  _lastMinted[msg.sender], "Last mint was too recent.");
        _lastMinted[msg.sender] = block.timestamp;
        require(tokenID_ < _resourceTokenCount, "No such resource token.");
        ResourceToken memory token = _resourceTokens[tokenID_];
        require(block.timestamp > token.activeFrom && time.activeUntil > block.timestamp, "Resource not active.");
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
        uint256 activeFrom;
        uint256 activeUntil;
        uint256 propositionID;
    }
    struct ResourceAdjustmentRequest {
        uint256 resourceID;
        bool toggle; // Toggle whether the request is for a rate change (true) or limit change (false)
        uint256 val;
        uint256 propositionID;
    }
    struct FeeChangeRequest {
        uint256 newFee;
        uint256 propositionID;
    }
    struct ActiveChangeRequest {
        uint256 resourceID;
        uint256 activeFrom;
        uint256 activeUntil;
        uint256 propositionID;
    }
    mapping (uint256 => NewResourceRequest) _newResourceRequests;
    mapping (uint256 => ResourceAdjustmentRequest) _resourceAdjustmentRequests;
    mapping (uint256 => FeeChangeRequest) _feeChangeRequests;
    mapping (uint256 => ActiveChangeRequest) _activeChangeRequests;
    uint256 _newResourceRequestCNT;
    uint256 _resourceAdjustmentRequestCNT;
    uint256 _feeChangeRequestCNT;
    uint256 _activeChangeRequestCNT;
    event NewResourceRequested(uint256 requestID, address tokenAddress, uint256 converesionRate, uint256 forgeLimit, uint256 propID);
    event NewResourceAdded(uint256 resourceID, uint256 requestID, address tokenAddress);
    function requestNewResource(address addr_, uint256 rate_, uint256 limit_) public returns (uint256 requestID) {
        uint256 requestID = _newResourceRequestCNT;
        _newResourceRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _newResourceRequests[requestID] = NewResourceRequest(addr_, rate_, limit_, propID);
        emit NewResourceRequested(requestID, addr_, rate_, limit_, 0, UINT_MAX, propID);
        return requestID;
    }
    function requestNewResource(address addr_, uint256 rate_, uint256 limit_, uint256 activeFrom_, uint256 activeUntil_) public returns (uint256 requestID) {
        uint256 requestID = _newResourceRequestCNT;
        _newResourceRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _newResourceRequests[requestID] = NewResourceRequest(addr_, rate_, limit_, propID);
        emit NewResourceRequested(requestID, addr_, rate_, limit_, activeFrom_, activeUntil_, propID);
        return requestID;
    }
    function requestResourceAdjustment(uint256 resourceID_, bool toggle_, uint256 val_) public returns (uint256 requetID) {
        require(resourceID_ < _resourceTokenCount, "No such resource defined.");
        uint256 requestID = _resourceAdjustmentRequestCNT;
        _resourceAdjustmentRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _resourceAdjustmentRequests[requestID] = ResourceAdjustmentRequest(resourceID_, toggle_, val_, propID);
        return requestID;
    }
    function requestActiveChange(uint256 resourceID_, uint256 activeFrom_, uint256 activeUntil_) public returns (uint256 requestID) {
        require(resourceID_ < _resourceTokenCount, "No such resource defined.");
        uint256 requestID = _activeChangeRequestCNT;
        _activeChangeRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _activeChangeRequests[requestID] = ActiveChangeRequest(resourceID_, activeFrom_, activeUntil_, propID);
        return requestID;
    }
    function executeAddResource(uint256 requestID_) public returns (uint256 resourceID) {
        require(requestID_ < _newResourceRequestCNT, "No such request.");
        NewResourceRequest memory request = _newResourceRequests[requestID_];
        voting.executeProposition(request.propositionID, msg.sender);
        uint resourceID = _addResourceToken(request.tokenAddress, request.conversionRate, request.forgeLimit, request.activeFrom, request.activeUntil);
        emit NewResourceAdded(resourceID, requestID_, request.tokenAddress);
        return resourceID;
    }
    function requestFeeChange(uint256 newFee_) public returns (uint256 requestID) {
        uint256 requestID = _feeChangeRequestCNT;
        _feeChangeRequestCNT++;
        uint propID = voting.addProposition(msg.sender, 5000000, block.timestamp + 1 days, block.timestamp + 8 days);
        _feeChangeRequests[requestID] = FeeChangeRequest(newFee_, propID);
        return requestID;
    }
    function checkIfResource(address tokenAddress) public view returns (bool isResource) {
        return (_reverseLookup[tokenAddress] != 0 || address(_resourceTokens[0].tokenAddress) == tokenAddress);
    }
    /// @dev returns 0 if not set or base resource token!
    function getResourceID(address tokenAddress) public view returns (uint256 resourceID) {
        return _reverseLookup[tokenAddress];
    }
    function _addResourceToken(address tokenAddress, uint conversionRate, uint forgeLimit, uint activeFrom_, uint activeUntil_) internal returns (uint resourceID) {
        require(!checkIfResource(tokenAddress), "Token already has a resource!");
        uint256 resourceID = _resourceTokenCount;
        _resourceTokenCount++;
        _resourceTokens[resourceID] = ResourceToken(ERC20(tokenAddress), conversionRate, forgeLimit, 0, activeFrom_, activeUntil_);
        return resourceID;
    }
    /// @dev Add executeResoureAddition!

    function executeResourceAdjustment(uint256 requestID_) public {
        require(requestID_ < _newResourceRequestCNT, "No such request.");
        ResourceAdjustmentRequest memory request = _resourceAdjustmentRequests[requestID_];
        voting.executeProposition(request.propositionID, msg.sender);
        ResourceToken storage token = _resourceTokens[request.resourceID];
        if (request.toggle) token.conversionRate = request.val;
        else token.forgeLimit = request.val;
    }
    function executeActiveChange(uint256 requestID_) public {
        require(requestID_ < _activeChangeRequestCNT, "No such request.");
        ActiveChangeRequest memory request = _activeChangeRequests[requestID_];
        voting.executeProposition(request.propositionID, msg.sender);
        ResourceToken storage token = _resourceTokens[request.resourceID];
        token.activeFrom = request.activeFrom;
        token.activeUntil = request.activeUntil;
    }
    function executeFeeChange(uint256 requestID_) public {
        require(requestID_ < _feeChangeRequestCNT, "No such request.");
        FeeChangeRequest memory request = _feeChangeRequests[requestID_];
        voting.executeProposition(request.propositionID, msg.sender);
       _smithFee = request.newFee;
    }
}
