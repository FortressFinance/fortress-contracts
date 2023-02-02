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
        
        _executeFortGlpStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);

        // _terminateFortGlpStrategy

        // _withdrawFromStrategy
        // _withdrawFromAssetsVault
        // _endEpoch();
    }

    function _deployFortGlpStrategy(address _enabledAsset, address _assetVault) internal returns (address) {
        FortressGlpStrategy _fortGlpStrategy = new FortressGlpStrategy(_enabledAsset, _assetVault, platform, manager, fortGlp);

        assertEq(_fortGlpStrategy.isActive(), false);
        assertEq(_fortGlpStrategy.isAssetEnabled(_enabledAsset), true);

        return address(_fortGlpStrategy);
    }

    function _executeFortGlpStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal {
        assertEq(metaVault.isUnmanaged(), false, "_executeFortGlpStrategy: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_executeFortGlpStrategy: E2");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E3");
        assertTrue(IERC20(AssetVault(_assetVaultAddress).getAsset()).balanceOf(_strategy) >= _amount, "_executeFortGlpStrategy: E3");

        bytes memory _configData = abi.encode(_amount, 0);

        vm.prank(manager);
        uint256 _fortGlpShares = IStrategy(_strategy).execute(_configData);

        assertEq(IERC20(fortGlp).balanceOf(_strategy), _fortGlpShares, "_executeFortGlpStrategy: E4");
        assertEq(IStrategy(_strategy).isActive(), true, "_executeFortGlpStrategy: E5");
    }
}
