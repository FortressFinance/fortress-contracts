// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/mainnet/compounders/balancer/BalancerCompounder.sol";
import "script/mainnet/utils/InitBase.sol";
import "src/mainnet/utils/FortressSwap.sol";
import "src/mainnet/utils/FortressRegistry.sol";

contract InitWETHwstETH is InitBase {
    
    function _initializeWETHwstETH(address _owner, address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // ETH --> wstETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHWSTETH;

        _fromList1[0] = ETH;

        _toList1[0] = wstETH;

        _swap.updateRoute(ETH, wstETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // BAL --> wstETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_WETHWSTETH;

        _fromList2[0] = BAL;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = wstETH;

        _swap.updateRoute(BAL, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // AURA --> wstETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_WETHWSTETH;

        _fromList2[0] = AURA;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = wstETH;

        _swap.updateRoute(AURA, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ------------------------- init cvxFXS/FXS compounder -------------------------
        
        uint256 _convexPid = 29;
        address _asset = BALANCER_WETHWSTETH;
        string memory _symbol = "fortress-bwstETH";
        string memory _name = "Fortress Balancer wstETH/WETH";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = wstETH;
        _underlyingAssets[1] = WETH;

        BalancerCompounder balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);

        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);
    
        return address(balancerCompounder);
    }
}