// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/compounders/curve/CurveCompounder.sol";
import "script/utils/InitBase.sol";
import "src/utils/FortressSwap.sol";
import "src/utils/FortressRegistry.sol";

contract InitPETH is InitBase {
    
    function _initializePETH(address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // pETH --> ETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHpETH;
        
        _fromList1[0] = pETH;
        
        _toList1[0] = ETH;

        _swap.updateRoute(pETH, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> pETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHpETH;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = pETH;

        _swap.updateRoute(ETH, pETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // CRV --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHpETH;

        _fromList2[0] = CRV;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _swap.updateRoute(CRV, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHpETH;

        _fromList2[0] = CVX;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _swap.updateRoute(CVX, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // JPEG --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHJPEG;
        _poolAddress2[1] = curveETHpETH;
        
        _fromList2[0] = JPEG;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _swap.updateRoute(JPEG, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ------------------------- init pETH compounder -------------------------
        
        uint256 _convexPid = 122;
        uint256 _poolType = 5;
        address _asset = pETH_ETH_f;
        string memory _symbol = "fortress-cpETH";
        string memory _name = "Fortress Curve pETH";

        address[] memory _rewardAssets = new address[](3);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        _rewardAssets[2] = JPEG;

        // NOTE - make sure the order of underlying assets is the same as in Curve contract (Backend requirment) 
        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = pETH;
        _underlyingAssets[1] = ETH;

        CurveCompounder curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        
        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);

        return address(curveCompounder);
    }
}