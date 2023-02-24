// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// // ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// // ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// // █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// // ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// // ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// // ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// // ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// // ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// // █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// // ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// // ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// // ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝

// //  _____     _                     _____ _   _   _____                     _           _           
// // | __  |___| |___ ___ ___ ___ ___|   __| |_| |_|     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// // | __ -| .'| | .'|   |  _| -_|  _|   __|  _|   |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// // |_____|__,|_|__,|_|_|___|___|_| |_____|_| |_|_|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  

// // Github - https://github.com/FortressFinance

// import "src/shared/concentrators/AMMConcentratorBase.sol";
// import "src/mainnet/utils/BalancerOperations.sol";
contract BalancerEthConcentrator {}
// contract BalancerEthConcentrator is BalancerOperations, AMMConcentratorBase {

//     using SafeERC20 for IERC20;

//     /// @notice The address of wstETH token.
//     address private constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
//     /// @notice The address of sfrxETH/rETH/wstETH Balancer pool.
//     address private constant BALANCER_3ETH = 0x8e85e97ed19C0fa13B2549309965291fbbc0048b;
    
//     /********************************** Constructor **********************************/

//     constructor(
//         ERC20 _asset,
//         string memory _name,
//         string memory _symbol,
//         string memory _description,
//         address _owner,
//         address _platform,
//         address _swap,
//         uint256 _boosterPoolId,
//         address[] memory _rewardAssets,
//         address[] memory _underlyingAssets,
//         address _compounder
//         )
//         AMMConcentratorBase(
//             _asset,
//             _name,
//             _symbol,
//             _description,
//             _owner,
//             _platform,
//             _swap,
//             address(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234), // Aura Booster
//             IConvexBooster(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234).poolInfo(_boosterPoolId).crvRewards,
//             _boosterPoolId,
//             _rewardAssets,
//             _underlyingAssets,
//             _compounder
//         ) {
//             IERC20(WSTETH).safeApprove(_swap, type(uint256).max);
//             IERC20(BALANCER_3ETH).safeApprove(_compounder, type(uint256).max);
//         }

//     /********************************** Internal Functions **********************************/

//     function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal override returns (uint256 _assets) {
//         _assets = _addLiquidity(address(asset), _underlyingAsset, _underlyingAmount);
//         if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
//     }

//     function _swapToUnderlying(address _underlyingAsset, uint256 _assets, uint256 _minAmount) internal override returns (uint256 _underlyingAmount) {
//         _underlyingAmount = _removeLiquidity(address(asset), _underlyingAsset, _assets);
//         if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();
//     }

//     function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
//         Booster memory _boosterData = boosterData;

//         IConvexBasicRewards(_boosterData.crvRewards).getReward();

//         Settings memory _settings = settings;
//         address _eth = ETH;
//         address _token;
//         address _swap = _settings.swap;
//         address[] memory _rewardAssets = _boosterData.rewardAssets;
//         for (uint256 i = 0; i < _rewardAssets.length; i++) {
//             _token = _rewardAssets[i];
//             if (_token != _eth) {
//                 uint256 _balance = IERC20(_token).balanceOf(address(this));
//                 if (_balance > 0) {
//                     IFortressSwap(_swap).swap(_token, _eth, _balance);
//                 }
//             }
//         }
        
//         _rewards = address(this).balance;
//         if (_rewards > 0) {
//             address _wstETH = WSTETH;
//             address _lpToken = BALANCER_3ETH;

//             // slither-disable-next-line arbitrary-send-eth
//             _rewards = IFortressSwap(_swap).swap{value: _rewards}(_eth, _wstETH, _rewards);
//             _rewards = _addLiquidity(_lpToken, _wstETH, _rewards);
            
//             Fees memory _fees = fees;
//             uint256 _platformFee = _fees.platformFeePercentage;
//             uint256 _harvestBounty = _fees.harvestBountyPercentage;
//             if (_platformFee > 0) {
//                 _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
//                 _rewards = _rewards - _platformFee;
//                 IERC20(_lpToken).safeTransfer(_settings.platform, _platformFee);
//             }
//             if (_harvestBounty > 0) {
//                 _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
//                 if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

//                 _rewards = _rewards - _harvestBounty;
//                 IERC20(_lpToken).safeTransfer(_receiver, _harvestBounty);
//             }
            
//             _rewards = ERC4626(_settings.compounder).deposit(_rewards, address(this));

//             emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

//             return _rewards;
//         } else {
//             revert NoPendingRewards();
//         }
//     }

//     receive() external payable {}
// }