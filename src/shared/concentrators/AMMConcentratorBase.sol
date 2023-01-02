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

//  _____ _____ _____ _____                     _           _           _____             
// |  _  |     |     |     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___| __  |___ ___ ___ 
// |     | | | | | | |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _| __ -| .'|_ -| -_|
// |__|__|_|_|_|_|_|_|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_| |_____|__,|___|___|

// Github - https://github.com/FortressFinance

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "src/shared/fortress-interfaces/IFortressSwap.sol";
import "src/shared/interfaces/ERC4626.sol";
import "src/shared/interfaces/IConvexBasicRewards.sol";
import "src/shared/interfaces/IConvexBooster.sol";

abstract contract AMMConcentratorBase is ReentrancyGuard, ERC4626 {
  
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        /// @notice The amount of current accrued rewards.
        uint256 rewards;
        /// @notice The reward per share already paid for the user, with 1e18 precision.
        uint256 rewardPerSharePaid;
    }

    /// @notice Mapping from account address to user info.
    mapping(address => UserInfo) public userInfo;

    /// @notice The accumulated reward per share, with 1e18 precision.
    uint256 public accRewardPerShare;
    /// @notice The pool ID in the Booster contract.
    uint256 public boosterPoolId;
    /// @notice The percentage of fee to pay for the platform on harvest.
    uint256 public platformFeePercentage;
    /// @notice The percentage of fee to pay for the caller on harvest.
    uint256 public harvestBountyPercentage;
    /// @notice The percentage of fee to keep in the vault on withdraw.
    uint256 public withdrawFeePercentage;
    /// @notice The last block number that the harvest function was executed.
    uint256 public lastHarvestBlock;
    /// @notice The internal accounting of AUM.
    uint256 public totalAUM;
    /// @notice The address of the Booster contract.
    address public booster;
    /// @notice The address of the staking rewards contract.
    address public crvRewards;
    /// @notice Whether deposit from vault is paused.
    bool public pauseDeposit;
    /// @notice Whether withdraw from vault is paused.
    bool public pauseWithdraw;
    /// @notice Whether claim from vault is paused.
    bool public pauseClaim;
    /// @notice The list of addresses of booster reward assets.
    address[] public rewardAssets;
    /// @notice The list the pool's underlying assets.
    address[] public underlyingAssets;

    /// @notice The address of the owner.
    address public owner;
    /// @notice The address of the recipient of platform fee.
    address public platform;
    /// @notice The address of FortressSwap contract, will be used to swap tokens.
    address public swap;
    /// @notice The address of the vault we concentrate the rewards into.
    address public compounder;
    /// @notice The precision.
    uint256 internal constant PRECISION = 1e18;
    /// @notice The fee denominator.
    uint256 internal constant FEE_DENOMINATOR = 1e9;
    /// @notice The maximum withdrawal fee.
    uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%
    /// @notice The maximum platform fee.
    uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%
    /// @notice The maximum harvest fee.
    uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%
    /// @notice The address representing ETH.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    /********************************** Constructor **********************************/

    constructor(
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            address _owner,
            address _platform,
            address _swap,
            address _booster,
            address _rewardsDistributor,
            uint256 _boosterPoolId,
            address[] memory _rewardAssets,
            address[] memory _underlyingAssets,
            address _compounder
        )
        ERC4626(_asset, _name, _symbol) {
        
        accRewardPerShare = 0;
        boosterPoolId = _boosterPoolId;
        platformFeePercentage = 50000000; // 5%,
        harvestBountyPercentage = 25000000; // 2.5%,
        withdrawFeePercentage = 2000000; // 0.2%,
        booster = _booster;
        crvRewards = _rewardsDistributor;
        pauseDeposit = false;
        pauseWithdraw = false;
        pauseClaim = false;
        rewardAssets = _rewardAssets;
        underlyingAssets = _underlyingAssets;

        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            IERC20(_rewardAssets[i]).safeApprove(_swap, type(uint256).max);
        }

        IERC20(address(_asset)).safeApprove(_booster, type(uint256).max);

        owner = _owner;
        platform = _platform;
        swap = _swap;
        compounder = _compounder;
    }

    /********************************** View Functions **********************************/

    /// @dev Return the amount of pending rewards for specific pool.
    /// @param _account - The address of user.
    /// @return - The amount of pending rewards.
    function pendingReward(address _account) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[_account];
        
        // return _userInfo.rewards.add(accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(balanceOf[_account]) / PRECISION);
        return _userInfo.rewards + (((accRewardPerShare - _userInfo.rewardPerSharePaid) * balanceOf[_account]) / PRECISION);
    }

    /// @dev Indicates whether there are pending rewards to harvest.
    /// @return - True if there are pending rewards, false if otherwise.
    function isPendingRewards() external virtual view returns (bool) {
        return IConvexBasicRewards(crvRewards).earned(address(this)) > 0;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param _shares - The amount of _shares to redeem.
    /// @return - The amount of _assets in return, after subtracting a withdrawal fee.
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        // Calculate assets based on a user's % ownership of vault shares
        uint256 assets = convertToAssets(_shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a fee - zero if user is the last to withdraw
        uint256 _fee = (_totalSupply == 0 || _totalSupply - _shares == 0) ? 0 : assets.mulDivDown(withdrawFeePercentage, FEE_DENOMINATOR);

        // Redeemable amount is the post-withdrawal-fee amount
        return assets - _fee;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param _assets - The amount of _assets to withdraw.
    /// @return - The amount of shares to burn, after subtracting a fee.
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        // Calculate shares based on the specified assets' proportion of the pool
        uint256 _shares = convertToShares(_assets);

        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal if user is not the last to withdraw
        return (_totalSupply == 0 || _totalSupply - _shares == 0) ? _shares : (_shares * FEE_DENOMINATOR) / (FEE_DENOMINATOR - withdrawFeePercentage);
    }

    /// @dev Returns the total amount of the assets that are managed by the vault.
    /// @return - The total amount of managed assets.
    function totalAssets() public view override returns (uint256) {
        return totalAUM;
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Mints vault shares to _receiver by depositing exact amount of assets.
    /// @param _assets - The amount of assets to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @return _shares - The amount of shares minted.
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        _updateRewards(_receiver);

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);

        _depositStrategy(_assets, true);
        
        return _shares;
    }

    /// @dev Mints exact vault shares to _receiver by depositing assets.
    /// @param _shares - The amount of shares to mint.
    /// @param _receiver - The address of the receiver of shares.
    /// @return _assets - The amount of assets deposited.
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        _updateRewards(_receiver);

        _assets = previewMint(_shares);
        _deposit(msg.sender, _receiver, _assets, _shares);

        _depositStrategy(_assets, true);
        
        return _assets;
    }

    /// @dev Burns shares from owner and sends exact amount of assets to _receiver.
    /// @param _assets - The amount of assets to receive.
    /// @param _receiver - The address of the receiver of assets.
    /// @param _owner - The owner of shares.
    /// @return _shares - The amount of shares burned.
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 _shares) {
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _updateRewards(_owner);

        _shares = previewWithdraw(_assets);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        _withdrawStrategy(_assets, _receiver, true);

        return _shares;
    }

    /// @dev Burns exact amount of shares from owner and sends assets to _receiver.
    /// @param _shares - The amount of shares to burn.
    /// @param _receiver - The address of the receiver of assets.
    /// @param _owner - The owner of shares.
    /// @return _assets - The amount of assets sent to the _receiver.
    function redeem(uint256 _shares, address _receiver, address _owner) public override nonReentrant returns (uint256 _assets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        _updateRewards(_owner);

        _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        _withdrawStrategy(_assets, _receiver, true);

        return _assets;
    }

    /// @dev Mints vault shares to _receiver by depositing exact amount of underlying assets.
    /// @param _underlyingAmount - The amount of underlying assets to deposit.
    /// @param _underlyingAsset - The address of underlying asset to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @param _minAmount - The minimum amount of assets (LP tokens) to receive.
    /// @return _shares - The amount of shares minted.
    // slither-disable-next-line reentrancy-no-eth
    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable nonReentrant returns (uint256 _shares) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (!(_underlyingAmount > 0)) revert ZeroAmount();
        
        _updateRewards(msg.sender);

        if (msg.value > 0) {
            if (msg.value != _underlyingAmount) revert InvalidAmount();
            if (_underlyingAsset != ETH) revert InvalidAsset();
        } else {
            IERC20(_underlyingAsset).safeTransferFrom(msg.sender, address(this), _underlyingAmount);
        }

        uint256 _assets = _swapFromUnderlying(_underlyingAsset, _underlyingAmount, _minAmount);
        
        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);
        
        _depositStrategy(_assets, false);
        
        return _shares;
    }

    /// @dev Burns exact amount of shares from the owner and sends underlying assets to _receiver.
    /// @param _shares - The amount of shares to burn.
    /// @param _underlyingAsset - The address of underlying asset to redeem shares for.
    /// @param _receiver - The address of the receiver of underlying assets.
    /// @param _owner - The owner of _shares.
    /// @param _minAmount - The minimum amount of underlying assets to receive.
    /// @return _underlyingAmount - The amount of underlying assets sent to the _receiver.
    // slither-disable-next-line reentrancy-no-eth
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) public nonReentrant returns (uint256 _underlyingAmount) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();
        
        _updateRewards(msg.sender);

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        _withdrawStrategy(_assets, _receiver, false);
        
        _underlyingAmount = _swapToUnderlying(_underlyingAsset, _assets, _minAmount);
        
        if (_underlyingAsset == ETH) {
            (bool sent,) = msg.sender.call{value: _underlyingAmount}("");
            if (!sent) revert FailedToSendETH();
        } else {
            IERC20(_underlyingAsset).safeTransfer(msg.sender, _underlyingAmount);
        }

        return _underlyingAmount;
    }

    /// @dev Claims all rewards for msg.sender and sends them to receiver.
    /// @param _receiver - The recipient of rewards.
    /// @return _rewards - The amount of compounder shares sent to the _receiver.
    function claim(address _receiver) public nonReentrant returns (uint256 _rewards) {
        if (pauseClaim) revert ClaimPaused();

        _updateRewards(msg.sender);

        UserInfo storage _userInfo = userInfo[msg.sender];
        _rewards = _userInfo.rewards;
        _userInfo.rewards = 0;

        _claim(_rewards, _receiver);

        return _rewards;
    }

    /// @dev Redeem shares and claim rewards in a single transaction.
    /// @param _shares - The amount of shares to redeem.
    /// @param _receiver - The receiver of assets and rewards.
    /// @return _assets - The amount of assets sent to _receiver.
    /// @return _rewards - The amount of rewards sent to _receiver.
    // slither-disable-next-line reentrancy-eth
    function redeemAndClaim(uint256 _shares, address _receiver) external returns (uint256 _assets, uint256 _rewards) {
        _assets = redeem(_shares, _receiver, msg.sender);
        _rewards = claim(_receiver);

        return (_assets, _rewards);
    }

    /// @dev Redeem to an underlying asset and claim rewards in a single transaction.
    /// @param _shares - The amount of shares to redeem.
    /// @param _underlyingAsset - The address of the underlying asset to redeem the shares to.
    /// @param _receiver - The receiver of underlying assets and rewards.
    /// @param _minAmount - The minimum amount of underlying assets to receive.
    /// @return _underlyingAmount - The amount of underlying assets sent to _receiver.
    /// @return _rewards - The amount of rewards sent to _receiver.
    // slither-disable-next-line reentrancy-eth
    function redeemUnderlyingAndClaim(uint256 _shares, address _underlyingAsset, address _receiver, uint256 _minAmount) external returns (uint256 _underlyingAmount, uint256 _rewards) {
        _underlyingAmount = redeemSingleUnderlying(_shares, _underlyingAsset, _receiver, msg.sender, _minAmount);
        _rewards = claim(_receiver);

        return (_underlyingAmount, _rewards);
    }

    /// @dev Harvests the pending rewards and converts to assets, then re-stakes the assets.
    /// @param _receiver - The address of receiver of harvest bounty.
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get.
    /// @return _rewards - The amount of rewards that were deposited back into the vault, denominated in the vault asset.
    function harvest(address _receiver, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        if (block.number == lastHarvestBlock) revert HarvestAlreadyCalled();
        lastHarvestBlock = block.number;

        _rewards = _harvest(_receiver, _minBounty);
        accRewardPerShare = accRewardPerShare + ((_rewards * PRECISION) / totalSupply);
        
        return _rewards;
    }

    /// @dev Adds updating of rewards to the original function.
    function transfer(address to, uint256 amount) public override returns (bool) {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { balanceOf[to] += amount; }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @dev Adds updating of rewards to the original function.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _updateRewards(from);

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { balanceOf[to] += amount; }

        emit Transfer(from, to, amount);

        return true;
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Updates vault fees.
    /// @param _withdrawFeePercentage - The new withdrawal fee percentage.
    /// @param _platformFeePercentage - The new platform fee percentage.
    /// @param _harvestBountyPercentage - The new harvest bounty percentage.
    function updateFees(uint256 _withdrawFeePercentage, uint256 _platformFeePercentage, uint256 _harvestBountyPercentage) external {
        if (msg.sender != owner) revert Unauthorized();
        if (_withdrawFeePercentage > MAX_WITHDRAW_FEE) revert InvalidAmount();
        if (_platformFeePercentage > MAX_PLATFORM_FEE) revert InvalidAmount();
        if (_harvestBountyPercentage > MAX_HARVEST_BOUNTY) revert InvalidAmount();

        withdrawFeePercentage = _withdrawFeePercentage;
        platformFeePercentage = _platformFeePercentage;
        harvestBountyPercentage = _harvestBountyPercentage;

        emit UpdateFees(_withdrawFeePercentage, _platformFeePercentage, _harvestBountyPercentage);
    }

    /// @dev updates the vault external utils.
    /// @param _rewardAssets - The new address list of reward assets.
    /// @param _booster - The new booster address.
    /// @param _crvRewards - The new crvRewards address.
    function updateExternalUtils(address[] memory _rewardAssets, address _booster, address _crvRewards, uint256 _boosterPoolId) external {
        if (msg.sender != owner) revert Unauthorized();

        rewardAssets = _rewardAssets;
        booster = _booster;
        crvRewards = _crvRewards;
        boosterPoolId = _boosterPoolId;

        emit UpdateExternalUtils(_rewardAssets, _booster, _crvRewards);
    }

    /// @dev updates the vault internal utils.
    /// @param _platform - The new platform address.
    /// @param _swap - The new swap address.
    /// @param _owner - The address of the new owner.
    function updateInternalUtils(address _compounder, address _platform, address _swap, address _owner) external {
        if (msg.sender != owner) revert Unauthorized();

        compounder = _compounder;
        platform = _platform;
        swap = _swap;
        owner = _owner;

        emit UpdateInternalUtils(_compounder, _platform, _swap, _owner);
    }

    /// @dev Pauses deposits/withdrawals for the vault.
    /// @param _pauseDeposit - The new deposit status.
    /// @param _pauseWithdraw - The new withdraw status.
    /// @param _pauseWithdraw - The new claim status.
    function pauseInteractions(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseClaim) external {
        if (msg.sender != owner) revert Unauthorized();

        pauseDeposit = _pauseDeposit;
        pauseWithdraw = _pauseWithdraw;
        pauseClaim = _pauseClaim;

        emit PauseInteractions(_pauseDeposit, _pauseWithdraw, _pauseClaim);
    }

    /********************************** Internal Functions **********************************/

    function _updateRewards(address _account) internal {
        uint256 _rewards = pendingReward(_account);
        UserInfo storage _userInfo = userInfo[_account];

        _userInfo.rewards = _rewards;
        _userInfo.rewardPerSharePaid = accRewardPerShare;
    }

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _mint(_receiver, _shares);
        totalAUM += _assets;

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {
        if (pauseWithdraw) revert WithdrawPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (_owner == address(0)) revert ZeroAddress();
        if (!(_shares > 0)) revert ZeroAmount();
        if (!(_assets > 0)) revert ZeroAmount();
        
        if (_caller != _owner) {
            uint256 _allowed = allowance[_owner][_caller];
            if (_allowed < _shares) revert InsufficientAllowance();
            if (_allowed != type(uint256).max) allowance[_owner][_caller] = _allowed - _shares;
        }
        
        _burn(_owner, _shares);
        totalAUM -= _assets;
        
        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _depositStrategy(uint256 _assets, bool _transfer) internal virtual {
        if (_transfer) IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        IConvexBooster(booster).deposit(boosterPoolId, _assets, true);
    }

    function _withdrawStrategy(uint256 _assets, address _receiver, bool _transfer) internal virtual {
        IConvexBasicRewards(crvRewards).withdrawAndUnwrap(_assets, false);
        if (_transfer) IERC20(address(asset)).safeTransfer(_receiver, _assets);
    }

    function _claim(uint256 _rewards, address _receiver) internal {
        if (!(_rewards > 0)) revert ZeroAmount();

        IERC20(compounder).safeTransfer(_receiver, _rewards);
        
        emit Claim(_receiver, _rewards);
    }

    function _isUnderlyingAsset(address _asset) internal view returns (bool) {
        address[] memory _underlyingAssets = underlyingAssets;

        for (uint256 i = 0; i < _underlyingAssets.length; i++) {
            if (_underlyingAssets[i] == _asset) {
                return true;
            }
        }
        return false;
    }

    function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal virtual returns (uint256 _assets) {}

    function _swapToUnderlying(address _underlyingAsset, uint256 _amount, uint256 _minAmount) internal virtual returns (uint256) {}

    function _harvest(address _receiver, uint256 _minBounty) internal virtual returns (uint256) {}

    /********************************** Events **********************************/

    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);
    event Harvest(address indexed _harvester, address indexed _receiver, uint256 _rewards, uint256 _platformFee);
    event Claim(address indexed _receiver, uint256 _rewards);
    event UpdateFees(uint256 _withdrawFeePercentage, uint256 _platformFeePercentage, uint256 _harvestBountyPercentage);
    event UpdateExternalUtils(address[] _rewardAssets, address _booster, address _crvRewards);
    event UpdateInternalUtils(address compounder, address _platform, address _swap, address _owner);
    event PauseInteractions(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseClaim);
    
    /********************************** Errors **********************************/

    error Unauthorized();
    error NotUnderlyingAsset();
    error DepositPaused();
    error WithdrawPaused();
    error ClaimPaused();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error NoPendingRewards();
    error InvalidAmount();
    error InvalidAsset();
    error InsufficientAmountOut();
    error FailedToSendETH();
    error HarvestAlreadyCalled();
}