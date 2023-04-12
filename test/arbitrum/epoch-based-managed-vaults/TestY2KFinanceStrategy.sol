// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "./BaseTest.sol";

// import "src/arbitrum/epoch-based-managed-vaults/stratagies/Y2KFinanceStrategy.sol";
contract TestY2KFinanceStrategy {}
// contract TestY2KFinanceStrategy is BaseTest {

//     uint256 assetVaultBalanceBeforeStrategy;

//     function setUp() public {
        
//         _setUp(WETH);

//         // TODO
//         // setup swap to Y2K --> WETH
//     }

//     function testExecuteY2KFinanceStrategy(uint256 _epochDuration, uint256 _investorDepositAmount) public returns (address, address, uint256) {
//         vm.assume(_epochDuration > 0);
//         vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 2 ether);
        
//         if (_epochDuration > type(uint256).max / 2) {
//             _epochDuration = type(uint256).max / 2;
//         }

//         _initVault(_epochDuration);

//         address _wethAssetVault = _addAssetVault(WETH);
        
//         address _y2kFinanceStrategy = _deployY2KFinanceStrategy(_wethAssetVault);

//         _initiateStrategy(WETH, _wethAssetVault, _y2kFinanceStrategy);

//         _addStrategy(_wethAssetVault, _y2kFinanceStrategy);
        
//         uint256 _amountDeposited = _investorsDepositOnCollateralRequired(_investorDepositAmount);

//         _startEpoch();

//         _amountDeposited = _depositToAssetsVault(_wethAssetVault, WETH, _amountDeposited);

//         _depositToStrategy(_wethAssetVault, _y2kFinanceStrategy, _amountDeposited);

//         uint256 _shares = _executeStrategy(_wethAssetVault, _y2kFinanceStrategy, _amountDeposited);

//         return (_wethAssetVault, _y2kFinanceStrategy, _shares);
//     }

//     function testTerminateY2KFinanceStrategy(uint256 _epochDuration, uint256 _investorDepositAmount) internal {
//         (address _wethAssetVault, address _y2kFinanceStrategy, uint256 _shares) = testExecuteY2KFinanceStrategy(_epochDuration, _investorDepositAmount);

//         _profitableTerminateStrategy(_wethAssetVault, _y2kFinanceStrategy, _shares);
//     }

//     // ------------------- UTILS -------------------

//     function _deployY2KFinanceStrategy(address _assetVault) internal returns (address) {
//         Y2KFinanceStrategy _y2kFinanceStrategy = new Y2KFinanceStrategy(_assetVault, platform, manager, address(fortressSwap));

//         assertEq(_y2kFinanceStrategy .isActive(), false);

//         return address(_y2kFinanceStrategy);
//     }

//     function _executeStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal returns (uint256) {
//         assertEq(metaVault.isUnmanaged(), false, "_executeY2kFinanceStrategy: E1");
//         assertEq(metaVault.isEpochinitiated(), true, "_executeY2kFinanceStrategy: E2");
//         assertEq(IStrategy(_strategy).isActive(), true, "_executeY2kFinanceStrategy: E3");
//         assertTrue(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy) >= _amount, "_executeY2kFinanceStrategy: E4");
//         assertTrue(AssetVault(_assetVaultAddress).strategies(_strategy), "_executeY2kFinanceStrategy: E03");
        
//         // uint256 UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
//         // TODO - get correct timestamp
//         uint256 _id = 20;
//         // get from getVaults of vaultFactory https://arbiscan.io/address/0x984e0eb8fb687afa53fc8b33e12e04967560e092#readContract
//         //  y2kSTETH_982*RISK (rY2K)
//         address _vault = address(0x1F53A194b45D6D2F5D4F05234626E038dFCeC4A3);
//         // get from events of rewardFactory https://arbiscan.io/address/0x9889Fca1d9A5D131F5d4306a2BC2F293cAfAd2F3#events
//         address _stakingRewards = address(0xA5EaF3DE2F097dD5d82cB9517eFf7E038485F189);
//         bytes memory _configData = abi.encode(_id, _amount, _vault, _stakingRewards);
//         assetVaultBalanceBeforeStrategy = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);

//         vm.prank(manager);
//         uint256 _shares = IStrategy(_strategy).execute(_configData);
        
//         assertEq(IERC1155(_vault).balanceOf(_strategy, _id), _shares, "_executeY2kFinanceStrategy: E4");
//         assertEq(IStrategy(_strategy).isActive(), true, "_executeY2kFinanceStrategy: E5");
//         assertTrue(_shares > 0, "_executeY2kFinanceStrategy: E6");

//         return _shares;
//     }

//     function _profitableTerminateStrategy(address _assetVaultAddress, address _strategy, uint256 _shares) internal {
//         assertEq(metaVault.isUnmanaged(), false, "_profitableTerminateStrategy: E1");
//         assertEq(metaVault.isEpochinitiated(), true, "_profitableTerminateStrategy: E2");
//         assertEq(IStrategy(_strategy).isActive(), true, "_profitableTerminateStrategy: E4");
//         assertTrue(AssetVault(_assetVaultAddress).strategies(_strategy), "_profitableTerminateStrategy: E04");
        
//         // uint256 UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
//         // TODO - get correct timestamp
//         uint256 _id = 20;
//         // get from getVaults of vaultFactory https://arbiscan.io/address/0x984e0eb8fb687afa53fc8b33e12e04967560e092#readContract
//         //  y2kSTETH_982*RISK (rY2K)
//         address _vault = address(0x1F53A194b45D6D2F5D4F05234626E038dFCeC4A3);
//         bytes memory _configData = abi.encode(_id, _shares, _vault, true);
//         uint256 _before = IERC1155(_vault).balanceOf(_strategy, _id);
//         uint256 _underlyingBefore = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(address(_strategy));

//         // Fast forward 1 month
//         skip(216000);
        
//         vm.prank(manager);
//         uint256 _amountOut = IStrategy(_strategy).terminate(_configData);
        
//         assertEq(IERC1155(_vault).balanceOf(_strategy, _id), _before - _amountOut, "_profitableTerminateStrategy: E6");
//         assertEq(IStrategy(_strategy).isActive(), true, "_profitableTerminateStrategy: E7");
//         assertEq(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy), (_underlyingBefore + _amountOut), "_profitableTerminateStrategy: E8");

//         uint256 _currentBalance = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);
//         if (assetVaultBalanceBeforeStrategy > _currentBalance) {
//             uint256 _amountToDeal = _currentBalance + (assetVaultBalanceBeforeStrategy - _currentBalance);
//             _dealERC20(AssetVault(_assetVaultAddress).getAsset(), _strategy , (_amountToDeal * 2));
//         }

//         _currentBalance = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);
//         assertTrue(_currentBalance > assetVaultBalanceBeforeStrategy, "_profitableTerminateStrategy: E9");
//     }
// }