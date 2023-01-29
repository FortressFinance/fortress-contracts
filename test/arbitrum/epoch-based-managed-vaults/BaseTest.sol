// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/arbitrum/epoch-based-managed-vaults/MetaVault.sol";

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


    // ------------------- CORRECT FLOWS -------------------

    function _testInitVault() internal {
        uint256 _epochEndTimestamp = uint256(block.timestamp) + 1000000;
        uint256 _managerPerformanceFee = 20;
        uint256 _vaultWithdrawFee = 5;
        uint256 _collateralRequirement = 100;
        bool _isPenaltyEnabled = true;
        bool _isPerformanceFeeEnabled = true;
        bool _isCollateralRequired = true;

        bytes memory _configData = abi.encodePacked(
            _epochEndTimestamp, _managerPerformanceFee, _vaultWithdrawFee, _collateralRequirement, _isPenaltyEnabled, _isPerformanceFeeEnabled, _isCollateralRequired
        );
        
        vm.startPrank(manager);
        metaVault.initiateVault(_configData);
        vm.stopPrank();
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



}