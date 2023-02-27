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

// //  _____         _____         _____                     _           _           
// // |     |_ _ _ _|     |___ _ _|     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// // |   --| | |_'_|   --|  _| | |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// // |_____|\_/|_,_|_____|_|  \_/|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  

// // Github - https://github.com/FortressFinance

// import "src/shared/concentrators/AMMConcentratorBase.sol";
// import "src/mainnet/utils/CurveOperations.sol";
contract CvxCrvConcentrator {}
// contract CvxCrvConcentrator is CurveOperations, AMMConcentratorBase {

//     using SafeERC20 for IERC20;

//     /// @notice The address of the underlying Curve pool.
//     address private immutable poolAddress;
//     /// @notice The type of the pool, used in CurveOperations.
//     uint256 private immutable poolType;
//     /// @notice The address of CRV token.
//     address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
//     /// @notice The address of cvxCRV token.
//     address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    
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
//             IERC20(CVXCRV).safeApprove(_compounder, type(uint256).max);

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
//         address _token;
//         address _swap = _settings.swap;
//         address _crv = CRV;
//         address[] memory _rewardAssets = _boosterData.rewardAssets;
//         for (uint256 i = 0; i < _rewardAssets.length; i++) {
//             _token = _rewardAssets[i];
//             if (_token != _crv) {
//                 if (_token == ETH && address(this).balance > 0) {
//                     IFortressSwap(_swap).swap{ value: address(this).balance }(ETH, _crv, address(this).balance);
//                 } else {
//                     uint256 _balance = IERC20(_token).balanceOf(address(this));
//                     if (_balance > 0) {
//                         IFortressSwap(_swap).swap(_token, _crv, _balance);
//                     }
//                 }
//             }
//         }
        
//         address _cvxcrv = CVXCRV;
//         _rewards = IERC20(_crv).balanceOf(address(this));
//         if (_rewards > 0) {
//             _rewards = IFortressSwap(_swap).swap(_crv, _cvxcrv, _rewards);

//             Fees memory _fees = fees;
//             uint256 _platformFee = _fees.platformFeePercentage;
//             uint256 _harvestBounty = _fees.harvestBountyPercentage;
//             if (_platformFee > 0) {
//                 _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
//                 _rewards = _rewards - _platformFee;
//                 IERC20(_cvxcrv).safeTransfer(_settings.platform, _platformFee);
//             }
//             if (_harvestBounty > 0) {
//                 _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
//                 if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

//                 _rewards = _rewards - _harvestBounty;
//                 IERC20(_cvxcrv).safeTransfer(_receiver, _harvestBounty);
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