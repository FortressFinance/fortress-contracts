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
    }

    function testCorrectFlow(uint256 _epochDuration) public {
        vm.assume(_epochDuration < (type(uint256).max - block.timestamp));
        vm.assume(_epochDuration > 0);
        // vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 10 ether);
        // , uint256 _investorDepositAmount
        uint256 _investorDepositAmount = 0.5 ether;

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

        _initVault(_epochDuration);

        address _wethAssetVault = _addAssetVault(WETH);

        address _fortGlpStrategy = _deployFortGlpStrategy(WETH, _wethAssetVault);

        _initiateStrategy(WETH, _wethAssetVault, _fortGlpStrategy);

        _addStrategy(_wethAssetVault, _fortGlpStrategy);

        uint256 _amountDeposited = _letInvestorsDepositOnCollateralRequired(_investorDepositAmount);
        
        _startEpoch();

        _amountDeposited = _depositToAssetsVault(_wethAssetVault, WETH, _amountDeposited);

        _depositToStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);
        
        uint256 _fortGlpShares = _executeFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _amountDeposited);

        uint256 _amountOut = _profitableTerminateFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _fortGlpShares);

        // _withdrawFromStrategy(_wethAssetVault, _fortGlpStrategy, _amountOut);
        _withdrawAllFromStrategy(_wethAssetVault, _fortGlpStrategy);

        _withdrawFromAssetVault(_wethAssetVault, _amountOut);
        
        _endEpoch();
    }

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

        bytes memory _configData = abi.encode(_asset, _amount, 0);
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
        
        uint256 _rewards = GlpCompounder(fortGlp).harvest(manager, 0);
        
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
