// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/arbitrum/epoch-based-managed-vaults/MetaVault.sol";
import "src/arbitrum/epoch-based-managed-vaults/interfaces/IStrategy.sol";

import "script/arbitrum/utils/AddressesArbi.sol";

contract BaseTest is Test, AddressesArbi {

    address FORTRESS_SWAP = address(0xd2DA200a79AbC6526EABACF98F8Ea4C26F34796F);

    address owner;
    address alice;
    address bob;
    address charlie;
    address manager;
    address platform;

    // uint256 amount;
    // uint256 accumulatedAmount;
    // uint256 accumulatedShares;
    // uint256 shares;
    // uint256 aliceAmountOut;
    // uint256 bobAmountOut;
    // uint256 charlieAmountOut;

    uint256 arbiFork;
    
    IFortressSwap fortressSwap;
    MetaVault metaVault;

    function _setUp(address _asset) internal {
        
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
        arbiFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbiFork);

        owner = address(0x16cAD91E1928F994816EbC5e759d8562aAc65ab2);
        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);
        charlie = address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc);
        manager = address(0x77Ee01E3d0E05b4afF42105Fe004520421248261);
        platform = address(0x9cbD8440E5b8f116082a0F4B46802DB711592fAD);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(manager, 100 ether);
        vm.deal(platform, 100 ether);
        
        fortressSwap = IFortressSwap(payable(FORTRESS_SWAP));

        metaVault = new MetaVault(ERC20(_asset), "MetaVault", "MV", platform, manager, FORTRESS_SWAP);
    }

    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        uint256 _before = IERC20(_token).balanceOf(_recipient);
        deal({ token: address(_token), to: _recipient, give: _amount});
        
        uint256 _after = IERC20(_token).balanceOf(_recipient);
        assertEq(_after - _before, _amount, "_dealERC20: E1");
    }


    // ------------------- MANAGER CORRECT FLOW -------------------

    // call first
    function _initVault(uint256 _epochDuration) internal {
        uint256 _epochEndTimestamp = uint256(block.timestamp) + _epochDuration;
        bool _isPenaltyEnabled = true;
        bool _isPerformanceFeeEnabled = true;
        bool _isCollateralRequired = true;

        bytes memory _configData = abi.encode(_epochEndTimestamp, _isPenaltyEnabled, _isPerformanceFeeEnabled, _isCollateralRequired);
        
        vm.startPrank(manager);
        metaVault.initiateVault(_configData);
        
        assertEq(true, true, "_testInitVault: E1");
        assertEq(metaVault.epochEndTimestamp(), _epochEndTimestamp, "_testInitVault: E1");
        assertEq(metaVault.isPenaltyEnabled(), _isPenaltyEnabled, "_testInitVault: E2");
        assertEq(metaVault.isPerformanceFeeEnabled(), _isPerformanceFeeEnabled, "_testInitVault: E3");
        assertEq(metaVault.isCollateralRequired(), _isCollateralRequired, "_testInitVault: E4");
        assertEq(metaVault.isUnmanaged(), true, "_testInitVault: E5");
        assertEq(metaVault.timelockStartTimestamp(), block.timestamp, "_testInitVault: E6");
        assertEq(metaVault.isTimelockInitiated(), true, "_testInitVault: E7");

        vm.expectRevert();
        metaVault.initiateEpoch(_configData);

        vm.expectRevert();
        metaVault.startEpoch();

        vm.stopPrank();
    }

    // call when vault is "unmanaged"
    function _addAssetVault(address _targetAsset) internal returns (address _assetVaultAddress) {
        if ((_targetAsset == WETH && address(metaVault.asset()) == USDC) || (_targetAsset == USDC && address(metaVault.asset()) == WETH)) {
            _addWETHUSDCRouteToSwap();
        }
        
        assertTrue(IFortressSwap(fortressSwap).routeExists(address(metaVault.asset()), _targetAsset), "_addAssetVault: E1");
        assertTrue(IFortressSwap(fortressSwap).routeExists(_targetAsset, address(metaVault.asset())), "_addAssetVault: E2");
        assertTrue(metaVault.isUnmanaged(), "_addAssetVault: E3");
        
        vm.startPrank(manager);

        _assetVaultAddress = metaVault.addAssetVault(_targetAsset);
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(metaVault.assetVaults(_targetAsset), _assetVaultAddress, "_addAssetVault: E4");
        assertEq(metaVault.assetVaultList(metaVault.getAssetVaultsLength() - 1), _assetVaultAddress, "_addAssetVault: E5");
        assertEq(_assetVault.getAsset(), _targetAsset, "_addAssetVault: E6");
        assertEq(_assetVault.metaVault(), address(metaVault), "_addAssetVault: E7");
        assertEq(_assetVault.metaVaultPrimaryAsset(), address(metaVault.asset()), "_addAssetVault: E8");
        
        vm.stopPrank();
    }

    // call when vault is "unmanaged"
    function _letInvestorsDepositOnCollateralRequired(uint256 _amount) internal returns (uint256 _amountDeposited) {
        assertEq(metaVault.isUnmanaged(), true, "_testInitVault: E5");
         
        uint256 _totalSupply = metaVault.previewDeposit(_amount) * 3;
        uint256 _managerShares = _managerAddCollateral(_totalSupply / metaVault.collateralRequirement());
        uint256 _maxMintAmount = _totalSupply - (_totalSupply / metaVault.collateralRequirement());
        uint256 _maxMintDelta = _totalSupply - _maxMintAmount;
        assertApproxEqAbs(metaVault.maxMint(address(0)), _maxMintAmount, 1e5, "_letInvestorsDeposit: E1");
        assertApproxEqAbs(metaVault.maxDeposit(address(0)), metaVault.convertToAssets(_maxMintAmount), 1e5, "_letInvestorsDeposit: E2");

        _dealERC20(address(metaVault.asset()), alice, _amount);
        vm.startPrank(alice);
        IERC20(address(metaVault.asset())).approve(address(metaVault), _amount);
        uint256 _sharesAlice = metaVault.deposit(_amount, alice);
        vm.stopPrank();
        
        assertEq(metaVault.balanceOf(alice), metaVault.convertToShares(_amount), "_letInvestorsDeposit: E3");
        assertEq(metaVault.balanceOf(alice), _sharesAlice, "_letInvestorsDeposit: E4");
        assertApproxEqAbs(metaVault.maxMint(address(0)), _maxMintAmount - _sharesAlice, 1e5, "_letInvestorsDeposit: E5");
        
        _dealERC20(address(metaVault.asset()), bob, _amount);
        vm.startPrank(bob);
        IERC20(address(metaVault.asset())).approve(address(metaVault), _amount);
        uint256 _sharesBob = metaVault.deposit(_amount, bob);
        vm.stopPrank();
        
        assertEq(metaVault.balanceOf(alice), metaVault.convertToShares(_amount), "_letInvestorsDeposit: E6");
        assertEq(metaVault.balanceOf(alice), _sharesBob, "_letInvestorsDeposit: E7");
        assertApproxEqAbs(metaVault.maxMint(address(0)), _maxMintAmount - (_sharesAlice + _sharesBob), 1e5, "_letInvestorsDeposit: E8");

        _dealERC20(address(metaVault.asset()), charlie, _amount);
        vm.startPrank(charlie);
        IERC20(address(metaVault.asset())).approve(address(metaVault), _amount);
        uint256 _lastAmount = metaVault.maxDeposit(address(0));
        assertApproxEqAbs(_amount - _maxMintDelta, _lastAmount, 1e5, "_letInvestorsDeposit: E9");
        uint256 _sharesCharlie = metaVault.deposit(_lastAmount, charlie);
        vm.stopPrank();
        
        assertEq(metaVault.balanceOf(charlie), metaVault.convertToShares(_lastAmount), "_letInvestorsDeposit: E10");
        assertEq(metaVault.balanceOf(charlie), _sharesCharlie, "_letInvestorsDeposit: E11");
        assertApproxEqAbs(metaVault.maxMint(address(0)), _maxMintAmount - (_sharesAlice + _sharesBob + _sharesCharlie), 1e5, "_letInvestorsDeposit: E12");

        assertEq(metaVault.maxDeposit(address(0)), 0, "_letInvestorsDeposit: E13");
        assertEq(metaVault.maxMint(address(0)), 0, "_letInvestorsDeposit: E14");
        assertEq(metaVault.totalAssets(), IERC20(address(metaVault.asset())).balanceOf(address(metaVault)), "_letInvestorsDeposit: E15");
        assertEq(metaVault.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie + _managerShares), "_letInvestorsDeposit: E16");

        return metaVault.totalAssets();
    }

    // call when vault is "unmanaged"
    function _managerAddCollateral(uint256 _amount) internal returns (uint256 _shares) {
        _dealERC20(address(metaVault.asset()), manager, _amount);
        uint256 _expectedShare = metaVault.previewDeposit(_amount);
        
        vm.startPrank(manager);
        IERC20(address(metaVault.asset())).approve(address(metaVault), _amount);
        _shares = metaVault.deposit(_amount, address(metaVault));
        vm.stopPrank();

        assertEq(metaVault.balanceOf(address(metaVault)), metaVault.convertToShares(_amount), "_managerAddCollateral: E1");
        assertEq(metaVault.balanceOf(address(metaVault)), _expectedShare, "_managerAddCollateral: E2");
    }

    // call when vault is "unmanaged" + epoch is initiated + asset were added
    function _startEpoch() internal {
        assertEq(metaVault.isEpochinitiated(), true, "_testStartEpoch: E1");
        assertEq(metaVault.isUnmanaged(), true, "_testInitVault: E2");

        vm.startPrank(manager);

        if (metaVault.timelockStartTimestamp() + metaVault.timelockDuration() > block.timestamp) {
            vm.expectRevert();
            metaVault.startEpoch();

            uint256 _timeLeft = metaVault.timelockStartTimestamp() + metaVault.timelockDuration() - block.timestamp;
            skip(_timeLeft);
        }

        metaVault.startEpoch();

        vm.stopPrank();

        assertEq(metaVault.isUnmanaged(), false, "_testInitVault: E8");
        assertEq(metaVault.snapshotSharesSupply(), metaVault.totalSupply(), "_testInitVault: E9");
        assertEq(metaVault.snapshotAssetBalance(), metaVault.totalAssets(), "_testInitVault: E10");
        assertEq(metaVault.isEpochinitiated(), true, "_testInitVault: E11");
        assertEq(metaVault.isTimelockInitiated(), false, "_testInitVault: E12");
    }

    // call when vault is "managed" + epoch is initiated + assets were deposited into meta vault
    // _assetVaultAddress should be the associated _asset's AssetVault address
    function _depositToAssetsVault(address _assetVaultAddress, address _asset, uint256 _amount) internal returns (uint256 _amountIn) {
        assertEq(metaVault.isUnmanaged(), false, "_testManageAssetsVaults: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_testManageAssetsVaults: E2");
        assertEq(metaVault.blacklistedAssets(_asset), false, "_testManageAssetsVaults: E3");
        assertTrue(metaVault.assetVaults(_asset) != address(0), "_testManageAssetsVaults: E4");
        assertEq(metaVault.assetVaults(_asset), _assetVaultAddress, "_testManageAssetsVaults: E5");
        assertTrue(IERC20(address(metaVault.asset())).balanceOf(address(metaVault)) > 0, "_testManageAssetsVaults: E6");
        assertTrue(IERC20(address(metaVault.asset())).balanceOf(address(metaVault)) >= _amount, "_testManageAssetsVaults: E6");

        AssetVault _assetVault = AssetVault(_assetVaultAddress);
        assertEq(IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress), 0, "_testManageAssetsVaults: E7");

        uint256 _before = IERC20(address(metaVault.asset())).balanceOf(address(metaVault));
        vm.prank(manager);
        _amountIn = metaVault.depositAsset(_asset, _amount, 0);

        assertEq(IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress), _amountIn, "_testManageAssetsVaults: E8");
        assertEq(IERC20(address(metaVault.asset())).balanceOf(address(metaVault)), _before - _amount, "_testManageAssetsVaults: E9");

        return _amountIn;
    }

    function _initiateStrategy(address _strategyAsset, address _assetVaultAddress, address _strategy) internal {
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(metaVault.isUnmanaged(), true, "_testManageAssetsVaults: E1");
        assertEq(_assetVault.isTimelocked(), false, "_testManageAssetsVaults: E2");
        assertEq(IStrategy(_strategy).isActive(), false, "_testManageAssetsVaults: E3");
        assertEq(IStrategy(_strategy).isAssetEnabled(_assetVault.getAsset()), true, "_testManageAssetsVaults: E4");
        assertEq(metaVault.assetVaults(_strategyAsset), _assetVaultAddress, "_testManageAssetsVaults: E5");

        vm.prank(manager);
        _assetVault.initiateStrategy(_strategy);

        assertEq(_assetVault.isTimelocked(), true, "_testManageAssetsVaults: E6");
        assertEq(_assetVault.initiatedStrategy(), _strategy, "_testManageAssetsVaults: E7");
        assertEq(_assetVault.timelock(), block.timestamp, "_testManageAssetsVaults: E8");
    }

    function _addStrategy(address _assetVaultAddress, address _strategy) internal {
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(_assetVault.isTimelocked(), true, "_testManageAssetsVaults: E1");
        assertEq(_assetVault.timelock() + _assetVault.timelockDuration() > block.timestamp, true, "_testManageAssetsVaults: E2");
        assertEq(_assetVault.initiatedStrategy(), _strategy, "_testManageAssetsVaults: E3");
        assertEq(_assetVault.blacklistedStrategies(_strategy), false, "_testManageAssetsVaults: E4");
        assertEq(IStrategy(_strategy).isAssetEnabled(_assetVault.getAsset()), true, "_testManageAssetsVaults: E5");
        assertEq(_assetVault.strategies(_strategy), false, "_testManageAssetsVaults: E6");

        skip(_assetVault.timelockDuration());

        vm.prank(manager);
        _assetVault.addStrategy();

        assertEq(_assetVault.isTimelocked(), false, "_testManageAssetsVaults: E7");
        assertEq(_assetVault.strategies(_strategy), true, "_testManageAssetsVaults: E8");
        assertEq(IStrategy(_strategy).isActive(), false, "_testManageAssetsVaults: E9");
        assertEq(_assetVault.strategyList(_assetVault.getStratagiesLength() - 1), _strategy, "_testManageAssetsVaults: E10");
    }

    function _depositToStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal {
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(metaVault.isUnmanaged(), false, "_testManageAssetsVaults: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_testManageAssetsVaults: E2");
        assertEq(_assetVault.blacklistedStrategies(_strategy), false, "_testManageAssetsVaults: E3");
        assertEq(IStrategy(_strategy).isActive(), false, "_testManageAssetsVaults: E4");
        assertEq(IStrategy(_strategy).isAssetEnabled(_assetVault.getAsset()), true, "_testManageAssetsVaults: E5");
        assertEq(_assetVault.strategies(_strategy), true, "_testManageAssetsVaults: E6");
        assertTrue(IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress) >= _amount, "_testManageAssetsVaults: E7");

        uint256 _before = IERC20(_assetVault.getAsset()).balanceOf(_strategy);
        vm.prank(manager);
        _assetVault.depositToStrategy(_strategy, _amount);
        uint256 _after = IERC20(_assetVault.getAsset()).balanceOf(_strategy);

        assertEq(IERC20(_assetVault.getAsset()).balanceOf(address(_strategy)), _after - _before, "_testManageAssetsVaults: E8");
    }

    function _withdrawFromStrategy(address _assetVaultAddress, address _strategy, uint256 _amount) internal {
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(metaVault.isUnmanaged(), false, "_testManageAssetsVaults: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_testManageAssetsVaults: E2");
        assertEq(_assetVault.blacklistedStrategies(_strategy), false, "_testManageAssetsVaults: E3");
        assertEq(IStrategy(_strategy).isActive(), true, "_testManageAssetsVaults: E4");
        assertEq(IStrategy(_strategy).isAssetEnabled(_assetVault.getAsset()), true, "_testManageAssetsVaults: E5");
        assertEq(_assetVault.strategies(_strategy), true, "_testManageAssetsVaults: E6");
        assertTrue(IERC20(_assetVault.getAsset()).balanceOf(_strategy) >= _amount, "_testManageAssetsVaults: E7");

        uint256 _before = IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress);
        vm.prank(manager);
        _assetVault.withdrawFromStrategy(_strategy, _amount);
        uint256 _after = IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress);

        assertEq(IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress), _after - _before, "_testManageAssetsVaults: E8");
    }

    function _withdrawFromAssetVault(address _assetVaultAddress, uint256 _amount) internal {
        AssetVault _assetVault = AssetVault(_assetVaultAddress);

        assertEq(metaVault.isUnmanaged(), false, "_testManageAssetsVaults: E1");
        assertEq(metaVault.isEpochinitiated(), true, "_testManageAssetsVaults: E2");
        assertTrue(IERC20(_assetVault.getAsset()).balanceOf(_assetVaultAddress) >= _amount, "_testManageAssetsVaults: E3");

        uint256 _assetVaultBefore = IERC20(_assetVault.getAsset()).balanceOf(address(this));
        uint256 _metaVaultBefore = IERC20(address(metaVault.asset())).balanceOf(address(metaVault));
        vm.prank(manager);
        uint256 _amountOut = _assetVault.withdraw(_amount); // should be done from metavault withdrawAsset(address _asset, uint256 _amount, uint256 _minAmount)
        uint256 _assetVaultAfter = IERC20(_assetVault.getAsset()).balanceOf(address(this));
        uint256 _metaVaultAfter = IERC20(address(metaVault.asset())).balanceOf(address(metaVault));

        assertEq(IERC20(_assetVault.getAsset()).balanceOf(address(_assetVault)), _assetVaultAfter - _assetVaultBefore, "_testManageAssetsVaults: E4");
        assertEq(IERC20(address(metaVault.asset())).balanceOf(address(metaVault)), _metaVaultAfter - _metaVaultBefore, "_testManageAssetsVaults: E5");
        assertEq(IERC20(address(metaVault.asset())).balanceOf(address(metaVault)), _amountOut, "_testManageAssetsVaults: E6");
    }

    // function _manageStratagies

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

    function _addWETHUSDCRouteToSwap() internal {
        uint256[] memory _poolType1 = new uint256[](1);    
        address[] memory _poolAddress1 = new address[](1);
        address[] memory _fromList1 = new address[](1);
        address[] memory _toList1 = new address[](1);

        _poolType1[0] = 13;
        _poolAddress1[0] = address(0);

        // TODO 
        // vm.startPrank(fortressSwap.owner());
        vm.startPrank(address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc));

        // WETH --> USDC
        if (!(fortressSwap.routeExists(WETH, USDC))) {
            _fromList1[0] = WETH;
            _toList1[0] = USDC;

            fortressSwap.updateRoute(WETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // USDC --> WETH
        if (!(fortressSwap.routeExists(USDC, WETH))) {
            _fromList1[0] = USDC;
            _toList1[0] = WETH;

            fortressSwap.updateRoute(USDC, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        vm.stopPrank();
    }
}