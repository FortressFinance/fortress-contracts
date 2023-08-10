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
import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {IFortressSwap} from "src/shared/fortress-interfaces/IFortressSwap.sol";
import {ERC4626, ERC20, FixedPointMathLib} from "src/shared/interfaces/ERC4626.sol";

interface ISTYCRV {
    function deposit(uint256 amount, address recipient) external returns(uint256);
    function withdraw(uint256 shares) external returns(uint256);
    function pricePerShare() external view returns(uint256);
}
interface IYCRV {
    function mint(uint256 amount) external returns(uint256);
}

contract CrvUsdConcentrator is ReentrancyGuard, ERC4626  {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address constant STYCRV = 0x27B5739e22ad9033bcBf192059122d163b60349D;
    address constant YCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E; 

    struct Fees {
        /// @notice The percentage of fee to pay for platform on harvest
        uint256 platformFeePercentage;
        /// @notice The percentage of fee to pay for caller on harvest
        uint256 harvestBountyPercentage;
        /// @notice The fee percentage to take on withdrawal. Fee stays in the vault, and is therefore distributed to vault participants. Used as a mechanism to protect against mercenary capital
        uint256 withdrawFeePercentage;
    }

    struct Settings {
        /// @notice The description of the vault
        string description;
        /// @notice The internal accounting of the deposit limit. Denominated in shares
        uint256 depositCap;
        /// @notice The address of the platform
        address platform;
        /// @notice The address of the FortressSwap contract
        address swap;
        /// @notice The address of the owner
        address owner;
        /// @notice Whether deposit for the pool is paused
        bool pauseDeposit;
        /// @notice Whether withdraw for the pool is paused
        bool pauseWithdraw;
        /// @notice Whether claim from vault is paused
        bool pauseClaim;
    }

    struct UserInfo {
        /// @notice The amount of current accrued rewards
        uint256 rewards;
        /// @notice The reward per share already paid for the user, with 1e18 precision
        uint256 rewardPerSharePaid;
        /// @notice The balance of CRV
        uint256 crvDepositedBalance;
    }

    /// @notice The fees settings
    Fees public fees;

    /// @notice The list the pool's underlying assets
    address[] public underlyingAssets;

    /// @notice The mapping of whitelisted feeless redeemers
    mapping(address => bool) public feelessRedeemerWhitelist;

    /// @notice The vault settings
    Settings public settings;

    /// @notice Mapping from account address to user info
    mapping(address => UserInfo) public userInfo;

    /// @notice The address of the contract that can specify an owner when calling the claim function 
    address public multiClaimer;

    /// @notice The accumulated reward per share, with 1e18 precision
    uint256 public accRewardPerShare;
    /// @notice The last block number that the harvest function was executed
    uint256 public lastHarvestBlock;
    /// @notice The internal accounting of AUM
    uint256 public totalAUM;
    /// @notice The internal accounting of CRV
    uint256 public totalCRV;

    /// @notice The precision
    uint256 internal constant PRECISION = 1e18;
    /// @notice The fee denominator
    uint256 internal constant FEE_DENOMINATOR = 1e9;
    /// @notice The maximum withdrawal fee
    uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%
    /// @notice The maximum platform fee
    uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%
    /// @notice The maximum harvest fee
    uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%
    
    /********************************** Constructor **********************************/
    
    constructor(
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            bytes memory _settingsConfig,
            address[] memory _underlyingAssets
        )
        ERC4626(_asset, _name, _symbol) {

            {
                Fees storage _fees = fees;
                _fees.platformFeePercentage = 50000000; // 5%
                _fees.harvestBountyPercentage = 25000000; // 2.5%
                _fees.withdrawFeePercentage = 2000000; // 0.2%
            }

            {
                Settings storage _settings = settings;

                (_settings.description, _settings.owner, _settings.platform, _settings.swap)
                = abi.decode(_settingsConfig, (string, address, address, address));

                _settings.depositCap = 0;
                _settings.pauseDeposit = false;
                _settings.pauseWithdraw = false;
                _settings.pauseClaim = false;
            }

            underlyingAssets = _underlyingAssets;
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
        return settings.description;
    }

    /// @dev Return the amount of pending rewards
    /// @param _account - The address of user
    /// @return - The amount of pending rewards
    function pendingReward(address _account) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[_account];
        
        return _userInfo.rewards + (((accRewardPerShare - _userInfo.rewardPerSharePaid) * balanceOf[_account]) / PRECISION);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions
    /// @param _shares - The amount of _shares to redeem
    /// @return - The amount of _assets in return, after subtracting a withdrawal fee
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        // Calculate assets based on a user's % ownership of vault shares
        uint256 assets = convertToAssets(_shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a fee - zero if user is the last to withdraw
        uint256 _fee = (_totalSupply == 0 || _totalSupply - _shares == 0) ? 0 : assets.mulDivDown(fees.withdrawFeePercentage, FEE_DENOMINATOR);

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
        return (_totalSupply == 0 || _totalSupply - _shares == 0) ? _shares : (_shares * FEE_DENOMINATOR) / (FEE_DENOMINATOR - fees.withdrawFeePercentage);
    }

    /// @dev Returns the total amount of the assets that are managed by the vault
    /// @return - The total amount of managed assets
    
    function totalAssets() public view override returns (uint256) {
        return totalAUM;
    }

    /// @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call
    function maxDeposit(address) public view override returns (uint256) {
        uint256 _assetCap = convertToAssets(settings.depositCap);
        return _assetCap == 0 ? type(uint256).max : _assetCap - totalAUM;
    }

    /// @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call
    function maxMint(address) public view override returns (uint256) {
        uint256 _depositCap = settings.depositCap;
        return _depositCap == 0 ? type(uint256).max : _depositCap - totalSupply;
    }
    
    /// @dev Get the list of addresses of the vault's underlying assets (the assets that comprise the LP token, which is the vault primary asset)
    /// @return - The underlying assets
    function getUnderlyingAssets() external view returns (address[] memory) {
        return underlyingAssets;
    }
    /********************************** Mutated Functions **********************************/

    /// @dev Harvest the pending rewards and convert to crvUSD
    /// @param _receiver - The address of account to receive harvest bounty
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get
    function harvest(address _receiver, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        if (block.number == lastHarvestBlock) revert HarvestAlreadyCalled();
        lastHarvestBlock = block.number;

        _rewards = _harvest(_receiver, _minBounty);
        accRewardPerShare = accRewardPerShare + ((_rewards * PRECISION) / totalSupply);

        return _rewards;
    }

    /// @dev Mints vault shares to _receiver by depositing exact amount of assets
    /// @param _assets - The amount of assets to deposit
    /// @param _receiver - The receiver of minted shares
    /// @return _shares - The amount of shares minted
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        if (_assets >= maxDeposit(msg.sender)) revert InsufficientDepositCap();

        _updateRewards(_receiver);

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);

        IERC20(STYCRV).safeTransferFrom(msg.sender, address(this), _assets);
        
        totalCRV += (_assets * ISTYCRV(STYCRV).pricePerShare()) / PRECISION;

        return _shares;
    }
    
    function depositUnderlying(address _underlyingAsset, address _receiver, uint256 _amount) external payable nonReentrant returns (uint256 _shares) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (!(_amount > 0)) revert ZeroAmount();
        
        _updateRewards(msg.sender);

        IERC20(_underlyingAsset).safeTransferFrom(msg.sender, address(this), _amount);
        
        uint256 _yCRVamount;
        if (_underlyingAsset == YCRV) {
            _yCRVamount = _amount;
        } else {
            _approve(CRV, YCRV, _amount);
            _yCRVamount = IYCRV(YCRV).mint(_amount);
        }

        _approve(YCRV, STYCRV, _yCRVamount);
        uint256 _assets = ISTYCRV(STYCRV).deposit(_yCRVamount, address(this)); 

        if (_assets >= maxDeposit(msg.sender)) revert InsufficientDepositCap();
        
        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);
        
        totalCRV += _amount;

        return _shares;
    }

    /// @dev Burns shares from owner and sends exact amount of assets to _receiver. If the _owner is whitelisted, no withdrawal fee is applied
    /// @param _assets - The amount of assets to receive
    /// @param _receiver - The address of the receiver of assets
    /// @param _owner - The owner of shares
    /// @return _shares - The amount of shares burned
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 _shares) {
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _updateRewards(_owner);

        // If the _owner is whitelisted, we can skip the preview and just convert the assets to shares
        _shares = feelessRedeemerWhitelist[_owner] ? convertToShares(_assets) : previewWithdraw(_assets);

        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        IERC20(STYCRV).safeTransfer(_receiver, _assets);

        totalCRV -= ((_assets * PRECISION)/ ISTYCRV(STYCRV).pricePerShare());

        return _shares;
    }

    /// @notice that this function is vulnerable to a sandwich/frontrunning attacke if called without asserting the returned value
    /// @notice If the _owner is whitelisted, no withdrawal fee is applied
    /// @dev Burns exact shares from owner and sends assets of unwrapped underlying tokens to _receiver
    /// @param _underlyingAsset - The address of underlying asset to redeem shares for
    /// @param _receiver - The address of the receiver of underlying assets
    /// @param _owner - The owner of _shares
    /// @param _shares - The amount of shares to burn
    /// @param _minAmount - The minimum amount of underlying assets to receive
    /// @return _underlyingAmount - The amount of underlying assets sent to the _receiver
    // slither-disable-next-line reentrancy-no-eth
    function redeemUnderlying(address _underlyingAsset, address _receiver, address _owner, uint256 _shares, uint256 _minAmount) public nonReentrant returns (uint256 _underlyingAmount) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();
        
        _updateRewards(msg.sender);

        uint256 _assets = feelessRedeemerWhitelist[_owner] ? convertToAssets(_shares) : previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        uint256 _yCrvAssets = ISTYCRV(STYCRV).withdraw(_assets); 

        if (_underlyingAsset == YCRV) {
            _underlyingAmount = _yCrvAssets;
        } else {
            _approve(YCRV, address(settings.swap), _yCrvAssets);
            _underlyingAmount = IFortressSwap(settings.swap).swap(YCRV, _underlyingAsset, _yCrvAssets);
        }

        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();

        IERC20(_underlyingAsset).safeTransfer(_receiver, _underlyingAmount);

        totalCRV = (totalCRV < _yCrvAssets) ? 0 : totalCRV - _yCrvAssets;

        return _underlyingAmount;
    }
    
    /// @dev Claims all rewards for _owner and sends them to _receiver
    /// @param _owner - The owner of rewards
    /// @param _receiver - The recipient of rewards
    /// @return _rewards - The amount of Compounder shares sent to the _receiver
    function claim(address _owner, address _receiver) public nonReentrant returns (uint256 _rewards) {
        if (settings.pauseClaim) revert ClaimPaused();
        
        if (msg.sender != multiClaimer) {
            _owner = msg.sender;
        }

        _updateRewards(_owner);

        UserInfo storage _userInfo = userInfo[_owner];
        _rewards = _userInfo.rewards;
        _userInfo.rewards = 0;

        _claim(_rewards, _receiver);

        return _rewards;
    }
    
    /// @dev Redeem to an underlying asset and claim rewards in a single transaction
    /// @param _underlyingAsset - The address of the underlying asset to redeem the shares to
    /// @param _receiver - The receiver of underlying assets and rewards
    /// @param _shares - The amount of shares to redeem
    /// @param _minAmount - The minimum amount of underlying assets to receive
    /// @return _underlyingAmount - The amount of underlying assets sent to _receiver
    /// @return _rewards - The amount of rewards sent to _receiver
    // slither-disable-next-line reentrancy-eth
    function redeemUnderlyingAndClaim(address _underlyingAsset, address _receiver, uint256 _shares, uint256 _minAmount) external returns (uint256 _underlyingAmount, uint256 _rewards) {
        _underlyingAmount = redeemUnderlying(_underlyingAsset, _receiver, msg.sender, _shares, _minAmount);
        _rewards = claim(address(0), _receiver);

        return (_underlyingAmount, _rewards);
    }

    // /// @dev Redeem shares and claim rewards in a single transaction
    // /// @param _shares - The amount of shares to redeem
    // /// @param _receiver - The receiver of assets and rewards
    // /// @return _assets - The amount of assets sent to _receiver
    // /// @return _rewards - The amount of rewards sent to _receiver
    // // slither-disable-next-line reentrancy-eth
    // function redeemAndClaim(uint256 _shares, address _receiver) external returns (uint256 _assets, uint256 _rewards) {
    //     _assets = redeem(_shares, _receiver, msg.sender);
    //     _rewards = claim(address(0), _receiver);

    //     return (_assets, _rewards);
    // }

    /********************************** Restricted Functions **********************************/
    /// @dev updates the vault internal utils
    /// @param _platform - The new platform address
    /// @param _swap - The new swap address
    /// @param _owner - The address of the new owner
    /// @param _depositCap - The new deposit cap
    /// @param _underlyingAssets - The new underlying assets
    function updateSettings(address _platform, address _swap, address _owner, uint256 _depositCap, address[] memory _underlyingAssets) external {
        Settings storage _settings = settings;

        if (msg.sender != _settings.owner) revert Unauthorized();

        _settings.platform = _platform;
        _settings.swap = _swap;
        _settings.owner = _owner;
        _settings.depositCap = _depositCap;

        underlyingAssets = _underlyingAssets;

        emit UpdateSettings(_platform, _swap, _owner, _depositCap, _underlyingAssets);
    }

    function updateMultiClaimer(address _multiClaimer) external {
        if (msg.sender != settings.owner) revert Unauthorized();

        multiClaimer = _multiClaimer;

        emit UpdateMultiClaimer(_multiClaimer);
    }

    /// @dev Pauses deposits/withdrawals for the vault
    /// @param _pauseDeposit - The new deposit status
    /// @param _pauseWithdraw - The new withdraw status
    /// @param _pauseWithdraw - The new claim status
    function pauseInteractions(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseClaim) external {
        Settings storage _settings = settings;

        if (msg.sender != _settings.owner) revert Unauthorized();

        _settings.pauseDeposit = _pauseDeposit;
        _settings.pauseWithdraw = _pauseWithdraw;
        _settings.pauseClaim = _pauseClaim;

        emit PauseInteractions(_pauseDeposit, _pauseWithdraw, _pauseClaim);
    }

    /********************************** Internal Functions **********************************/

    function _harvest(address _receiver, uint256 _minBounty) internal returns (uint256 _rewards) {

        uint256 _rate = ISTYCRV(STYCRV).pricePerShare();
        uint256 _crvBalanceSnapshot = (IERC20(STYCRV).balanceOf(address(this)) * _rate)/PRECISION;
        uint256 _accruedCRV = _crvBalanceSnapshot - totalCRV;
        if (_accruedCRV <=0) revert NoPendingRewards();
        _rewards = ISTYCRV(STYCRV).withdraw((_accruedCRV * PRECISION)/_rate); 

        Fees memory _fees = fees;
        uint256 _platformFee = _fees.platformFeePercentage;
        uint256 _harvestBounty = _fees.harvestBountyPercentage;
        if (_platformFee > 0) {
            _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
            _rewards = _rewards - _platformFee;
            IERC20(YCRV).safeTransfer(settings.platform, _platformFee);
        }
        if (_harvestBounty > 0) {
            _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
            if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

            _rewards = _rewards - _harvestBounty;
            IERC20(YCRV).safeTransfer(_receiver, _harvestBounty);
        }
        _approve(YCRV, address(settings.swap), _rewards);
        _rewards = IFortressSwap(settings.swap).swap(YCRV, CRVUSD, _rewards);

        totalAUM = IERC20(STYCRV).balanceOf(address(this));
        
        if ((IERC20(STYCRV).balanceOf(address(this)) * _rate) / PRECISION - totalCRV < 0) revert IncorrectHarvest();

        emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

        return _rewards;
    }

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (settings.pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _mint(_receiver, _shares);
        totalAUM += _assets;

        emit Deposit(_caller, _receiver, _assets, _shares);
    }


    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {
        if (settings.pauseWithdraw) revert WithdrawPaused();
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
    
    function _claim(uint256 _rewards, address _receiver) internal {
        if (!(_rewards > 0)) revert ZeroAmount();

        IERC20(CRVUSD).safeTransfer(_receiver, _rewards);
        
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
    
    function _updateRewards(address _account) internal {
        uint256 _rewards = pendingReward(_account);
        UserInfo storage _userInfo = userInfo[_account];

        _userInfo.rewards = _rewards;
        _userInfo.rewardPerSharePaid = accRewardPerShare;
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    receive() external payable {}

    /********************************** Events **********************************/

    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);
    event Harvest(address indexed _harvester, address indexed _receiver, uint256 _rewards, uint256 _platformFee);
    event Claim(address indexed _receiver, uint256 _rewards);
    event UpdateFees(uint256 _withdrawFeePercentage, uint256 _platformFeePercentage, uint256 _harvestBountyPercentage);
    event UpdateBoosterData(address _booster, address _crvRewards, uint256 _boosterPoolId);
    event UpdateRewardAssets(address[] _rewardAssets);
    event UpdateSettings(address _platform, address _swap, address _owner, uint256 _depositCap, address[] _underlyingAssets);
    event UpdateFeelessRedeemerWhitelist(address _address, bool _whitelist);
    event UpdateMultiClaimer(address _multiClaimer);
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
    error InsufficientDepositCap();
    error NoPendingRewards();
    error InvalidAmount();
    error InvalidAsset();
    error InsufficientAmountOut();
    error FailedToSendETH();
    error HarvestAlreadyCalled();
    error IncorrectHarvest();
}