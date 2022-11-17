// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "src/interfaces/ERC4626.sol";
import "src/fortress-interfaces/IFortressSwap.sol";

abstract contract TokenCompounderBase is ReentrancyGuard, ERC4626 {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /// @notice Whether deposit for the pool is paused.
    bool public pauseDeposit = false;
    /// @notice Whether withdraw for the pool is paused.
    bool public pauseWithdraw = false;
    /// @notice The percentage of token to take on withdraw.
    uint256 public withdrawFeePercentage;
    /// @notice The percentage of rewards to take for platform on harvest.
    uint256 public platformFeePercentage;
    /// @notice The percentage of rewards to take for caller on harvest.
    uint256 public harvestBountyPercentage;
    /// @notice The address of the owner.
    address public owner;
    /// @notice The address of recipient of platform fee.
    address public platform;
    /// @notice The address of swap contract, will be used to swap tokens.
    address public swap;
    /// @notice The fee denominator.
    uint256 internal constant FEE_DENOMINATOR = 1e9;

    /********************************** Constructor **********************************/

    constructor(
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            address _platform,
            address _swap
        )
        ERC4626(_asset, _name, _symbol) {
        
        platformFeePercentage = 50000000; // 5%,
        harvestBountyPercentage = 25000000; // 2.5%,
        withdrawFeePercentage = 2000000; // 0.2%,
        owner = msg.sender;
        platform = _platform;
        swap = _swap;
    }

    /********************************** View Functions **********************************/

    /// @dev Indicates whether there are pending rewards to harvest.
    /// @return - True if there's pending rewards, false if otherwise.
    function isPendingRewards() public view virtual returns (bool) {}

    /// @dev Returns the total amount of the assets that are managed by the vault.
    /// @return - The total amount of the managed assets.
    function totalAssets() public view virtual override returns (uint256) {}

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param _shares - The amount of _shares to redeem.
    /// @return - The amount of _assets in return, after subtracting a withdrawal fee.
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        uint256 _assets = convertToAssets(_shares); 
        return _assets - ((_assets * withdrawFeePercentage) / FEE_DENOMINATOR);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param _assets - The amount of _assets to withdraw.
    /// @return - The amount of shares to burn, after subtracting a fee.
    function previewWithdraw(uint256 _assets) public view virtual override returns (uint256) {
        return convertToShares(_assets + ((_assets * withdrawFeePercentage) / FEE_DENOMINATOR));
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Mints Vault shares to _receiver by depositing exact amount of underlying assets.
    /// @param _assets - The amount of assets to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @return _shares - The amount of shares minted.
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        
        _shares = previewDeposit(_assets);
        
        _deposit(msg.sender, _receiver, _assets, _shares);
        
        return _shares;
    }

    /// @dev Mints exact Vault shares to _receiver by depositing amount of underlying assets.
    /// @param _shares - The shares to receive.
    /// @param _receiver - The address of the receiver of shares.
    /// @return _assets - The amount of underlying assets received.
    // slither-disable-next-line reentrancy-no-eth
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        _assets = previewMint(_shares);
        
        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);

        _deposit(msg.sender, _receiver, _assets, _shares);
        
        return _assets;
    }

    /// @dev Burns shares from owner and sends exact assets of underlying assets to _receiver.
    /// @param _assets - The amount of underlying assets to receive.
    /// @param _receiver - The address of the receiver of underlying assets.
    /// @param _owner - The owner of shares.
    /// @return _shares - The amount of shares burned.
    function withdraw(uint256 _assets, address _receiver, address _owner) external override returns (uint256 _shares) { 
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _shares = previewWithdraw(_assets);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _shares;
    }

    /// @dev Burns exact shares from owner and sends assets of underlying tokens to _receiver.
    /// @param _shares - The shares to burn.
    /// @param _receiver - The address of the receiver of underlying assets.
    /// @param _owner - The owner of shares to burn.
    /// @return _assets - The amount of assets returned to the user.
    function redeem(uint256 _shares, address _receiver, address _owner) external override returns (uint256 _assets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _assets;
    }

    /// @dev Mints Vault shares to receiver by depositing exact amount of unwrapped underlying assets.
    /// @param _underlyingAmount - The amount of unwrapped underlying assets to deposit.
    /// @param _receiver - The receiver of minted shares.
    /// @param _minAmount - The minimum amount of asset to get for unwrapped asset.
    /// @return _shares - The amount of shares minted.
    function depositUnderlying(uint256 _underlyingAmount, address _receiver, uint256 _minAmount) external virtual nonReentrant returns (uint256 _shares) {}

    /// @notice that this function is vulnerable to a sandwich/frontrunning attacke if called without asserting the returned value.
    /// @dev Burns exact shares from owner and sends assets of unwrapped underlying tokens to _receiver.
    /// @param _shares - The shares to burn.
    /// @param _receiver - The address of the receiver of underlying assets.
    /// @param _owner - The owner of shares to burn.
    /// @return _assets - The amount of assets returned to the user.
    function redeemUnderlying(uint256 _shares, address _receiver, address _owner, uint256 _minAmount) external virtual nonReentrant returns (uint256 _assets) {}

    /// @dev Harvest the pending rewards and convert to underlying token, then stake.
    /// @param _recipient - The address of account to receive harvest bounty.
    /// @param _minBounty - The minimum amount of harvest bounty _recipient should get.
    function harvest(address _recipient, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        return _harvest(_recipient, _minBounty);
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Update the withdraw fee percentage.
    /// @param _feePercentage - The fee percentage to update.
    function updateWithdrawFeePercentage(uint256 _feePercentage) external {
        if (msg.sender != owner) revert Unauthorized();

        withdrawFeePercentage = _feePercentage;

        emit UpdateWithdrawalFeePercentage(_feePercentage);
    }

    /// @dev Update the platform fee percentage.
    /// @param _feePercentage - The fee percentage to update.
    function updatePlatformFeePercentage(uint256 _feePercentage) external {
        if (msg.sender != owner) revert Unauthorized();

        platformFeePercentage = _feePercentage;

        emit UpdatePlatformFeePercentage(_feePercentage);
    }

    /// @dev Update the harvest bounty percentage.
    /// @param _percentage - The fee percentage to update.
    function updateHarvestBountyPercentage(uint256 _percentage) external {
        if (msg.sender != owner) revert Unauthorized();

        harvestBountyPercentage = _percentage;

        emit UpdateHarvestBountyPercentage(_percentage);
    }

    /// @dev Update the recipient.
    /// @param _platform - The platform address to update.
    function updatePlatform(address _platform) external {
      if (msg.sender != owner) revert Unauthorized();

      platform = _platform;

      emit UpdatePlatform(_platform);
    }

    /// @dev Update the zap contract
    /// @param _swap - The swap address to update.
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

        pauseWithdraw = _pause;

        emit PausePoolWithdraw(_pause);
    }

    /// @dev Pauses deposits for the vault.
    /// @param _pause - The new status.
    function pausePoolDeposit(bool _pause) external {
        if (msg.sender != owner) revert Unauthorized();

        pauseDeposit = _pause;

        emit PausePoolDeposit(_pause);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _mint(_receiver, _shares);

        _costumDeposit(_assets);

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
        
        if (totalSupply == 0) {
            if (isPendingRewards()) {
                revert NoPendingRewards();
            }
            _assets = totalAssets();
        }

        _costumWithdraw(_assets);
        
        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _harvest(address _recipient, uint256 _minimumOut) internal virtual returns (uint256) {}

    function _costumDeposit(uint256 _assets) internal virtual {}

    function _costumWithdraw(uint256 _assets) internal virtual {}

    /********************************** Events **********************************/

    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);
    event Harvest(address indexed _harvester, uint256 _amount);
    event UpdatePlatformFeePercentage(uint256 _feePercentage);
    event UpdateHarvestBountyPercentage(uint256 _percentage);
    event UpdateWithdrawalFeePercentage(uint256 _feePercentage);
    event UpdatePlatform(address indexed _platform);
    event UpdateSwap(address indexed _swap);
    event UpdateOwner(address indexed _owner);
    event PausePoolDeposit(bool _pause);
    event PausePoolWithdraw(bool _pause);
    
    /********************************** Errors **********************************/

    error Unauthorized();
    error InsufficientBalance();
    error InsufficientAllowance();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientAmountOut();
    error DepositPaused();
    error WithdrawPaused();
    error NoPendingRewards();
}