// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/mainnet/compounders/balancer/BalancerCompounder.sol";
import "script/mainnet/utils/InitBase.sol";
import "src/mainnet/utils/FortressSwap.sol";
import "src/mainnet/utils/FortressRegistry.sol";

contract InitThreeETH is InitBase {
    
    function _initializeThreeETH(address _owner, address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // ETH --> rETH
        if (!(_swap.routeExists(ETH, rETH))) {
            _poolType1[0] = 12;
        
            _poolAddress1[0] = BALANCER_RETHWETH;

            _fromList1[0] = ETH;
            
            _toList1[0] = rETH;
            
            _swap.updateRoute(ETH, rETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // BAL --> rETH
        if (!(_swap.routeExists(BAL, rETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_WETHBAL;
            _poolAddress2[1] = BALANCER_RETHWETH;

            _fromList2[0] = BAL;
            _fromList2[1] = WETH;

            _toList2[0] = WETH;
            _toList2[1] = rETH;

            _swap.updateRoute(BAL, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // AURA --> rETH
        if (!(_swap.routeExists(AURA, rETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_WETHAURA;
            _poolAddress2[1] = BALANCER_RETHWETH;

            _fromList2[0] = AURA;
            _fromList2[1] = WETH;

            _toList2[0] = WETH;
            _toList2[1] = rETH;

            _swap.updateRoute(AURA, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ETH --> sfrxETH
        if (!(_swap.routeExists(ETH, sfrxETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_WETHWSTETH;
            _poolAddress2[1] = BALANCER_3ETH;

            _fromList2[0] = ETH;
            _fromList2[1] = wstETH;

            _toList2[0] = wstETH;
            _toList2[1] = sfrxETH;

            _swap.updateRoute(ETH, sfrxETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // BAL --> sfrxETH
        if (!(_swap.routeExists(BAL, sfrxETH))) {
            _poolType3[0] = 12;
            _poolType3[1] = 12;
            _poolType3[2] = 12;

            _poolAddress3[0] = BALANCER_WETHBAL;
            _poolAddress3[1] = BALANCER_WETHWSTETH;
            _poolAddress3[2] = BALANCER_3ETH;
            
            _fromList3[0] = BAL;
            _fromList3[1] = WETH;
            _fromList3[2] = wstETH;
            
            _toList3[0] = WETH;
            _toList3[1] = wstETH;
            _toList3[2] = sfrxETH;
            
            _swap.updateRoute(BAL, sfrxETH, _poolType3, _poolAddress3, _fromList3, _toList3);
        }

        // AURA --> sfrxETH
        if (!(_swap.routeExists(AURA, sfrxETH))) {
            _poolType3[0] = 12;
            _poolType3[1] = 12;
            _poolType3[2] = 12;

            _poolAddress3[0] = BALANCER_WETHAURA;
            _poolAddress3[1] = BALANCER_WETHWSTETH;
            _poolAddress3[2] = BALANCER_3ETH;
            
            _fromList3[0] = AURA;
            _fromList3[1] = WETH;
            _fromList3[2] = wstETH;
            
            _toList3[0] = WETH;
            _toList3[1] = wstETH;
            _toList3[2] = sfrxETH;
            
            _swap.updateRoute(AURA, sfrxETH, _poolType3, _poolAddress3, _fromList3, _toList3);
        }

        // ETH --> wstETH
        if (!(_swap.routeExists(ETH, wstETH))) {
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_WETHWSTETH;

            _fromList1[0] = ETH;

            _toList1[0] = wstETH;

            _swap.updateRoute(ETH, wstETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // BAL --> wstETH
        if (!(_swap.routeExists(BAL, wstETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_WETHBAL;
            _poolAddress2[1] = BALANCER_WETHWSTETH;

            _fromList2[0] = BAL;
            _fromList2[1] = WETH;

            _toList2[0] = WETH;
            _toList2[1] = wstETH;

            _swap.updateRoute(BAL, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // AURA --> wstETH
        if (!(_swap.routeExists(AURA, wstETH))) {
            _poolType2[0] = 12;
            _poolType2[1] = 12;

            _poolAddress2[0] = BALANCER_WETHAURA;
            _poolAddress2[1] = BALANCER_WETHWSTETH;

            _fromList2[0] = AURA;
            _fromList2[1] = WETH;

            _toList2[0] = WETH;
            _toList2[1] = wstETH;

            _swap.updateRoute(AURA, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ------------------------- init WETH/rETH compounder -------------------------
        
        uint256 _convexPid = 13;
        address _asset = BALANCER_3ETH;
        string memory _symbol = "fortress-b3ETH";
        string memory _name = "Fortress Balancer sfrxETH-stETH-rETH";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = sfrxETH;
        _underlyingAssets[1] = rETH;
        _underlyingAssets[2] = wstETH;

        BalancerCompounder balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);

        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);

        return address(balancerCompounder);
    }
}