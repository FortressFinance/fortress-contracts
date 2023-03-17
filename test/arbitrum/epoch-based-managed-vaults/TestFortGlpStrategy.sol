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

    function testCorrectFlow(uint256 _epochEndBlockNumber, uint256 _investorDepositAmount) public {
        // uint256 _epochEndBlockNumber = 1679048754;
        // uint256 _epochEndBlockNumber = 1; 70818642
        // vm.assume(_epochEndBlockNumber < (type(uint256).max - 70818642));
        vm.assume(_epochEndBlockNumber < (type(uint256).max - 10));
        vm.assume(_epochEndBlockNumber > block.number);
        vm.assume(_investorDepositAmount > 0.1 ether && _investorDepositAmount < 2 ether);
        
        _initVault(_epochEndBlockNumber);

        console.log("_epochEndBlockNumber ", _epochEndBlockNumber);
        console.log("block.number ", block.number);

        for (uint256 i = 0; i < 4; i++) {

            if (i > 0) {
                _initEpoch(_epochEndBlockNumber);
            }

            // Add asset vaults
            address _wethAssetVault = _addAssetVault(WETH);
            address _usdtAssetVault = _addAssetVault(USDT);
            //

            // Add strategies
            address _fortGlpStrategy = _deployFortGlpStrategy(WETH, _wethAssetVault);
            address _fortGlpStrategyUsdt = _deployFortGlpStrategy(USDT, _usdtAssetVault);

            _initiateStrategy(WETH, _wethAssetVault, _fortGlpStrategy);

            _addStrategy(_wethAssetVault, _fortGlpStrategy);

            _initiateStrategy(USDT, _usdtAssetVault, _fortGlpStrategyUsdt);

            _addStrategy(_usdtAssetVault, _fortGlpStrategyUsdt);
            //

            uint256 _amountDeposited = _investorsDepositOnCollateralRequired(_investorDepositAmount);

            _startEpoch();

            _amountDeposited = _depositToAssetsVault(_wethAssetVault, WETH, _amountDeposited);

            _depositToStrategy(_wethAssetVault, _fortGlpStrategy, _amountDeposited);

            uint256 _fortGlpShares = _executeFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _amountDeposited);

            uint256 _amountOut = _profitableTerminateFortGlpStrategy(WETH, _wethAssetVault, _fortGlpStrategy, _fortGlpShares);

            // _withdrawFromStrategy(_wethAssetVault, _fortGlpStrategy, _amountOut);
            _withdrawAllFromStrategy(_wethAssetVault, _fortGlpStrategy);

            _withdrawFromAssetVault(_wethAssetVault, _amountOut);

            if (i == 3) {
                _executeLatenessPenalty();
            }

            _endEpoch();

            _removeCollateral(IERC20(address(metaVault)).balanceOf(address(metaVault)));
            console.log("DONE: ", i);

            // TODO
            // _investorWithdraw(_amountOut);
        }

        // Blacklist asset
        _blacklistAsset(WETH);
        _blacklistAsset(USDT);

        // Update manager
        _updateManager(address(alice));
    }

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
        bytes memory _configData = abi.encode(_asset, _amount / 50, 0);
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
        // _dealERC20(WETH, address(fortGlp) , 5 ether);

        // IFortGlp(fortGlp).harvest(address(manager), WETH, 0);
        // -----

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
