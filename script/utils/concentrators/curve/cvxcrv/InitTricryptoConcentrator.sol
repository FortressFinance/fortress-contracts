// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/concentrators/curve/CvxCrvConcentrator.sol";

import "src/utils/FortressRegistry.sol";
import "src/utils/FortressSwap.sol";
import "script/utils/InitBase.sol";

contract InitTricryptoConcentrator is InitBase {

    function _initTricryptoConcentrator(address _fortressRegistry, address _fortressSwap, address _platform, address _compounder) public returns (address) {
        
        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // CVX --> CRV
        if (!(_swap.routeExists(CVX, CRV))) { 
            _poolType2[0] = 5;
            _poolType2[1] = 5;

            _poolAddress2[0] = curveETHCVX;
            _poolAddress2[1] = curveETHCRV;

            _fromList2[0] = CVX;
            _fromList2[1] = ETH;

            _toList2[0] = ETH;
            _toList2[1] = CRV;

            _swap.updateRoute(CVX, CRV, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ------------------------- init Tricrypto cvxCRV Concentrator -------------------------
        
        _boosterPoolId = 38;
        _poolType = 0;
        _asset = TRICRYPTOLP;
        _symbol = "fortress-cTricrypto";
        _name = "Fortress Curve Tricrypto";

        _rewardAssets2[0] = CRV;
        _rewardAssets2[1] = CVX;

        _underlyingAssets3[0] = USDT;
        _underlyingAssets3[1] = wBTC;
        _underlyingAssets3[2] = WETH;

        CvxCrvConcentrator cvxCrvConcentrator = new CvxCrvConcentrator(ERC20(_asset), _name, _symbol, _platform, address(_fortressSwap), _boosterPoolId, _rewardAssets2, _underlyingAssets3, _compounder, _poolType);
        
        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerCurveCvxCrvConcentrator(address(cvxCrvConcentrator), _asset, _symbol, _name, _underlyingAssets3, _compounder);

        return address(cvxCrvConcentrator);
    }
}