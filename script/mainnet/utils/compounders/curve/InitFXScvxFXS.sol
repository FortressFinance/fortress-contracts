// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/mainnet/compounders/curve/CurveCompounder.sol";
import "script/mainnet/utils/InitBase.sol";
import "src/mainnet/utils/FortressSwap.sol";
import "src/mainnet/utils/FortressRegistry.sol";

contract InitFXScvxFXS is InitBase {
    
    function _initializeFXScvxFXS(address _owner, address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {
        
        _initSwapcvxFXS(_fortressSwap);

        // ------------------------- init cvxFXS/FXS compounder -------------------------

        uint256 _convexPid = 72;
        uint256 _poolType = 2;
        address _asset = cvxFXSFXS_f;
        string memory _symbol = "fortress-ccvxFXS";
        string memory _name = "Fortress Curve cvxFXS/FXS";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = FXS;
        _underlyingAssets[1] = cvxFXS;

        CurveCompounder curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);

        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);

        return address(curveCompounder);
    }

    function _initSwapcvxFXS(address _fortressSwap) internal {
        
        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // ETH --> FXS
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3FXSETH;

        _fromList1[0] = ETH;

        _toList1[0] = FXS;

        _swap.updateRoute(ETH, FXS, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> cvxFXS
        _poolType2[0] = 0;
        _poolType2[1] = 3;

        _poolAddress2[0] = uniV3FXSETH;
        _poolAddress2[1] = curveFXScvxFXS;
        
        _fromList2[0] = ETH;
        _fromList2[1] = FXS;
        
        _toList2[0] = FXS;
        _toList2[1] = cvxFXS;
        
        _swap.updateRoute(ETH, cvxFXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> FXS
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = uniV3FXSETH;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = FXS;
        
        _swap.updateRoute(CRV, FXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> cvxFXS
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 3;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = uniV3FXSETH;
        _poolAddress3[2] = curveFXScvxFXS;
        
        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = FXS;
        
        _toList3[0] = ETH;
        _toList3[1] = FXS;
        _toList3[2] = cvxFXS;
        
        _swap.updateRoute(CRV, cvxFXS, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> FXS
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = uniV3FXSETH;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = FXS;
        
        _swap.updateRoute(CVX, FXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> cvxFXS
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 3;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = uniV3FXSETH;
        _poolAddress3[2] = curveFXScvxFXS;
        
        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = FXS;
        
        _toList3[0] = ETH;
        _toList3[1] = FXS;
        _toList3[2] = cvxFXS;
        
        _swap.updateRoute(CVX, cvxFXS, _poolType3, _poolAddress3, _fromList3, _toList3);
    }
}