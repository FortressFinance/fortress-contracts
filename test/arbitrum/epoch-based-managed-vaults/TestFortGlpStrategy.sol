// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseTest.sol";

import {ERC4626} from "src/shared/interfaces/ERC4626.sol";

import {FortressGlpStrategy, IFortGlp} from "src/arbitrum/epoch-based-managed-vaults/stratagies/FortressGlpStrategy.sol";
import {GlpCompounder} from "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract TestFortGlpStrategy is BaseTest {

    address fortGlp;
    uint256 public assetVaultBalanceBeforeStrategy;
    
    function setUp() public {
        
        _setUp(USDC);

        address[] memory _underlyingAssets5 = new address[](5);
        _underlyingAssets5[0] = WETH;
        _underlyingAssets5[1] = ETH;
        _underlyingAssets5[2] = FRAX;
        _underlyingAssets5[3] = USDC;
        _underlyingAssets5[4] = USDT;

        GlpCompounder glpCompounder = new GlpCompounder("description", manager, platform, address(fortressSwap), _underlyingAssets5);
        fortGlp = address(glpCompounder);

        uint256[] memory _poolType = new uint256[](1);
        _poolType[0] = 13;
        address[] memory _poolAddress = new address[](1);
        _poolAddress[0] = address(0);
        address[] memory _fromList = new address[](1);
        _fromList[0] = WETH;
        address[] memory _toList = new address[](1);
        _toList[0] = USDC;

        vm.startPrank(owner);
        // address owner = vm.envAddress("OWNER");
        FortressArbiSwap(payable(address(fortressSwap))).deleteRoute(WETH, USDC);
        FortressArbiSwap(payable(address(fortressSwap))).updateRoute(WETH, USDC, _poolType, _poolAddress, _fromList, _toList);
        vm.stopPrank();
    }

    function testCorrectFlow(uint256 _epochDuration, uint256 _investorDepositAmount) public {
        vm.assume(_epochDuration < (type(uint256).max - block.timestamp));
        vm.assume(_epochDuration > 0);
        vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 10 ether);
        
        _initVault(_epochDuration);

        for (uint256 i = 0; i < 1; i++) {
            if (i > 0) {
                _initEpoch(_epochDuration);
            }

            address _wethAssetVault = _addAssetVault(WETH);

            address _fortGlpStrategy = _deployFortGlpStrategy(WETH, _wethAssetVault);

            _initiateStrategy(WETH, _wethAssetVault, _fortGlpStrategy);

            _addStrategy(_wethAssetVault, _fortGlpStrategy);
            
            uint256 _amountDeposited = _investorsDepositOnCollateralRequired(_investorDepositAmount);

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
            console.log("DONE: ", i);
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
        FortressGlpStrategy _fortGlpStrategy = new FortressGlpStrategy(_enabledAsset, _assetVault, platform, manager, fortGlp, address(fortressSwap));

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
        uint256 _before = GlpCompounder(fortGlp).balanceOf(address(_strategy));
        uint256 _underlyingBefore = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(address(_strategy));

        // Fast forward 1 month
        skip(216000);
        
        // TODO -----
        // vm.rollFork(block.number + 1);
        // GlpCompounder(fortGlp).harvest(address(manager), 0);

        // artificially inject WETH rewards to the GLP vault 
        _dealERC20(WETH, address(fortGlp) , 5 ether);
        // -----

        IFortGlp(fortGlp).harvest(address(manager), WETH, 0);

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
