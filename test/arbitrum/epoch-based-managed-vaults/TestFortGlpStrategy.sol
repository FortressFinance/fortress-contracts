// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseTest, AssetVault, IStrategy, IERC20} from "./BaseTest.sol";

import {FortressGlpStrategy} from "src/arbitrum/epoch-based-managed-vaults/stratagies/FortressGlpStrategy.sol";

contract TestFortGlpStrategy is BaseTest {

    address fortGlp = address(0x9363e5e4a7aDfB346BEA0fe87a8BD02fddA48855);
    
    function setUp() public {
        
        _setUp(USDC);
    }

    function testCorrectFlow(uint256 _epochDuration, uint256 _investorDepositAmount) public {
        vm.assume(_epochDuration < (type(uint256).max - block.timestamp));
        vm.assume(_epochDuration > 0);
        vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 10 ether);

        _initVault(_epochDuration);

        address _wethAssetVault = _addAssetVault(WETH);

        address _fortGlpStrategy = _deployFortGlpStrategy(WETH, _wethAssetVault);

        _initiateStrategy(WETH, _wethAssetVault, _fortGlpStrategy);

        _addStrategy(_wethAssetVault, _fortGlpStrategy);

        uint256 _amountDeposited = _letInvestorsDepositOnCollateralRequired(_investorDepositAmount);
        
        _startEpoch();

        _amountDeposited = _depositToAssetsVault(_wethAssetVault, WETH, _amountDeposited);

        _depositToStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);
        
        uint256 _fortGlpShares = _executeFortGlpStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);

        uint256 _amountOut = _terminateFortGlpStrategy(_wethAssetVault, _fortGlpStrategy, _fortGlpShares);

        _withdrawFromStrategy(_wethAssetVault, _fortGlpStrategy, _amountOut);

        _withdrawFromAssetVault(_wethAssetVault, _amountOut);
        // _endEpoch();
    }

    function _deployFortGlpStrategy(address _enabledAsset, address _assetVault) internal returns (address) {
        FortressGlpStrategy _fortGlpStrategy = new FortressGlpStrategy(_enabledAsset, _assetVault, platform, manager, fortGlp);

        assertEq(_fortGlpStrategy.isActive(), false);
        assertEq(_fortGlpStrategy.isAssetEnabled(_enabledAsset), true);

        return address(_fortGlpStrategy);
    }

    function _executeFortGlpStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal returns (uint256 _fortGlpShares) {
        assertEq(metaVault.isUnmanaged(), false, "_executeFortGlpStrategy: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_executeFortGlpStrategy: E2");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E3");
        assertTrue(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy) >= _amount, "_executeFortGlpStrategy: E3");

        bytes memory _configData = abi.encode(_amount, 0);

        vm.prank(manager);
        _fortGlpShares = IStrategy(_strategy).execute(_configData);

        assertEq(IERC20(fortGlp).balanceOf(_strategy), _fortGlpShares, "_executeFortGlpStrategy: E4");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E5");

        return _fortGlpShares;
    }

    function _terminateFortGlpStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal returns (uint256 _amountOut) {
        assertEq(metaVault.isUnmanaged(), false, "_terminateFortGlpStrategy: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_terminateFortGlpStrategy: E2");
        assertEq(IStrategy(_strategy).isActive(), true, "_terminateFortGlpStrategy: E4");

        bytes memory _configData = abi.encode(_amount, 0);

        uint256 _before = IERC20(fortGlp).balanceOf(address(_strategy));
        uint256 _underlyingBefore = IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(address(_strategy));
        vm.prank(manager);
        _amountOut = IStrategy(_strategy).terminate(_configData);

        assertEq(IERC20(fortGlp).balanceOf(_strategy), _before - _amount, "_terminateFortGlpStrategy: E6");
        assertEq(IStrategy(_strategy).isActive(), true, "_terminateFortGlpStrategy: E7");
        assertEq(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy), (_underlyingBefore + _amountOut), "_terminateFortGlpStrategy: E8");

        return _amountOut;
    }
}
