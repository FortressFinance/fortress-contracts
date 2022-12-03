// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/compounders/balancer/BalancerCompounder.sol";
import "script/utils/InitBase.sol";
import "src/utils/FortressSwap.sol";
import "src/utils/FortressRegistry.sol";

contract InitWETHrETH is InitBase {
    
    function _initializeWETHrETH(address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // ETH --> rETH
        _poolType1[0] = 12;
        
        _poolAddress1[0] = BALANCER_RETHWETH;

        _fromList1[0] = ETH;
        
        _toList1[0] = rETH;
        
        _swap.updateRoute(ETH, rETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // BAL --> rETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_RETHWETH;

        _fromList2[0] = BAL;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = rETH;

        _swap.updateRoute(BAL, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // AURA --> rETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_RETHWETH;

        _fromList2[0] = AURA;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = rETH;

        _swap.updateRoute(AURA, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ------------------------- init WETH/rETH compounder -------------------------
        
        uint256 _convexPid = 21;
        address _asset = BALANCER_RETHWETH;
        string memory _symbol = "fortress-brETH";
        string memory _name = "Fortress Balancer rETH/WETH";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = rETH;
        _underlyingAssets[1] = WETH;

        BalancerCompounder balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);

        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);

        return address(balancerCompounder);
    }
}