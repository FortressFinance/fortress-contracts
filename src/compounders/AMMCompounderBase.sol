// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "src/interfaces/ERC4626.sol";
import "src/interfaces/IConvexBasicRewards.sol";
import "src/interfaces/IConvexBooster.sol";
import "src/fortress-interfaces/IFortressSwap.sol";

abstract contract AMMCompounderBase is ReentrancyGuard, ERC4626 {
  
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    struct PoolInfo {
        /// @notice The pool ID in the Booster contract.
        uint256 boosterPoolId;
        /// @notice The percentage of fee to pay for the platform on harvest.
        uint256 platformFeePercentage;
        /// @notice The percentage of fee to pay for the caller on harvest.
        uint256 harvestBountyPercentage;
        /// @notice The percentage of fee to keep in the vault on withdraw.
        uint256 withdrawFeePercentage;
        /// @notice The address of the Booster contract.
        address booster;
        /// @notice The address of the staking rewards contract.
        address crvRewards;
        /// @notice Whether deposit for the pool is paused.
        bool pauseDeposit;
        /// @notice Whether withdraw for the pool is paused.
        bool pauseWithdraw;
        /// @notice The list of addresses of booster reward assets.
        address[] rewardAssets;
        /// @notice The list the pool's underlying assets.
        address[] underlyingAssets;
    }

    /// @notice The storage of pool info.
    PoolInfo public poolInfo;

    /// @notice The address of the owner.
    address public owner;
    /// @notice The address of the recipient of platform fee.
    address public platform;
    /// @notice The address of FortressSwap contract, will be used to swap tokens.
    address public swap;
    /// @notice The fee denominator.
    uint256 internal constant FEE_DENOMINATOR = 1e9;
    
    /********************************** Constructor **********************************/

    constructor(
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            address _platform,
            address _swap,
            address _booster,
            uint256 _boosterPoolId,
            address[] memory _rewardAssets,
            address[] memory _underlyingAssets
        )
        ERC4626(_asset, _name, _symbol) {
        
        poolInfo = PoolInfo({
            boosterPoolId: _boosterPoolId,
            platformFeePercentage: 50000000, // 5%,
            harvestBountyPercentage: 25000000, // 2.5%,
            withdrawFeePercentage: 2000000, // 0.2%,
            booster: _booster,
            crvRewards: IConvexBooster(_booster).poolInfo(_boosterPoolId).crvRewards,
            pauseDeposit: false,
            pauseWithdraw: false,
            rewardAssets: _rewardAssets,
            underlyingAssets: _underlyingAssets
        });

        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            IERC20(_rewardAssets[i]).safeApprove(_swap, type(uint256).max);
        }

        IERC20(address(_asset)).safeApprove(_booster, type(uint256).max);

        owner = msg.sender;
        platform = _platform;
        swap = _swap;
    }

    /********************************** View Functions **********************************/

    /// @dev Get the list of addresses of the vault's underlying assets (the assets that comprise the LP token, which is the vault primary asset).
    /// @return - The list of address of the underlying assets.
    function getUnderlyingAssets() external view returns (address[] memory) {
        return poolInfo.underlyingAssets;
    }

    /// @dev Indicates whether there are pending rewards to harvest.
    /// @return - True if there are pending rewards, false if otherwise.
    function isPendingRewards() public view returns (bool) {
        return IConvexBasicRewards(poolInfo.crvRewards).earned(address(this)) > 0;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param _shares - The amount of _shares to redeem.
    /// @return - The amount of _assets in return, including a withdrawal fee.
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        uint256 _assets = convertToAssets(_shares); 
        return _assets - ((_assets * poolInfo.withdrawFeePercentage) / FEE_DENOMINATOR);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param _assets - The amount of _assets to withdraw.
    /// @return - The amount of shares to burn, including a withdrawal fee.
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        return convertToShares(_assets + ((_assets * poolInfo.withdrawFeePercentage) / FEE_DENOMINATOR));
    }

    /// @dev Returns the total amount of the assets that are managed by the vault.
    /// @return - The total amount of managed assets.
    function totalAssets() public view override returns (uint256) {
        return IConvexBasicRewards(poolInfo.crvRewards).balanceOf(address(this));
    }

    /// @dev Checks if a specific asset is an underlying asset of the vault's asset (which is an LP token).
    /// @param _asset - The address of the asset to check.
    /// @return - Whether the _assets is an underlying asset.
    function _isUnderlyingAsset(address _asset) internal view returns (bool) {
        address[] memory _underlyingAssets = poolInfo.underlyingAssets;

        for (uint256 i = 0; i < _underlyingAssets.length; i++) {
            if (_underlyingAssets[i] == _asset) {
                return true;
            }
        }
        return false;
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Mints vault shares to _receiver by depositing exact amount of assets.
    /// @param _assets - The amount of assets to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @return _shares - The amount of shares minted.
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);
        
        return _shares;
    }

    /// @dev Mints exact vault shares to _receiver by depositing assets.
    /// @param _shares - The amount of shares to mint.
    /// @param _receiver - The address of the receiver of shares.
    /// @return _assets - The amount of assets deposited.
    // slither-disable-next-line reentrancy-no-eth
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        _assets = previewMint(_shares);
        
        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);

        _deposit(msg.sender, _receiver, _assets, _shares);
        
        return _assets;
    }

    /// @dev Burns shares from owner and sends exact amount of assets to _receiver.
    /// @param _assets - The amount of assets to receive.
    /// @param _receiver - The address of the receiver of assets.
    /// @param _owner - The owner of shares.
    /// @return _shares - The amount of shares burned.
    function withdraw(uint256 _assets, address _receiver, address _owner) external override returns (uint256 _shares) {
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _shares = previewWithdraw(_assets);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _shares;
    }

    /// @dev Burns exact amount of shares from owner and sends assets to _receiver.
    /// @param _shares - The amount of shares to burn.
    /// @param _receiver - The address of the receiver of assets.
    /// @param _owner - The owner of shares.
    /// @return _assets - The amount of assets sent to the _receiver.
    function redeem(uint256 _shares, address _receiver, address _owner) external override returns (uint256 _assets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _assets;
    }

    /// @dev Mints vault shares to _receiver by depositing exact amount of underlying assets.
    /// @param _underlyingAmount - The amount of underlying assets to deposit.
    /// @param _underlyingAsset - The address of underlying asset to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @param _minAmount - The minimum amount of assets (LP tokens) to receive.
    /// @return _shares - The amount of shares minted.
    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable virtual nonReentrant returns (uint256 _shares) {}

    /// @dev Burns exact amount of shares from the owner and sends underlying assets to _receiver.
    /// @param _shares - The amount of shares to burn.
    /// @param _underlyingAsset - The address of underlying asset to redeem shares for.
    /// @param _receiver - The address of the receiver of underlying assets.
    /// @param _owner - The owner of _shares.
    /// @param _minAmount - The minimum amount of underlying assets to receive.
    /// @return _underlyingAmount - The amount of underlying assets sent to the _receiver.
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) external virtual nonReentrant returns (uint256 _underlyingAmount) {}

    /// @dev Harvests the pending rewards and converts to assets, then re-stakes the assets.
    /// @param _receiver - The address of receiver of harvest bounty.
    /// @param _underlyingAsset - The address of underlying asset to convert rewards to, which will then be deposited in the underlying pool, in return for assets (LP tokens). 
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get.
    /// @return _rewards - The amount of rewards that were deposited back into the vault, denominated in the vault asset.
    function harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        
        return _harvest(_receiver, _underlyingAsset, _minBounty);
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Updates the withdraw fee percentage.
    /// @param _feePercentage - The new withdrawal fee percentage.
    function updateWithdrawFeePercentage(uint256 _feePercentage) external {
        if (msg.sender != owner) revert Unauthorized();

        poolInfo.withdrawFeePercentage = _feePercentage;

        emit UpdateWithdrawalFeePercentage(_feePercentage);
    }

    /// @dev Updates the platform fee percentage.
    /// @param _feePercentage - The new platform fee percentage.
    function updatePlatformFeePercentage(uint256 _feePercentage) external {
        if (msg.sender != owner) revert Unauthorized();

        poolInfo.platformFeePercentage = _feePercentage;

        emit UpdatePlatformFeePercentage(_feePercentage);
    }

    /// @dev Updates the harvest bounty percentage.
    /// @param _feePercentage - The new fee percentage.
    function updateHarvestBountyPercentage(uint256 _feePercentage) external {
        if (msg.sender != owner) revert Unauthorized();

        poolInfo.harvestBountyPercentage = _feePercentage;

        emit UpdateHarvestBountyPercentage(_feePercentage);
    }

    /// @dev updates the reward assets.
    /// @param _rewardAssets - The new address list of reward assets.
    function updatePoolRewardAssets(address[] memory _rewardAssets) external {
        if (msg.sender != owner) revert Unauthorized();

        PoolInfo storage _poolInfo = poolInfo;

        delete _poolInfo.rewardAssets;
        _poolInfo.rewardAssets = _rewardAssets;

        emit UpdatePoolRewardAssets(_rewardAssets);
    }

    /// @dev Updates the recipient of platform fee.
    /// @param _platform - The new platform address.
    function updatePlatform(address _platform) external {
        if (msg.sender != owner) revert Unauthorized();

        platform = _platform;

        emit UpdatePlatform(_platform);
    }

    /// @dev Updates the address of FortressSwap contract.
    /// @param _swap - The new swap address.
    function updateSwap(address _swap) external {
        if (msg.sender != owner) revert Unauthorized();

        swap = _swap;

        emit UpdateSwap(_swap);
    }

    /// @dev Updates the owner of the contract.
    /// @param _owner - The address of the new owner.
    function updateOwner(address _owner) external {
        if (msg.sender != owner) revert Unauthorized();

        owner = _owner;
        
        emit UpdateOwner(_owner);
    }

    /// @dev Pauses withdrawals for the vault.
    /// @param _pause - The new status.
    function pausePoolWithdraw(bool _pause) external {
        if (msg.sender != owner) revert Unauthorized();

        PoolInfo storage _poolInfo = poolInfo;

        _poolInfo.pauseWithdraw = _pause;

        emit PausePoolWithdraw(_pause);
    }

    /// @dev Pauses deposits for the vault.
    /// @param _pause - The new status.
    function pausePoolDeposit(bool _pause) external {
        if (msg.sender != owner) revert Unauthorized();

        PoolInfo storage _poolInfo = poolInfo;
        
        _poolInfo.pauseDeposit = _pause;

        emit PausePoolDeposit(_pause);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        PoolInfo memory _poolInfo = poolInfo;

        if (_poolInfo.pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _mint(_receiver, _shares);

        IConvexBooster(_poolInfo.booster).deposit(_poolInfo.boosterPoolId, _assets, true);

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {
        PoolInfo memory _poolInfo = poolInfo;

        if (_poolInfo.pauseWithdraw) revert WithdrawPaused();
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
        
        if (totalSupply == 0) {
            _assets = totalAssets();
        }

        IConvexBasicRewards(_poolInfo.crvRewards).withdrawAndUnwrap(_assets, false);
        
        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minimumOut) internal virtual returns (uint256) {}

    /********************************** Events **********************************/

    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);
    event Harvest(address indexed _harvester, address indexed _receiver, uint256 _rewards, uint256 _platformFee);
    event UpdatePlatformFeePercentage(uint256 _feePercentage);
    event UpdateHarvestBountyPercentage(uint256 _percentage);
    event UpdateWithdrawalFeePercentage(uint256 _feePercentage);
    event UpdatePoolRewardAssets(address[] indexed _rewardAssets);
    event UpdatePlatform(address indexed _platform);
    event UpdateSwap(address indexed _swap);
    event UpdateOwner(address indexed _owner);
    event PausePoolDeposit(bool _pause);
    event PausePoolWithdraw(bool _pause);
    
    /********************************** Errors **********************************/

    error Unauthorized();
    error NotUnderlyingAsset();
    error DepositPaused();
    error WithdrawPaused();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error NoPendingRewards();
    error InvalidAmount();
    error InvalidAsset();
    error InsufficientAmountOut();
    error FailedToSendETH();
}