// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/balancer/BalancerArbiCompounder.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/BalancerArbiOperations.sol";

contract InitWstETHwETHArbi is InitBaseArbi {

    function _initializeWstETHwETH(address _owner, address _yieldOptimizersRegistry, address _fortressSwap, address _platform, address _ammOperations) public returns (address) {

        _initSwapWstETHwETH(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------
        
        uint256 _convexPid = 0;
        address _asset = BALANCER_WSTETHWETH; 
        
        address[] memory _rewardAssets = new address[](1);
        _rewardAssets[0] = BAL;
        // _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = WSTETH;
        _underlyingAssets[1] = WETH;
        _underlyingAssets[2] = ETH;

        address _booster = address(0x98Ef32edd24e2c92525E59afc4475C1242a30184);
        address _crvRewards = IConvexBoosterArbi(_booster).poolInfo(_convexPid).crvRewards; 
        bytes memory _settingsConfig = abi.encode(balancerCryptoDescription, address(_owner), address(_platform), address(_fortressSwap), address(_ammOperations));
        bytes memory _boosterConfig = abi.encode(_convexPid, _booster, _crvRewards, _rewardAssets);

        BalancerArbiCompounder balancerCompounder = new BalancerArbiCompounder(ERC20(_asset), "Fortress Compounding wstETH-WETH", "fcWstETHwETh", _settingsConfig, _boosterConfig, _underlyingAssets);

        // // ------------------------- init registry -------------------------

        YieldOptimizersRegistry(_yieldOptimizersRegistry).registerAmmCompounder(false, address(balancerCompounder), address(_asset));

        // // ------------------------- whitelist in ammOperations -------------------------

        BalancerArbiOperations(payable(_ammOperations)).updateWhitelist(address(balancerCompounder), true); 
        
        return address(balancerCompounder);
    }

     function _initSwapWstETHwETH(address _fortressSwap) internal {

        FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));
        
        // BAL ->  WETH 
        if (!(_swap.routeExists(BAL, WETH))) {
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_BALWETH;
            
            _fromList1[0] = BAL;
            
            _toList1[0] = WETH;
            
            _swap.updateRoute(BAL, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // BAL ->  ETH 
        if (!(_swap.routeExists(BAL, ETH))) {
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_BALWETH;
            
            _fromList1[0] = BAL;
            
            _toList1[0] = ETH;
            
            _swap.updateRoute(BAL, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // BAL ->  WSTETH 
        if (!(_swap.routeExists(BAL, WSTETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_BALWETH;
            _poolAddress2[1] = BALANCER_WSTETHWETH;

            _fromList2[0] = BAL;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = WSTETH;
            
            _swap.updateRoute(BAL, WSTETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ETH ->  WSTETH 
        if (!(_swap.routeExists(ETH, WSTETH))) {
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_WSTETHWETH;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = WSTETH;
            
            _swap.updateRoute(ETH, WSTETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }
        
     }
}
