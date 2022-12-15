// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

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

//  _____             _____     _ _____                     _           _           
// |  _  |_ _ ___ ___| __  |___| |     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// |     | | |  _| .'| __ -| .'| |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// |__|__|___|_| |__,|_____|__,|_|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  

// Github - https://github.com/FortressFinance

import "src/mainnet/concentrators/AMMConcentratorBase.sol";
import "src/mainnet/utils/BalancerOperations.sol";

contract AuraBalConcentrator is BalancerOperations, AMMConcentratorBase {

    using SafeERC20 for IERC20;

    /// @notice The address of BAL token.
    address private constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    /// @notice The address of auraBAL token.
    address private constant AURABAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
    /// @notice The address of ETH/BAL pool.
    address private constant BALANCER_WETHBAL = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    
    /********************************** Constructor **********************************/

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _owner,
        address _platform,
        address _swap,
        uint256 _boosterPoolId,
        address[] memory _rewardAssets,
        address[] memory _underlyingAssets,
        address _compounder
        )
        AMMConcentratorBase(
            _asset,
            _name,
            _symbol,
            _owner,
            _platform,
            _swap,
            address(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234), // Aura Booster
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets,
            _compounder
        ) {
            IERC20(BALANCER_WETHBAL).safeApprove(_swap, type(uint256).max);
            IERC20(AURABAL).safeApprove(_compounder, type(uint256).max);
        }

    /********************************** Mutated Functions **********************************/

    /// @notice See {AMMConcentratorBase - depositSingleUnderlying}
    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable override nonReentrant returns (uint256 _shares) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (!(_underlyingAmount > 0)) revert ZeroAmount();

        _updateRewards(msg.sender);

        if (msg.value > 0) {
            if (msg.value != _underlyingAmount) revert InvalidAmount();
            if (_underlyingAsset != ETH) revert InvalidAsset();
        } else {
            IERC20(_underlyingAsset).safeTransferFrom(msg.sender, address(this), _underlyingAmount);
        }

        uint256 _assets = _addLiquidity(address(asset), _underlyingAsset, _underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);

        _afterDeposit(_assets, false);

        return _shares;
    }

    /// @notice See {AMMConcentratorBase - redeemSingleUnderlying}
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) public override nonReentrant returns (uint256 _underlyingAmount) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();
        
        _updateRewards(_owner);

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        _afterWithdraw(_assets, _receiver, false);

        _underlyingAmount = _removeLiquidity(address(asset), _underlyingAsset, _assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();

        if (_underlyingAsset == ETH) {
            (bool sent,) = msg.sender.call{value: _underlyingAmount}("");
            if (!sent) revert FailedToSendETH();
        } else {
            IERC20(_underlyingAsset).safeTransfer(msg.sender, _underlyingAmount);
        }

        return _underlyingAmount;
    }

    /********************************** Internal Functions **********************************/

    function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IConvexBasicRewards(crvRewards).getReward();

        address _bal = BAL;
        address _token;
        address _swap = swap;
        address[] memory _rewardAssets = rewardAssets;
        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            _token = _rewardAssets[i];
            if (_token != _bal) {
                if (_token == ETH && address(this).balance > 0) {
                    IFortressSwap(_swap).swap{ value: address(this).balance }(ETH, _bal, address(this).balance);
                } else {
                    uint256 _balance = IERC20(_token).balanceOf(address(this));
                    if (_balance > 0) {
                        IFortressSwap(_swap).swap(_token, _bal, _balance);
                    }
                }
            }
        }
        
        address _aurabal = AURABAL;
        _rewards = IERC20(_bal).balanceOf(address(this));
        if (_rewards > 0) {
            _rewards = _swapBALToAuraBAL(_rewards);
        
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(_aurabal).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

                _rewards = _rewards - _harvestBounty;
                IERC20(_aurabal).safeTransfer(_receiver, _harvestBounty);
            }

            _rewards = ERC4626(compounder).deposit(_rewards, address(this));

            accRewardPerShare = accRewardPerShare + ((_rewards * PRECISION) / totalSupply);
            
            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    /// @dev Swap BAL to auraBAL.
    /// @param _amount - The amount of BAL to swap.
    /// @return - The amount of auraBAL in return.
    function _swapBALToAuraBAL(uint256 _amount) internal returns (uint256) {
        address _balancerWETHBAL = BALANCER_WETHBAL;
        
        _amount = _addLiquidity(_balancerWETHBAL, BAL, _amount);
        
        return IFortressSwap(swap).swap(_balancerWETHBAL, AURABAL, _amount);
    }

    receive() external payable {}
}