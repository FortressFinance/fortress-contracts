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

// //  _____                 _____ _   _   _____                     _           _           
// // |     |_ _ ___ _ _ ___|   __| |_| |_|     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// // |   --| | |  _| | | -_|   __|  _|   |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// // |_____|___|_|  \_/|___|_____|_| |_|_|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  

// // Github - https://github.com/FortressFinance

// import "src/shared/concentrators/AMMConcentratorBase.sol";
// import "src/mainnet/utils/CurveOperations.sol";
contract CurveEthConcentrator {}
// contract CurveEthConcentrator is CurveOperations, AMMConcentratorBase {

//     using SafeERC20 for IERC20;

//     /// @notice The address of the underlying Curve pool.
//     address private immutable poolAddress;
//     /// @notice The type of the pool, used in CurveOperations.
//     uint256 private immutable poolType;
//     /// @notice The address of Curve frxETH/ETH LP token.
//     address private constant FRXETHCRV = 0xf43211935C781D5ca1a41d2041F397B8A7366C7A;
//     /// @notice The address of frxETH/ETH pool.
//     address constant FRXETHETH = 0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577;
    
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
//         address _compounder,
//         uint256 _poolType
//         )
//         AMMConcentratorBase(
//             _asset,
//             _name,
//             _symbol,
//             _description,
//             _owner,
//             _platform,
//             _swap,
//             address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Booster
//             IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31).poolInfo(_boosterPoolId).crvRewards,
//             _boosterPoolId,
//             _rewardAssets,
//             _underlyingAssets,
//             _compounder
//         ) {
//             IERC20(FRXETHCRV).safeApprove(_compounder, type(uint256).max);

//             poolType = _poolType;
//             poolAddress = metaRegistry.get_pool_from_lp_token(address(_asset));
//         }

//     /********************************** Internal Functions **********************************/

//     function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal override returns (uint256 _assets) {
//         _assets = _addLiquidity(poolAddress, poolType, _underlyingAsset, _underlyingAmount);
//         if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
//     }

//     function _swapToUnderlying(address _underlyingAsset, uint256 _assets, uint256 _minAmount) internal override returns (uint256 _underlyingAmount) {
//         _underlyingAmount = _removeLiquidity(poolAddress, poolType, _underlyingAsset, _assets);
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
//             _rewards = _addLiquidity(FRXETHETH, 5, _eth, _rewards);

//             Fees memory _fees = fees;
//             address _lpToken = FRXETHCRV;
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