pragma solidity ^0.8.0;
import "../openZeppelin/IERC20.sol";
import "./IERC20Forgable.sol";
import "../openZeppelin/Address.sol";
import "../governance/Democratized.sol";

// ERC20Forgable token that allows for additional minting resources and with built in governance control. 
contract MultiERC20Forgable is ERC20, IERC20Forgable, DefaultDemocratized {
    struct ResourceToken {
        ERC20 tokenAddress;
        uint256 totalMaterialUsed;
        uint256 conversionRate;
    }
    uint256 resourceTokenCount;
    mapping (uint256 => ResourceToken) _resourceTokens; // The token that will be used in the forging process.
    mapping (address => uint256) _lastMinted;
    uint256 _smithCount;
    uint256 _smithFee;
    mapping (address => bool) _registered;

    constructor(string memory name_, string memory symbol_, address memory resourceToken_) ERC20(name_, symbol_) {
        _resourceToken = resourceToken_;
    }
    function forge(uint256 amt_) external override returns (bool success) {
        return _forge(0, amt_);
    }
    function forge(uint256 tokenID_, uint256 amt_) {
        return _forge(tokenID_, amt_);
    }
    function maxForge() public view override returns (uint256) {
        if (_totalMaterial / 1000 < 100000000000) return 100000000000;
        return _totalMaterial / 1000;
    }
    function conversionRate() external view override returns (uint256 rate) {

    }
    function timeToForge(address addr) external view override returns (uint256 time) {
        uint256 dif = (block.timestamp - _lastMinted[addr]);
        if (dif > 3600) return 0;
        return 3600 - dif;
    }
    function forgePrice() external override returns (uint256 price) {
        return _costToForge();
    }
    function smithCount() external view override returns (uint256 count) {
        return _smithCount;
    }
    function smithFee() external view returns (uint256 fee);
    function canSmith() external view returns (bool able);
    function canSmith(address addr_) external view returns (bool);
    function totalMaterialUsed() external view returns (uint256 totalUsed);
    function firstMint() external view returns (uint256 date);
    function lastMint() external view returns (uint256 date);
    function paySmithingFee() external payable returns (bool fee);

    function _forge(uint256 tokenID_, uint256 amt_) {
        require(tokenID < resourceTokenCount, "No such resource token.");
        require(amt_ <= _forgeAllowed(), "The forge is too small to fit the amount of material requested.");
        require(_resourceToken.balanceOf(msg.sender >= amt_), "Insufficient funds to mint.");
        require(_resourceToken.allowance(msg.sender) >= amt_, "Insufficient approved funds.");
        ResourceToken memory token = _resourceTokens[tokenID_];
        ERC20 memory rt = token.tokenAddress;
        rt.transferFrom(msg.sender, address(this), amt_);
        uint256 amt = msg.tokenvalue / token.conversionRate;
        emit Forged(msg.sender, msg.tokenvalue, amt);
        _mint(msg.sender, amt);        
    }
    function _forgeAllowed() internal returns (uint256 allowed) {

    }
}