// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import {BaseTest, AssetVault, IStrategy, IERC20} from "./BaseTest.sol";
import "./BaseTest.sol";

import "src/shared/interfaces/ERC4626.sol";

import {FortressGlpStrategy, IFortGlp} from "src/arbitrum/epoch-based-managed-vaults/stratagies/FortressGlpStrategy.sol";
import {GlpCompounder} from "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract TestFortGlpStrategy is BaseTest {

    address fortGlp = address(0x9363e5e4a7aDfB346BEA0fe87a8BD02fddA48855);
    uint256 public totalBalance;
    
    function setUp() public {
        
        _setUp(USDC);

        GlpCompounder _glpCompounder = new GlpCompounder(fortGlp, manager, platform);
        fortGlp = address(_glpCompounder);
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
        
        _endEpoch();
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
        totalBalance = _amount;

        console.log("totalSupply:", ERC4626(fortGlp).totalSupply());
        console.log("totalAssets:", ERC4626(fortGlp).totalAssets());
        vm.prank(manager);
        _fortGlpShares = IStrategy(_strategy).execute(_configData);
        console.log("totalSupply1:", ERC4626(fortGlp).totalSupply());
        console.log("totalAssets1:", ERC4626(fortGlp).totalAssets());
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
        
        uint256 _beforeGlp = ERC4626(fortGlp).totalAssets();
        
        
        console.log("_pendingRewards: %s", GlpCompounder(fortGlp).pendingRewards());
        
        // skip(10000000000000000000);
        // Fast forward 1 month
        skip(216000);
        skip(216000);
        skip(216000);
        skip(216000);
        skip(216000);
        skip(216000);
        skip(216000);
        // _pendingRewards: 56536888062089
        // _pendingRewards1: 61218657610029740779
        

        // totalBalance: 7578295835801795476650
        // totalBalance: 6344306315879809407558 //_amountOut
        // IFortGlp(fortGlp).harvest(manager, WETH, 1000000000000000);
        uint256 _pendingRewards = GlpCompounder(fortGlp).pendingRewards();
        console.log("_pendingRewards1: %s", _pendingRewards);
        console.log("_previewDepositBefore: %s", ERC4626(fortGlp).previewDeposit(1000000000000000000));
        uint256 _rewards = GlpCompounder(fortGlp).harvest(manager, 0);
        console.log("_rewards: %s", _rewards);
        

        ////////-----------------
        // _pendingRewards1: 61433698273419796676
        // _pendingRewards1: 83973115516102289 // _rewards
        
        // IFortGlp(fortGlp).harvest(manager, 0);
        uint256 _afterGlp = ERC4626(fortGlp).totalAssets();
        console.log("_previewDepositAfter: %s", ERC4626(fortGlp).previewDeposit(1000000000000000000));
        console.log("_before: %s", _beforeGlp);
        console.log("_after: %s", _afterGlp);
        // _before: 11972634479561972540869140
        // _after: 11972634562652131888518609
        // _before: 11978178413654131613410390
        // _after: 11978178496686252536283058

        vm.prank(manager);
        _amountOut = IStrategy(_strategy).terminate(_configData);

        // totalBalance = totalBalance - ;
        assertEq(totalBalance, _amountOut, "yahm: E5");
        console.log("totalBalance: %s", totalBalance);
        console.log("_amountOut: %s", _amountOut);

        assertEq(IERC20(fortGlp).balanceOf(_strategy), _before - _amount, "_terminateFortGlpStrategy: E6");
        assertEq(IStrategy(_strategy).isActive(), true, "_terminateFortGlpStrategy: E7");
        assertEq(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy), (_underlyingBefore + _amountOut), "_terminateFortGlpStrategy: E8");

        return _amountOut;
    }
}
