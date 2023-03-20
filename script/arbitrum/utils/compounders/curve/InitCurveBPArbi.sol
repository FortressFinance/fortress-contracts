// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/curve/CurveArbiCompounder.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";

contract InitCurveBPArbi is InitBaseArbi {

    function _initializeCurveBP(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _ammOperations) public returns (address) {

        _initSwap(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------
        
        // vst/frax - 0
        // crvEURSUSD - 4
        uint256 _convexPid = 7;
        uint256 _poolType = 1; 
        address _asset = CRVBP_LP;
        // string memory _symbol = "fc2Pool";
        // string memory _name = "Fortress Compounding 2Pool";

        address[] memory _rewardAssets = new address[](1);
        _rewardAssets[0] = CRV;
        // _rewardAssets[1] = CVX;

        // NOTE - make sure the order of underlying assets is the same as in Curve contract (Backend requirment) 
        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = USDT;
        _underlyingAssets[1] = USDC;

        address _booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
        address _crvRewards = IConvexBoosterArbi(_booster).poolInfo(_convexPid).rewards;
        bytes memory _settingsConfig = abi.encode(curveStableDescription, address(_owner), address(_platform), address(_fortressSwap), address(_ammOperations));
        bytes memory _boosterConfig = abi.encode(_convexPid, _booster, _crvRewards, _rewardAssets);
        
        CurveArbiCompounder curveCompounder = new CurveArbiCompounder(ERC20(_asset), "Fortress Compounding 2Pool", "fc2Pool", _settingsConfig, _boosterConfig, _underlyingAssets, _poolType);
        
        // ------------------------- init registry -------------------------

        YieldOptimizersRegistry(_fortressArbiRegistry).registerAmmCompounder(true, address(curveCompounder), address(_asset));

        // ------------------------- whitelist in ammOperations -------------------------

        CurveArbiOperations(payable(_ammOperations)).updateWhitelist(address(curveCompounder), true);
        
        return address(curveCompounder);
    }

    function _initSwap(address _fortressSwap) internal {

        FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));

        // CRV --> USDC 
        if (!(_swap.routeExists(CRV, USDC))) {
            _poolType2[0] = 0;
            _poolType2[1] = 0;
            
            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = UNIV3_USDCWETH;
            
            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = USDC;

            _swap.updateRoute(CRV, USDC, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // CRV --> USDT
        if (!(_swap.routeExists(CRV, USDT))) {
            _poolType2[0] = 0;
            _poolType2[1] = 4;

            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = CURVE_TRICRYPTO;

            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = USDT;

            _swap.updateRoute(CRV, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ETH --> USDC
        if (!(_swap.routeExists(ETH, USDC))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(ETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> USDT
        if (!(_swap.routeExists(ETH, USDT))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(ETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }
    }
}
