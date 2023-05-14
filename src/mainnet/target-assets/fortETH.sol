// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
                                                                                    

// Github - https://github.com/FortressFinance

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {ERC4626, ERC20, FixedPointMathLib} from "src/shared/interfaces/ERC4626.sol";

abstract contract FortETH is ReentrancyGuard, ERC4626 {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;
    
    struct Fees {
        /// @notice The performance fee percentage to take for platform on harvest
        uint256 platformFeePercentage;
        /// @notice The percentage of fee to pay for caller on harvest
        uint256 harvestBountyPercentage;
        /// @notice The fee percentage to take on withdrawal. Fee stays in the vault, and is therefore distributed to vault participants. Used as a mechanism to protect against mercenary capital
        uint256 withdrawFeePercentage;
    }

    /// @notice The fees settings
    Fees public fees;

    /// @notice The internal accounting of AUM
    uint256 internal totalAUM;
    /// @notice The internal accounting of the deposit limit. Denominated in shares
    uint256 public depositCap;

    /// @notice The description of the vault
    string public description;

    /// @notice The address of owner
    address public owner;
    /// @notice The address of recipient of platform fee
    address public platform;


    /// @notice Whether deposits are paused
    bool public pauseDeposit = false;
    /// @notice Whether withdrawals are paused
    bool public pauseWithdraw = false;

    /// @notice The fee denominator
    uint256 internal constant DENOMINATOR = 1e9;
    /// @notice The maximum withdrawal fee
    uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%
    /// @notice The maximum platform fee
    uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%
    /// @notice The maximum harvest fee
    uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%


    /// @notice The address of WETH token.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The mapping of whitelisted feeless redeemers
    mapping(address => bool) public feelessRedeemerWhitelist;

    
    /// @notice The address of the active strategy
    address public activeStrategy;
    /// @notice The address list of strategies
    address[] public strategyList;

    /// @notice The mapping of strategies
    mapping(address => bool) public strategies;
    /// @notice The mapping of blacklisted strategies

    /********************************** Constructor **********************************/

    constructor(
            address _owner,
            address _platform
        )
        ERC4626(ERC20(WETH), "Fortress LSDs Primitive", "fortETH") {

        {
            Fees storage _fees = fees;
            _fees.platformFeePercentage = 50000000; // 5%
            _fees.harvestBountyPercentage = 25000000; // 2.5%
            _fees.withdrawFeePercentage = 2000000; // 0.2%
        }
        
        owner = _owner;
        platform = _platform;
        depositCap = 0;
    }

    /********************************** View Functions **********************************/

    /// @dev Get the name of the vault
    /// @return - The name of the vault
    function getName() external view returns (string memory) {
        return name;
    }

    /// @dev Get the symbol of the vault
    /// @return - The symbol of the vault
    function getSymbol() external view returns (string memory) {
        return symbol;
    }

    /// @dev Get the description of the vault
    /// @return - The description of the vault
    function getDescription() external view returns (string memory) {
        return description;
    }

    /// @dev Get the address of the active strategy
    /// @return - The address of the active strategy
    function getActiveStrategy() external view returns (address) {
        return activeStrategy;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions
    /// @param _shares - The amount of _shares to redeem
    /// @return - The amount of _assets in return, after subtracting a withdrawal fee
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        // Calculate assets based on a user's % ownership of vault shares
        uint256 assets = convertToAssets(_shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a fee - zero if user is the last to withdraw
        uint256 _fee = (_totalSupply == 0 || _totalSupply - _shares == 0) ? 0 : assets.mulDivDown(fees.withdrawFeePercentage, DENOMINATOR);

        // Redeemable amount is the post-withdrawal-fee amount
        return assets - _fee;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions
    /// @param _assets - The amount of _assets to withdraw
    /// @return - The amount of shares to burn, after subtracting a fee
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        // Calculate shares based on the specified assets' proportion of the pool
        uint256 _shares = convertToShares(_assets);

        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal if user is not the last to withdraw
        return (_totalSupply == 0 || _totalSupply - _shares == 0) ? _shares : (_shares * DENOMINATOR) / (DENOMINATOR - fees.withdrawFeePercentage);
    }

    /// @dev Returns the total amount of assets that are managed by the vault
    /// @return - The total amount of managed assets
    function totalAssets() public view virtual override returns (uint256) {
        return totalAUM;
    }

    /// @dev Returns the maximum amount of the primary asset asset that can be deposited into the Vault for the receiver, through a deposit call
    function maxDeposit(address) public view override returns (uint256) {
        uint256 _assetCap = convertToAssets(depositCap);
        return _assetCap == 0 ? type(uint256).max : _assetCap - totalAUM;
    }

    /// @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call
    function maxMint(address) public view override returns (uint256) {
        return depositCap == 0 ? type(uint256).max : depositCap - totalSupply;
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Mints Vault shares to _receiver by depositing exact amount of WETH
    /// @param _assets - The amount of assets to deposit
    /// @param _receiver - The receiver of minted shares
    /// @return _shares - The amount of shares minted
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        if (_assets >= maxDeposit(msg.sender)) revert InsufficientDepositCap();

        _shares = previewDeposit(_assets);
        
        _deposit(msg.sender, _receiver, _assets, _shares);

        IERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), _assets);
        
        if (activeStrategy != address(0)) {
        _depositToStrategy(activeStrategy, _assets);
        }

        return _shares;
    }

    /// @dev Mints exact Vault shares to _receiver by depositing amount of WETH
    /// @param _shares - The shares to receive
    /// @param _receiver - The address of the receiver of shares
    /// @return _assets - The amount of underlying assets received
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        if (_shares >= maxMint(msg.sender)) revert InsufficientDepositCap();

        _assets = previewMint(_shares);

        _deposit(msg.sender, _receiver, _assets, _shares);

        IERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), _assets);
        
        if (activeStrategy != address(0)) {
            _depositToStrategy(activeStrategy, _assets);
        }

        return _assets;
    }

    /// @dev Withdraw not available
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 _shares) {}
     

    /// @dev Redeem not available
    function redeem(uint256 _shares, address _receiver, address _owner) external override nonReentrant returns (uint256 _assets) {}
       
    /// @dev Adds emitting of YbTokenTransfer event to the original function
    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
        emit YbTokenTransfer(msg.sender, to, amount, convertToAssets(amount));
        
        return true;
    }

    /// @dev Adds emitting of YbTokenTransfer event to the original function
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
        emit YbTokenTransfer(from, to, amount, convertToAssets(amount));

        return true;
    }

    /// @notice Platform has admin access
    modifier onlyOwner() {
        if (msg.sender != owner && msg.sender != platform) revert Unauthorized();
        _;
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Adds new strategy
    function addStrategy(address _strategy) external onlyOwner nonReentrant {
        
        if (strategies[_strategy]) revert StrategyAlreadyExist(); 

        strategies[_strategy] = true;
        strategyList.push(_strategy);

        emit StrategyAdded(block.timestamp, _strategy);
    }
    /// @dev Set active strategy
    function activateStrategy(address _strategy) public onlyOwner nonReentrant {
        if (activeStrategy != address(0)) {
            IStrategy(activeStrategy).terminateExecution();
        } 

        activeStrategy = _strategy;

        uint256 balance = ERC20(WETH).balanceOf(address(this));
        if (balance>0) {
            _depositToStrategy(activeStrategy, balance);
        }

        emit StrategyActivated(block.timestamp, _strategy);
    }

    /// @dev Withdraws all funds from active strategy into this contract
    function withdrawFromStrategy(address _strategy) external onlyOwner nonReentrant {
        if (!strategies[_strategy]) revert StrategyNonExistent();
        
        uint256 _before = ERC20(WETH).balanceOf(address(this));
        IStrategy(_strategy).terminateExecution();
        uint256 _amount = ERC20(WETH).balanceOf(address(this))- _before;

        emit WithdrawnFromStrategy(block.timestamp, _strategy, _amount);
    }

    /// @dev Updates the feelessRedeemerWhitelist
    /// @param _address - The address to update
    /// @param _whitelist - The new whitelist status
    function updateFeelessRedeemerWhitelist(address _address, bool _whitelist) external {
        if (msg.sender != owner) revert Unauthorized();

        feelessRedeemerWhitelist[_address] = _whitelist;
    }

    /// @dev Updates the vault fees
    /// @param _withdrawFeePercentage - The new withdrawal fee percentage
    /// @param _platformFeePercentage - The new platform fee percentage
    /// @param _harvestBountyPercentage - The new harvest fee percentage
    function updateFees(uint256 _withdrawFeePercentage, uint256 _platformFeePercentage, uint256 _harvestBountyPercentage) external {
        if (msg.sender != owner) revert Unauthorized();
        if (_withdrawFeePercentage > MAX_WITHDRAW_FEE) revert InvalidAmount();
        if (_platformFeePercentage > MAX_PLATFORM_FEE) revert InvalidAmount();
        if (_harvestBountyPercentage > MAX_HARVEST_BOUNTY) revert InvalidAmount();

        Fees storage _fees = fees;
        _fees.withdrawFeePercentage = _withdrawFeePercentage;
        _fees.platformFeePercentage = _platformFeePercentage;
        _fees.harvestBountyPercentage = _harvestBountyPercentage;

        emit UpdateFees(_withdrawFeePercentage, _platformFeePercentage, _harvestBountyPercentage);
    }

    /// @dev updates the vault settings
    /// @param _platform - The Fortress platform address
    /// @param _owner - The vault owner address
    /// @param _depositCap - The deposit cap
    function updateSettings(address _platform, address _owner, uint256 _depositCap) external {
        if (msg.sender != owner) revert Unauthorized();

        platform = _platform;
        owner = _owner;
        depositCap = _depositCap;

        emit UpdateInternalUtils();
    }

    /// @dev Pauses deposits/withdrawals for the vault
    /// @param _pauseDeposit - The new deposit status
    /// @param _pauseWithdraw - The new withdraw status
    function pauseInteractions(bool _pauseDeposit, bool _pauseWithdraw) external {
        if (msg.sender != owner) revert Unauthorized();

        pauseDeposit = _pauseDeposit;
        
        emit PauseInteractions(_pauseDeposit, _pauseWithdraw);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _mint(_receiver, _shares);
        totalAUM += _assets;

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    function _depositToStrategy(address _strategy, uint256 _amount) internal nonReentrant {
        if (!strategies[_strategy]) revert StrategyNonExistent();

        _approve(WETH, _strategy, _amount);
        IStrategy(_strategy).deposit(_amount);
        IStrategy(_strategy).execute();

        emit DepositedToStrategy(block.timestamp, _strategy, _amount);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {}

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, _amount);
    }

    /********************************** Events **********************************/

    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);
    event YbTokenTransfer(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event UpdateFees(uint256 _withdrawFeePercentage, uint256 _platformFeePercentage, uint256 _harvestBountyPercentage);
    event PauseInteractions(bool _pauseDeposit, bool _pauseWithdraw);
    event UpdateInternalUtils();
    event DepositedToStrategy(uint256 indexed _timestamp, address _strategy, uint256 _amount);
    event WithdrawnFromStrategy(uint256 indexed _timestamp, address _strategy, uint256 _amount);
    event StrategyActivated(uint256 indexed _timestamp, address _strategy);
    event StrategyAdded(uint256 indexed _timestamp, address _strategy);
    /********************************** Errors **********************************/

    error Unauthorized();
    error InsufficientBalance();
    error InsufficientAllowance();
    error InvalidAmount();
    error InsufficientDepositCap();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientAmountOut();
    error DepositPaused();
    error WithdrawPaused();
    error WeightExcess();
    error NoAssetVaults();
    error AssetVaultNotAvailable();
    error LengthNotMatch();
    error StrategyNonExistent();
    error StrategyAlreadyExist();
}