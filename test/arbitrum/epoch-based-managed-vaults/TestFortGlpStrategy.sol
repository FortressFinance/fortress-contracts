// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import {BaseTest, AssetVault, IStrategy, IERC20} from "./BaseTest.sol";
import "./BaseTest.sol";

import "src/shared/interfaces/ERC4626.sol";

import {FortressGlpStrategy, IFortGlp} from "src/arbitrum/epoch-based-managed-vaults/stratagies/FortressGlpStrategy.sol";
import {GlpCompounder} from "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract TestFortGlpStrategy is BaseTest {

    address fortGlp = address(0x9363e5e4a7aDfB346BEA0fe87a8BD02fddA48855);
    uint256 public assetVaultBalanceBeforeStrategy;
    
    function setUp() public {
        
        _setUp(USDC);

        GlpCompounder _glpCompounder = new GlpCompounder(fortGlp, manager, platform);
        fortGlp = address(_glpCompounder);

        uint256[] memory _poolType = new uint256[](1);
        _poolType[0] = 13;
        address[] memory _poolAddress = new address[](1);
        _poolAddress[0] = address(0);
        address[] memory _fromList = new address[](1);
        _fromList[0] = WETH;
        address[] memory _toList = new address[](1);
        _toList[0] = USDC;

        vm.startPrank(address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc));
        // address owner = vm.envAddress("OWNER");
        IFortressSwap(FORTRESS_SWAP).deleteRoute(WETH, USDC);
        IFortressSwap(FORTRESS_SWAP).updateRoute(WETH, USDC, _poolType, _poolAddress, _fromList, _toList);
        vm.stopPrank();
    }

    function testCorrectFlow(uint256 _epochDuration, uint256 _investorDepositAmount) public {
        vm.assume(_epochDuration < (type(uint256).max - block.timestamp));
        vm.assume(_epochDuration > 0);
        vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 10 ether);
        
        _initVault(_epochDuration);

        for (uint256 i = 0; i < 2; i++) {
            if (i > 0) {
                _initEpoch(_epochDuration);
            }

            address _wethAssetVault = _addAssetVault(WETH);

            address _fortGlpStrategy = _deployFortGlpStrategy(WETH, _wethAssetVault);

            _initiateStrategy(WETH, _wethAssetVault, _fortGlpStrategy);

            _addStrategy(_wethAssetVault, _fortGlpStrategy);
            
            // if (i > 0) revert("test0");
            uint256 _amountDeposited = _letInvestorsDepositOnCollateralRequired(_investorDepositAmount);
            // _managerAddCollateral(1 ether);
            // if (i > 0) revert("test1");

            _startEpoch();

            _amountDeposited = _depositToAssetsVault(_wethAssetVault, WETH, _amountDeposited);

            _depositToStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);
            
            uint256 _fortGlpShares = _executeFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _amountDeposited);

            uint256 _amountOut = _profitableTerminateFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _fortGlpShares);

            // _withdrawFromStrategy(_wethAssetVault, _fortGlpStrategy, _amountOut);
            _withdrawAllFromStrategy(_wethAssetVault, _fortGlpStrategy);

            _withdrawFromAssetVault(_wethAssetVault, _amountOut);
            
            _endEpoch();

            _removeCollateral(IERC20(address(metaVault)).balanceOf(address(metaVault)));
        }
    }

    // 1*
    // 1. initiate vault (which intiates an epoch)
    // 2. user deposits
    // 3. start epoch
    // 4. manage assets (1. deposit into AssetsVault, 2. deposit into Strategy vaults)
    // 5. end epoch
    // 6. user withdraws

    // 2* (continue from 1)
    // 1. call 1*
    // 2. initiate a new epoch (initiateEpoch)
    // 3. user deposits
    // 4. start epoch
    // 5. manage assets (1. deposit into AssetsVault, 2. deposit into Strategy vaults)
    // 6. end epoch
    // 7. user withdraws

    // *3 (add asset vault)
    // 1. call 2*
    // 2. add asset vault
    // 3. call 2* again

    // *4 (add strategy vault)
    // 1. call 2*
    // 2. add strategy vault
    // 3. call 2* again

    // *5 (remove asset vault (blacklist asset))
    // 1. call 3*
    // 2. remove asset vault
    // 3. call 2*

    // *6 (update manager)
    // 1. call 2*
    // 2. update manager
    // 3. call 2* again

    // *7 (manager didnt finish epoch on time)
    // 1. call 2*
    // 2. start epoch
    // 3. manage assets (1. deposit into AssetsVault, 2. deposit into Strategy vaults)
    // 4. do not end epoch on time
    // 5. punish vault manager
    // 6. end epoch

    // ------------------- WRONG FLOWS -------------------

    // *1 (Investor interact with contract on wrong state)

    // *2 (call executeLatenessPenalty (1) before end epoch and (2) when penalty is disabled)

    // *3 (test modifiers)

    // *4 (deposit wrong asset)

    // *5 (withdraw wrong asset)

    // *6 (start epoch before timelock passed)

    // *7 (start epoch without calling initiateEpoch)

    // *8 (end epoch without withdawing assets)

    // *9 (deposit a blacklisted asset)

    // ------------------- UTILS -------------------

    function _deployFortGlpStrategy(address _enabledAsset, address _assetVault) internal returns (address) {
        FortressGlpStrategy _fortGlpStrategy = new FortressGlpStrategy(_enabledAsset, _assetVault, platform, manager, fortGlp, FORTRESS_SWAP);

        assertEq(_fortGlpStrategy.isActive(), false);
        assertEq(_fortGlpStrategy.isAssetEnabled(_enabledAsset), true);

        return address(_fortGlpStrategy);
    }

    function _executeFortGlpStrategy(address _asset, address _assetVaultAddress, address _strategy, uint256 _amount) internal returns (uint256 _fortGlpShares) {
        assertEq(metaVault.isUnmanaged(), false, "_executeFortGlpStrategy: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_executeFortGlpStrategy: E2");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E3");
        assertTrue(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy) >= _amount, "_executeFortGlpStrategy: E3");
        assertTrue(AssetVault(_assetVaultAddress).strategies(_strategy), "_executeFortGlpStrategy: E03");

        // TODO - we deposit only half of the amount to the strategy because GLP mint exceed max USDG (which means the contract can't take more of that asset)
        bytes memory _configData = abi.encode(_asset, _amount / 10, 0);
        assetVaultBalanceBeforeStrategy = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);

        vm.prank(manager);
        _fortGlpShares = IStrategy(_strategy).execute(_configData);
        
        assertEq(IERC20(fortGlp).balanceOf(_strategy), _fortGlpShares, "_executeFortGlpStrategy: E4");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E5");
        assertTrue(_fortGlpShares > 0, "_executeFortGlpStrategy: E6");

        return _fortGlpShares;
    }

    function _profitableTerminateFortGlpStrategy(address _asset, address _assetVaultAddress, address _strategy, uint256 _amount) internal returns (uint256) {
        assertEq(metaVault.isUnmanaged(), false, "_profitableTerminateFortGlpStrategy: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_profitableTerminateFortGlpStrategy: E2");
        assertEq(IStrategy(_strategy).isActive(), true, "_profitableTerminateFortGlpStrategy: E4");
        assertTrue(AssetVault(_assetVaultAddress).strategies(_strategy), "_profitableTerminateFortGlpStrategy: E04");

        bytes memory _configData = abi.encode(_asset, _amount, 0);

        uint256 _before = IERC20(fortGlp).balanceOf(address(_strategy));
        uint256 _underlyingBefore = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(address(_strategy));
        
        // Fast forward 1 month
        skip(216000);
        
        vm.rollFork(block.number + 1);
        GlpCompounder(fortGlp).harvest(manager, 0);
        
        vm.prank(manager);
        uint256 _amountOut = IStrategy(_strategy).terminate(_configData);
        
        assertEq(IERC20(fortGlp).balanceOf(_strategy), _before - _amount, "_profitableTerminateFortGlpStrategy: E6");
        assertEq(IStrategy(_strategy).isActive(), true, "_profitableTerminateFortGlpStrategy: E7");
        assertEq(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy), (_underlyingBefore + _amountOut), "_profitableTerminateFortGlpStrategy: E8");

        uint256 _currentBalance = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);
        if (assetVaultBalanceBeforeStrategy > _currentBalance) {
            uint256 _amountToDeal = _currentBalance + (assetVaultBalanceBeforeStrategy - _currentBalance);
            _dealERC20(AssetVault(_assetVaultAddress).getAsset(), _strategy , (_amountToDeal * 2));
        }

        _currentBalance = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy);
        assertTrue(_currentBalance > assetVaultBalanceBeforeStrategy, "_profitableTerminateFortGlpStrategy: E9");
        
        return _currentBalance;
    }
}
