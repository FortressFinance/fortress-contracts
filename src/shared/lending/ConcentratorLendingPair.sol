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

//  _____         _                   __              _ _         _____     _     
// |   __|___ ___| |_ ___ ___ ___ ___|  |   ___ ___ _| |_|___ ___|  _  |___|_|___ 
// |   __| . |  _|  _|  _| -_|_ -|_ -|  |__| -_|   | . | |   | . |   __| .'| |  _|
// |__|  |___|_| |_| |_| |___|___|___|_____|___|_|_|___|_|_|_|_  |__|  |__,|_|_|  todo
//                                                           |___|                

// Github - https://github.com/FortressFinance

import {IFortressConcentrator} from "./interfaces/IFortressConcentrator.sol";

import "./FortressLendingCore.sol";

/// @notice The child contract of FortressLendingCore that is deployed for each Concentrator pair.
contract ConcentratorLendingPair is FortressLendingCore {

    using SafeERC20 for IERC20;

    /// @notice Boolean to pause/unpause claiming of rewards
    bool public pauseClaim;

    /// @notice The address of the contract that can specify an owner when calling the claim function 
    address public multiClaimer;
    /// @notice The address of the reward asset which is claimed from the collateral contract (the Concentrator)
    address public rewardAsset;

    /// @notice The accumulated reward per collateral unit, with 1e18 precision
    uint256 public accRewardPerCollatUnit;
    /// @notice The last block number that the harvest function was executed
    uint256 public lastHarvestBlock;
    /// @notice The percentage of fee to pay for caller on harvest
    uint256 public harvestBountyPercentage;

    /// @notice The precision
    uint256 private constant PRECISION = 1e18;
    /// @notice The fee denominator
    uint256 private constant FEE_DENOMINATOR = 1e9;

    struct UserRewardsInfo {
        /// @notice The amount of current accrued rewards
        uint256 rewards;
        /// @notice The reward per collateral unit already paid for the borrower, with 1e18 precision
        uint256 rewardPerCollatUnitPaid;
    }
    /// @notice Mapping from account address to rewards user info
    mapping(address => UserRewardsInfo) public userRewardsInfo;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        bytes memory _configData,
        bytes memory _concentratorConfig,
        address _owner,
        address _swap,
        uint256 _maxLTV,
        uint256 _liquidationFee
    ) FortressLendingCore(_asset, _name, _symbol, _configData, _owner, _swap, _maxLTV, _liquidationFee) {
        (address _rewardsAsset, address _multiClaimer, bool _pauseClaim) = abi.decode(_concentratorConfig, (address, address, bool));
        rewardAsset = _rewardsAsset;
        multiClaimer = _multiClaimer;
        pauseClaim = _pauseClaim;

        harvestBountyPercentage = 25000000; // 2.5%
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    /// @notice Return the amount of pending rewards for a specific borrower
    /// @param _account - The address of borrower
    /// @return - The amount of pending rewards
    function pendingReward(address _account) public view returns (uint256) {
        UserRewardsInfo memory _userInfo = userRewardsInfo[_account];

        return _userInfo.rewards + (((accRewardPerCollatUnit - _userInfo.rewardPerCollatUnitPaid) * userCollateralBalance[_account]) / PRECISION);
    }

    // ============================================================================================
    // Functions: Borrowing
    // Visability: External
    // Description: Add a call to _updateReward() before each borrower external function
    // ============================================================================================

    /// @notice Same as parent function, but adds a call to _updateReward()
    function addCollateral(uint256 _collateralAmount, address _borrower) external override nonReentrant speedBump(_borrower) {
        if (pauseSettings.addCollateral) revert Paused();

        _updateRewards(_borrower);

        lastInteractionBlock[_borrower] = block.number;

        _addInterest();

        _addCollateral(msg.sender, _collateralAmount, _borrower);
    }

    /// @notice Same as parent function, but adds a call to _updateReward()
    function removeCollateral(
        uint256 _collateralAmount,
        address _receiver
    ) external override nonReentrant speedBump(msg.sender) isSolvent(msg.sender) {
        if (pauseSettings.removeCollateral) revert Paused();

        _updateRewards(msg.sender);

        lastInteractionBlock[msg.sender] = block.number;

        _addInterest();
        
        // Note: exchange rate is irrelevant when borrower has no debt shares
        if (userBorrowShares[msg.sender] > 0) _updateExchangeRate();
        
        _removeCollateral(_collateralAmount, _receiver, msg.sender);
    }

    /// @notice Same as parent function, but adds a call to _updateReward()
    function repayAsset(
        uint256 _shares,
        address _borrower
    ) external override nonReentrant speedBump(_borrower) returns (uint256 _amountToRepay) {
        if (pauseSettings.repayAsset) revert Paused();

        _updateRewards(_borrower);

        lastInteractionBlock[_borrower] = block.number;

        _addInterest();
        
        BorrowAccount memory _totalBorrow = totalBorrow;
        _amountToRepay = convertToAssets(_totalBorrow.amount, _totalBorrow.shares, _shares, true);
        
        _repayAsset(_totalBorrow, _amountToRepay, _shares, msg.sender, _borrower);
    }

    /// @notice Same as parent function, but adds a call to _updateReward()
    function leveragePosition(
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _minAmount,
        address _underlyingAsset
    ) external override nonReentrant speedBump(msg.sender) isSolvent(msg.sender) returns (uint256 _totalCollateralAdded) {
        if (ERC20(address(_underlyingAsset)).decimals() != ERC20(address(assetContract)).decimals()) revert InvalidUnderlyingAsset();
        if (pauseSettings.addLeverage) revert Paused();

        _updateRewards(msg.sender);

        lastInteractionBlock[msg.sender] = block.number;

        _addInterest();
        _updateExchangeRate();

        // Add initial collateral
        if (_initialCollateralAmount > 0) _addCollateral(msg.sender, _initialCollateralAmount, msg.sender);

        // Debit borrowers (msg.sender) account
        uint256 _borrowShares = _borrowAsset(_borrowAmount);

        uint256 _underlyingAmount;
        address _asset = address(assetContract);
        if (_asset != _underlyingAsset) {
            address _swap = address(swap);
            _approve(_asset, _swap, _borrowAmount);
            _underlyingAmount = IFortressSwap(_swap).swap(_asset, _underlyingAsset, _borrowAmount);
        } else {
            _underlyingAmount = _borrowAmount;
        }

        address _collateralContract = address(collateralContract);
        _approve(_underlyingAsset, _collateralContract, _underlyingAmount);
        uint256 _amountCollateralOut = IFortressVault(_collateralContract).depositUnderlying(_underlyingAsset, address(this), _underlyingAmount, 0);
        if (_amountCollateralOut < _minAmount) revert SlippageTooHigh(_amountCollateralOut, _minAmount);

        // address(this) as _sender means no transfer occurs as the pair has already received the collateral during swap
        _addCollateral(address(this), _amountCollateralOut, msg.sender);
        
        emit LeveragedPosition(msg.sender, _borrowAmount, _borrowShares, _initialCollateralAmount, _amountCollateralOut);

        return _initialCollateralAmount + _amountCollateralOut;
    }

    /// @notice Same as parent function, but adds a call to _updateReward()
    function repayAssetWithCollateral(
        uint256 _collateralToSwap,
        uint256 _minAmount,
        address _underlyingAsset
    ) external override nonReentrant speedBump(msg.sender) isSolvent(msg.sender) returns (uint256 _amountAssetOut) {
        if (ERC20(address(_underlyingAsset)).decimals() != ERC20(address(assetContract)).decimals()) revert InvalidUnderlyingAsset();
        if (pauseSettings.removeLeverage) revert Paused();

        _updateRewards(msg.sender);

        lastInteractionBlock[msg.sender] = block.number;

        _addInterest();
        _updateExchangeRate();

        // Note: Debit users collateral balance in preparation for swap, setting _recipient to address(this) means no transfer occurs
        _removeCollateral(_collateralToSwap, address(this), msg.sender);
        _amountAssetOut = IFortressVault(address(collateralContract)).redeemUnderlying(_underlyingAsset, address(this), address(this), _collateralToSwap, 0);
        
        address _asset = address(assetContract);

        if (_underlyingAsset != _asset) {
            _approve(_underlyingAsset, swap, _amountAssetOut);
            _amountAssetOut = IFortressSwap(swap).swap(_underlyingAsset, _asset, _amountAssetOut);
        }

        if (_amountAssetOut < _minAmount) revert SlippageTooHigh(_amountAssetOut, _minAmount);

        BorrowAccount memory _totalBorrow = totalBorrow;
        uint256 _sharesToRepay = convertToShares(_totalBorrow.amount, _totalBorrow.shares, _amountAssetOut, false);

        // Note: Setting _payer to address(this) means no actual transfer will occur.  Contract already has funds
        _repayAsset(_totalBorrow, _amountAssetOut, _sharesToRepay, address(this), msg.sender);

        emit RepayAssetWithCollateral(msg.sender, _collateralToSwap, _amountAssetOut, _sharesToRepay);
    }

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    /// @notice Claims all rewards for _owner and sends them to _receiver
    /// @param _owner - The owner of rewards
    /// @param _receiver - The recipient of rewards
    /// @return _rewards - The amount of Compounder shares sent to the _receiver
    function claim(address _owner, address _receiver) external nonReentrant returns (uint256 _rewards) {
        if (pauseClaim) revert ClaimPaused();
        
        if (msg.sender != multiClaimer) {
            _owner = msg.sender;
        }

        _updateRewards(_owner);

        UserRewardsInfo storage _userInfo = userRewardsInfo[_owner];
        _rewards = _userInfo.rewards;
        _userInfo.rewards = 0;

        _claim(_rewards, _receiver);

        return _rewards;
    }

    /// @notice Harvests the pending rewards and converts to assets, then re-stakes the assets
    /// @param _receiver - The address of receiver of harvest bounty
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get
    /// @return _rewards - The amount of rewards that were deposited back into the vault, denominated in the vault asset
    function harvest(address _receiver, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        if (block.number == lastHarvestBlock) revert HarvestAlreadyCalled();
        lastHarvestBlock = block.number;

        _rewards = _harvest(_receiver, _minBounty);
        accRewardPerCollatUnit += ((_rewards * PRECISION) / totalCollateral);

        return _rewards;
    }

    // ============================================================================================
    // Owner Functions
    // ============================================================================================

    /// @notice Updates the concentrator config
    /// @param _harvestBountyPercentage - The percentage of fee to pay for caller on harvest
    /// @param _multiClaimer - The address of the new multiClaimer
    /// @param _pauseClaim - The boolean to pause/unpause claiming of rewards
    function updateConcentratorConfig(uint256 _harvestBountyPercentage, address _multiClaimer, bool _pauseClaim) external onlyOwner {
        harvestBountyPercentage = _harvestBountyPercentage;
        multiClaimer = _multiClaimer;
        pauseClaim = _pauseClaim;

        emit UpdateConcentratorConfig(_multiClaimer, _pauseClaim);
    }

    // ============================================================================================
    // Internal Functions
    // ============================================================================================

    function _updateRewards(address _account) internal {
        uint256 _rewards = pendingReward(_account);
        UserRewardsInfo storage _userInfo = userRewardsInfo[_account];

        _userInfo.rewards = _rewards;
        _userInfo.rewardPerCollatUnitPaid = accRewardPerCollatUnit;
    }

    function _claim(uint256 _rewards, address _receiver) internal {
        if (!(_rewards > 0)) revert ZeroAmount();

        IERC20(rewardAsset).safeTransfer(_receiver, _rewards);
        
        emit Claim(_receiver, _rewards);
    }

    function _harvest(address _receiver, uint256 _minBounty) internal returns (uint256 _rewards) {
        address _asset = rewardAsset;
        uint256 _before = IERC20(_asset).balanceOf(address(this));
        IFortressConcentrator(address(collateralContract)).claim(address(this), address(this));
        _rewards = IERC20(_asset).balanceOf(address(this)) - _before;

        if (_rewards > 0) {
            uint256 _harvestBounty = (harvestBountyPercentage * _rewards) / FEE_DENOMINATOR;
            if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

            _rewards -= _harvestBounty;
            IERC20(_asset).safeTransfer(_receiver, _harvestBounty);
        }
    }

    // ============================================================================================
    // Events
    // ============================================================================================

    event Claim(address indexed _receiver, uint256 _rewards);
    event UpdateConcentratorConfig(address indexed _multiClaimer, bool _pauseClaim);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error InsufficientAmountOut();
    error ClaimPaused();
    error HarvestAlreadyCalled();
}