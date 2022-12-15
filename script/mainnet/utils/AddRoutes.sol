// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/mainnet/utils/FortressSwap.sol";

import "./Addresses.sol";
import "./InitBase.sol";

contract AddRoutes is Addresses, InitBase {

    // pool type -->
    // 0: UniswapV3
    // 1: Fraxswap
    // 2: Curve2AssetPool
    // 3: _swapCurveCryptoV2
    // 4: Curve3AssetPool
    // 5: CurveETHV2Pool
    // 6: CurveCRVMeta
    // 7: CurveFraxMeta
    // 8: CurveBase3Pool
    // 9: CurveSBTCPool
    // 10: Curve4Pool
    // 11: FraxCryptoMeta
    // 12: BalancerSingleSwap
    // uint256[] _poolType1 = new uint256[](1);
    // uint256[] _poolType2 = new uint256[](2);
    // uint256[] _poolType3 = new uint256[](3);
    // uint256[] _poolType4 = new uint256[](4);
    
    // address[] _poolAddress1 = new address[](1);
    // address[] _poolAddress2 = new address[](2);
    // address[] _poolAddress3 = new address[](3);
    // address[] _poolAddress4 = new address[](4);

    // address[] _fromList1 = new address[](1);
    // address[] _fromList2 = new address[](2);
    // address[] _fromList3 = new address[](3);
    // address[] _fromList4 = new address[](4);
    
    // address[] _toList1 = new address[](1);
    // address[] _toList2 = new address[](2);
    // address[] _toList3 = new address[](3);
    // address[] _toList4 = new address[](4);
    
    function addRoutes(address _swapAddress) public {
        
        FortressSwap _fortressSwap = FortressSwap(payable(_swapAddress));
        
        // --------------------------------- to ETH ---------------------------------

        // stETH --> ETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHstETH;
        
        _fromList1[0] = stETH;
        
        _toList1[0] = ETH;

        _fortressSwap.updateRoute(stETH, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // pETH --> ETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHpETH;
        
        _fromList1[0] = pETH;
        
        _toList1[0] = ETH;

        _fortressSwap.updateRoute(pETH, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // frxETH --> ETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHfrxETH;
        
        _fromList1[0] = frxETH;
        
        _toList1[0] = ETH;

        _fortressSwap.updateRoute(frxETH, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // USDT --> ETH
        _poolType1[0] = 4;

        _poolAddress1[0] = TRICRYPTO;
        
        _fromList1[0] = USDT;
        
        _toList1[0] = ETH;

        _fortressSwap.updateRoute(USDT, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from ETH ---------------------------------

        // ETH --> pETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHpETH;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = pETH;

        _fortressSwap.updateRoute(ETH, pETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> frxETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHfrxETH;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = frxETH;

        _fortressSwap.updateRoute(ETH, frxETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> FIAT
        _poolType3[0] = 4;
        _poolType3[1] = 8;
        _poolType3[2] = 12;

        _poolAddress3[0] = TRICRYPTO;
        _poolAddress3[1] = CURVE_BP;
        _poolAddress3[2] = BALANCER_FIATUSDCDAI;

        _fromList3[0] = ETH;
        _fromList3[1] = USDT;
        _fromList3[2] = USDC;

        _toList3[0] = USDT;
        _toList3[1] = USDC;
        _toList3[2] = FIAT;

        _fortressSwap.updateRoute(ETH, FIAT, _poolType3, _poolAddress3, _fromList3, _toList3);

        // ETH --> pUSD
        _poolType2[0] = 4;
        _poolType2[1] = 6;

        _poolAddress2[0] = TRICRYPTO;
        _poolAddress2[1] = pUSD3CRV;

        _fromList2[0] = ETH;
        _fromList2[1] = USDT;

        _toList2[0] = USDT;
        _toList2[1] = pUSD;

        _fortressSwap.updateRoute(ETH, pUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> LDO
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3LDOETH;

        _fromList1[0] = ETH;

        _toList1[0] = LDO;

        _fortressSwap.updateRoute(ETH, LDO, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> CRV
        _poolType1[0] = 5;

        _poolAddress1[0] = curveETHCRV;

        _fromList1[0] = ETH;

        _toList1[0] = CRV;

        _fortressSwap.updateRoute(ETH, CRV, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> cvxCRV
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveCRVcvxCRV;

        _fromList2[0] = ETH;
        _fromList2[1] = CRV;

        _toList2[0] = CRV;
        _toList2[1] = cvxCRV;

        _fortressSwap.updateRoute(ETH, cvxCRV, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> CVX
        _poolType1[0] = 5;

        _poolAddress1[0] = curveETHCVX;

        _fromList1[0] = ETH;

        _toList1[0] = CVX;

        _fortressSwap.updateRoute(ETH, CVX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> wstETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHWSTETH;

        _fromList1[0] = ETH;

        _toList1[0] = wstETH;

        _fortressSwap.updateRoute(ETH, wstETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> sfrxETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHWSTETH;
        _poolAddress2[1] = BALANCER_3ETH;

        _fromList2[0] = ETH;
        _fromList2[1] = wstETH;

        _toList2[0] = wstETH;
        _toList2[1] = sfrxETH;

        _fortressSwap.updateRoute(ETH, sfrxETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> FXS
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3FXSETH;

        _fromList1[0] = ETH;

        _toList1[0] = FXS;

        _fortressSwap.updateRoute(ETH, FXS, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> cvxFXS
        _poolType2[0] = 0;
        _poolType2[1] = 3;

        _poolAddress2[0] = uniV3FXSETH;
        _poolAddress2[1] = curveFXScvxFXS;
        
        _fromList2[0] = ETH;
        _fromList2[1] = FXS;
        
        _toList2[0] = FXS;
        _toList2[1] = cvxFXS;
        
        _fortressSwap.updateRoute(ETH, cvxFXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> sdFXS
        _poolType2[0] = 0;
        _poolType2[1] = 2;

        _poolAddress2[0] = uniV3FXSETH;
        _poolAddress2[1] = curvesdFXSFXS;
        
        _fromList2[0] = ETH;
        _fromList2[1] = FXS;
        
        _toList2[0] = FXS;
        _toList2[1] = sdFXS;
        
        _fortressSwap.updateRoute(ETH, sdFXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> SPELL
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3SPELLETH;

        _fromList1[0] = ETH;

        _toList1[0] = SPELL;

        _fortressSwap.updateRoute(ETH, SPELL, _poolType1, _poolAddress1, _fromList1, _toList1);
        
        // ETH --> ALCX
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3ALCXETH;

        _fromList1[0] = ETH;

        _toList1[0] = ALCX;

        _fortressSwap.updateRoute(ETH, ALCX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> SNX
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3SNXETH;

        _fromList1[0] = ETH;

        _toList1[0] = SNX;

        _fortressSwap.updateRoute(ETH, SNX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> USDD
        _poolType2[0] = 4;
        _poolType2[1] = 6;

        _poolAddress2[0] = TRICRYPTO;
        _poolAddress2[1] = USDD3CRV;

        _fromList2[0] = ETH;
        _fromList2[1] = USDT;

        _toList2[0] = USDT;
        _toList2[1] = USDD;

        _fortressSwap.updateRoute(ETH, USDD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> USDC
        _poolType2[0] = 4;
        _poolType2[1] = 8;

        _poolAddress2[0] = TRICRYPTO;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = ETH;
        _fromList2[1] = USDT;
        
        _toList2[0] = USDT;
        _toList2[1] = USDC;
        
        _fortressSwap.updateRoute(ETH, USDC, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> DAI
        _poolType2[0] = 4;
        _poolType2[1] = 8;

        _poolAddress2[0] = TRICRYPTO;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = ETH;
        _fromList2[1] = USDT;
        
        _toList2[0] = USDT;
        _toList2[1] = DAI;
        
        _fortressSwap.updateRoute(ETH, DAI, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> rETH
        _poolType1[0] = 12;
        
        _poolAddress1[0] = BALANCER_RETHWETH;

        _fromList1[0] = ETH;
        
        _toList1[0] = rETH;
        
        _fortressSwap.updateRoute(ETH, rETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> USDT
        _poolType1[0] = 4;
        
        _poolAddress1[0] = TRICRYPTO;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = USDT;
        
        _fortressSwap.updateRoute(ETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> FRAX
        _poolType1[0] = 0;
        
        _poolAddress1[0] = uniV3FRAXETH;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = FRAX;
        
        _fortressSwap.updateRoute(ETH, FRAX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> stETH
        _poolType1[0] = 2;

        _poolAddress1[0] = curveETHstETH;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = stETH;

        _fortressSwap.updateRoute(ETH, stETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> wBTC
        _poolType1[0] = 4;

        _poolAddress1[0] = TRICRYPTO;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = wBTC;

        _fortressSwap.updateRoute(ETH, wBTC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ETH --> sUSD
        _poolType2[0] = 4;
        _poolType2[1] = 10;

        _poolAddress2[0] = TRICRYPTO;
        _poolAddress2[1] = sUSD4POOL;
        
        _fromList2[0] = ETH;
        _fromList2[1] = USDT;
        
        _toList2[0] = USDT;
        _toList2[1] = sUSD;

        _fortressSwap.updateRoute(ETH, sUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> LUSD
        _poolType2[0] = 0;
        _poolType2[1] = 7;

        _poolAddress2[0] = uniV3FRAXETH;
        _poolAddress2[1] = LUSDFRAXBP;
        
        _fromList2[0] = ETH;
        _fromList2[1] = FRAX;
        
        _toList2[0] = FRAX;
        _toList2[1] = LUSD;

        _fortressSwap.updateRoute(ETH, LUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> TUSD
        _poolType2[0] = 0;
        _poolType2[1] = 7;

        _poolAddress2[0] = uniV3FRAXETH;
        _poolAddress2[1] = TUSDFRAXBP;
        
        _fromList2[0] = ETH;
        _fromList2[1] = FRAX;
        
        _toList2[0] = FRAX;
        _toList2[1] = TUSD;

        _fortressSwap.updateRoute(ETH, TUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> FPI
        _poolType2[0] = 0;
        _poolType2[1] = 3;

        _poolAddress2[0] = uniV3FRAXETH;
        _poolAddress2[1] = curveFRAXFPI;

        _fromList2[0] = ETH;
        _fromList2[1] = FRAX;

        _toList2[0] = FRAX;
        _toList2[1] = FPI;

        _fortressSwap.updateRoute(ETH, FPI, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ETH --> BAL
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHBAL;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = BAL;

        _fortressSwap.updateRoute(ETH, BAL, _poolType1, _poolAddress1, _fromList1, _toList1);
        
        // ETH --> AURA
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHAURA;
        
        _fromList1[0] = ETH;
        
        _toList1[0] = AURA;

        _fortressSwap.updateRoute(ETH, AURA, _poolType1, _poolAddress1, _fromList1, _toList1);

        // WETH --> AURA
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHAURA;
        
        _fromList1[0] = WETH;
        
        _toList1[0] = AURA;

        _fortressSwap.updateRoute(WETH, AURA, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from CRV ---------------------------------

        // CRV --> ETH
        _poolType1[0] = 5;

        _poolAddress1[0] = curveETHCRV;

        _fromList1[0] = CRV;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(CRV, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // CRV --> CVX
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHCVX;

        _fromList2[0] = CRV;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = CVX;

        _fortressSwap.updateRoute(CRV, CVX, _poolType2, _poolAddress2, _fromList2, _toList2);
        
        // CRV --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHpETH;

        _fromList2[0] = CRV;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _fortressSwap.updateRoute(CRV, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> frxETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHfrxETH;

        _fromList2[0] = CRV;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = frxETH;

        _fortressSwap.updateRoute(CRV, frxETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        
        // CRV --> TUSD
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 7;

        _poolAddress4[0] = curveETHCRV;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = TUSDFRAXBP;

        _fromList4[0] = CRV;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = TUSD;

        _fortressSwap.updateRoute(CRV, TUSD, _poolType4, _poolAddress4, _fromList4, _toList4);

        // CRV --> LUSD
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 7;

        _poolAddress4[0] = curveETHCRV;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = LUSDFRAXBP;

        _fromList4[0] = CRV;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = LUSD;

        _fortressSwap.updateRoute(CRV, LUSD, _poolType4, _poolAddress4, _fromList4, _toList4);

        // CRV --> cvxCRV
        _poolType1[0] = 2;

        _poolAddress1[0] = curveCRVcvxCRV;

        _fromList1[0] = CRV;

        _toList1[0] = cvxCRV;

        _fortressSwap.updateRoute(CRV, cvxCRV, _poolType1, _poolAddress1, _fromList1, _toList1);

        // cvxCRV --> CRV
        _poolType1[0] = 2;

        _poolAddress1[0] = curveCRVcvxCRV;

        _fromList1[0] = cvxCRV;

        _toList1[0] = CRV;

        _fortressSwap.updateRoute(cvxCRV, CRV, _poolType1, _poolAddress1, _fromList1, _toList1);

        // CRV --> stETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHstETH;

        _fromList2[0] = CRV;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = stETH;

        _fortressSwap.updateRoute(CRV, stETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> USDC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = USDC;

        _fortressSwap.updateRoute(CRV, USDC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> USDT
        _poolType2[0] = 5;
        _poolType2[1] = 4;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = TRICRYPTO;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = USDT;
        
        _fortressSwap.updateRoute(CRV, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> DAI
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = DAI;

        _fortressSwap.updateRoute(CRV, DAI, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> FRAX
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = FRAX3CRV;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = FRAX;

        _fortressSwap.updateRoute(CRV, FRAX, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> MIM
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = MIM3CRV;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = MIM;

        _fortressSwap.updateRoute(CRV, MIM, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> alUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = alUSD3CRV;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = alUSD;

        _fortressSwap.updateRoute(CRV, alUSD, _poolType3, _poolAddress3, _fromList3, _toList3);
        
        // CRV --> pUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = pUSD3CRV;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = pUSD;

        _fortressSwap.updateRoute(CRV, pUSD, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> bUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = BUSD3CRV;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = BUSD;

        _fortressSwap.updateRoute(CRV, BUSD, _poolType3, _poolAddress3, _fromList3, _toList3);
        
        // CRV --> FXS
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = uniV3FXSETH;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = FXS;
        
        _fortressSwap.updateRoute(CRV, FXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> sdFXS
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 2;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = uniV3FXSETH;
        _poolAddress3[2] = curvesdFXSFXS;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = FXS;

        _toList3[0] = ETH;
        _toList3[1] = FXS;
        _toList3[2] = sdFXS;

        _fortressSwap.updateRoute(CRV, sdFXS, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> wBTC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 4;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = TRICRYPTO;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = wBTC;

        _fortressSwap.updateRoute(CRV, wBTC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> sBTC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 9;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = curveSBTC;

        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = wBTC;

        _toList3[0] = ETH;
        _toList3[1] = wBTC;
        _toList3[2] = sBTC;

        _fortressSwap.updateRoute(CRV, sBTC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> sETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHsETH;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = sETH;
        
        _fortressSwap.updateRoute(CRV, sETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> FPI
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 3;

        _poolAddress4[0] = curveETHCRV;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = curveFRAXFPI;

        _fromList4[0] = CRV;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = FPI;

        _fortressSwap.updateRoute(CRV, FPI, _poolType4, _poolAddress4, _fromList4, _toList4);

        // CRV --> OHM
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHOHM;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = OHM;
        
        _fortressSwap.updateRoute(CRV, OHM, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> JPEG
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHJPEG;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = JPEG;
        
        _fortressSwap.updateRoute(CRV, JPEG, _poolType2, _poolAddress2, _fromList2, _toList2);

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
        
        _fortressSwap.updateRoute(CRV, cvxFXS, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> LINK
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = uniV3LINKETH;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = LINK;
        
        _fortressSwap.updateRoute(CRV, LINK, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> sLINK
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 2;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = uniV3LINKETH;
        _poolAddress3[2] = curveLINKsLINK;
        
        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = LINK;
        
        _toList3[0] = ETH;
        _toList3[1] = LINK;
        _toList3[2] = sLINK;
        
        _fortressSwap.updateRoute(CRV, sLINK, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CRV --> alETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCRV;
        _poolAddress2[1] = curveETHalETH;
        
        _fromList2[0] = CRV;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = alETH;
        
        _fortressSwap.updateRoute(CRV, alETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CRV --> sUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 10;

        _poolAddress3[0] = curveETHCRV;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = sUSD4POOL;
        
        _fromList3[0] = CRV;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;
        
        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = sUSD;
        
        _fortressSwap.updateRoute(CRV, sUSD, _poolType3, _poolAddress3, _fromList3, _toList3);

        // --------------------------------- from CVX ---------------------------------

        // CVX --> ETH
        _poolType1[0] = 5;

        _poolAddress1[0] = curveETHCVX;

        _fromList1[0] = CVX;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(CVX, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // CVX --> CRV
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHCRV;

        _fromList2[0] = CVX;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = CRV;

        _fortressSwap.updateRoute(CVX, CRV, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> stETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHstETH;

        _fromList2[0] = CVX;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = stETH;

        _fortressSwap.updateRoute(CVX, stETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> USDC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = USDC;

        _fortressSwap.updateRoute(CVX, USDC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> TUSD
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 7;

        _poolAddress4[0] = curveETHCVX;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = TUSDFRAXBP;

        _fromList4[0] = CVX;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = TUSD;

        _fortressSwap.updateRoute(CVX, TUSD, _poolType4, _poolAddress4, _fromList4, _toList4);

        // CVX --> LUSD
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 7;

        _poolAddress4[0] = curveETHCVX;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = LUSDFRAXBP;

        _fromList4[0] = CVX;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = LUSD;

        _fortressSwap.updateRoute(CVX, LUSD, _poolType4, _poolAddress4, _fromList4, _toList4);
        
        // CVX --> USDT
        _poolType2[0] = 5;
        _poolType2[1] = 4;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = TRICRYPTO;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = USDT;
        
        _fortressSwap.updateRoute(CVX, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> DAI
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = DAI;

        _fortressSwap.updateRoute(CVX, DAI, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> FRAX
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = FRAX3CRV;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = FRAX;

        _fortressSwap.updateRoute(CVX, FRAX, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> MIM
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = MIM3CRV;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = MIM;

        _fortressSwap.updateRoute(CVX, MIM, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> alUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = alUSD3CRV;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = alUSD;

        _fortressSwap.updateRoute(CVX, alUSD, _poolType3, _poolAddress3, _fromList3, _toList3);
        
        // CVX --> pUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = pUSD3CRV;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = pUSD;

        _fortressSwap.updateRoute(CVX, pUSD, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> bUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = BUSD3CRV;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = BUSD;

        _fortressSwap.updateRoute(CVX, BUSD, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> FXS
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = uniV3FXSETH;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = FXS;
        
        _fortressSwap.updateRoute(CVX, FXS, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> wBTC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 4;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = TRICRYPTO;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;

        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = wBTC;

        _fortressSwap.updateRoute(CVX, wBTC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> sBTC
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 9;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = curveSBTC;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = wBTC;

        _toList3[0] = ETH;
        _toList3[1] = wBTC;
        _toList3[2] = sBTC;

        _fortressSwap.updateRoute(CVX, sBTC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> sETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHsETH;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = sETH;
        
        _fortressSwap.updateRoute(CVX, sETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> FPI
        _poolType4[0] = 5;
        _poolType4[1] = 4;
        _poolType4[2] = 6;
        _poolType4[3] = 3;

        _poolAddress4[0] = curveETHCVX;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = FRAX3CRV;
        _poolAddress4[3] = curveFRAXFPI;

        _fromList4[0] = CVX;
        _fromList4[1] = ETH;
        _fromList4[2] = USDT;
        _fromList4[3] = FRAX;

        _toList4[0] = ETH;
        _toList4[1] = USDT;
        _toList4[2] = FRAX;
        _toList4[3] = FPI;

        _fortressSwap.updateRoute(CVX, FPI, _poolType4, _poolAddress4, _fromList4, _toList4);

        // CVX --> OHM
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHOHM;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = OHM;
        
        _fortressSwap.updateRoute(CVX, OHM, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> JPEG
        _poolType2[0] = 5;
        _poolType2[1] = 5;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHJPEG;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = JPEG;
        
        _fortressSwap.updateRoute(CVX, JPEG, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHpETH;

        _fromList2[0] = CVX;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _fortressSwap.updateRoute(CVX, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> frxETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHfrxETH;

        _fromList2[0] = CVX;
        _fromList2[1] = ETH;

        _toList2[0] = ETH;
        _toList2[1] = frxETH;

        _fortressSwap.updateRoute(CVX, frxETH, _poolType2, _poolAddress2, _fromList2, _toList2);

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
        
        _fortressSwap.updateRoute(CVX, cvxFXS, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> sdFXS
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 2;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = uniV3FXSETH;
        _poolAddress3[2] = curvesdFXSFXS;

        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = FXS;

        _toList3[0] = ETH;
        _toList3[1] = FXS;
        _toList3[2] = sdFXS;

        _fortressSwap.updateRoute(CVX, sdFXS, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> LINK
        _poolType2[0] = 5;
        _poolType2[1] = 0;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = uniV3LINKETH;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = LINK;
        
        _fortressSwap.updateRoute(CVX, LINK, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> sLINK
        _poolType3[0] = 5;
        _poolType3[1] = 0;
        _poolType3[2] = 2;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = uniV3LINKETH;
        _poolAddress3[2] = curveLINKsLINK;
        
        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = LINK;
        
        _toList3[0] = ETH;
        _toList3[1] = LINK;
        _toList3[2] = sLINK;
        
        _fortressSwap.updateRoute(CVX, sLINK, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> alETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHCVX;
        _poolAddress2[1] = curveETHalETH;
        
        _fromList2[0] = CVX;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = alETH;
        
        _fortressSwap.updateRoute(CVX, alETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // CVX --> sUSD
        _poolType3[0] = 5;
        _poolType3[1] = 4;
        _poolType3[2] = 10;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = sUSD4POOL;
        
        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;
        
        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = sUSD;
        
        _fortressSwap.updateRoute(CVX, sUSD, _poolType3, _poolAddress3, _fromList3, _toList3);

        // CVX --> cvxCRV
        _poolType3[0] = 5;
        _poolType3[1] = 5;
        _poolType3[2] = 2;

        _poolAddress3[0] = curveETHCVX;
        _poolAddress3[1] = curveETHCRV;
        _poolAddress3[2] = curveCRVcvxCRV;
        
        _fromList3[0] = CVX;
        _fromList3[1] = ETH;
        _fromList3[2] = CRV;
        
        _toList3[0] = ETH;
        _toList3[1] = CRV;
        _toList3[2] = cvxCRV;
        
        _fortressSwap.updateRoute(CVX, cvxCRV, _poolType3, _poolAddress3, _fromList3, _toList3);

        // --------------------------------- from LDO ---------------------------------

        // LDO --> ETH
        _poolType1[0] = 0;

        _poolAddress1[0] = 0xf4aD61dB72f114Be877E87d62DC5e7bd52DF4d9B;

        _fromList1[0] = LDO;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(LDO, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // LDO --> stETH
        _poolType2[0] = 0;
        _poolType2[1] = 2;

        _poolAddress2[0] = 0xf4aD61dB72f114Be877E87d62DC5e7bd52DF4d9B;
        _poolAddress2[1] = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
        
        _fromList2[0] = LDO;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = stETH;

        _fortressSwap.updateRoute(LDO, stETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // --------------------------------- from SNX ---------------------------------

        // SNX --> DAI
        _poolType2[0] = 0;
        _poolType2[1] = 8;

        _poolAddress2[0] = uniV3SNXUSDC;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = SNX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = DAI;

        _fortressSwap.updateRoute(SNX, DAI, _poolType2, _poolAddress2, _fromList2, _toList2);

        // SNX --> USDC
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3SNXUSDC;

        _fromList1[0] = SNX;

        _toList1[0] = USDC;

        _fortressSwap.updateRoute(SNX, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // SNX --> USDT
        _poolType2[0] = 0;
        _poolType2[1] = 8;

        _poolAddress2[0] = uniV3SNXUSDC;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = SNX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = USDT;

        _fortressSwap.updateRoute(SNX, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // SNX --> sUSD
        _poolType2[0] = 0;
        _poolType2[1] = 10;

        _poolAddress2[0] = uniV3SNXUSDC;
        _poolAddress2[1] = sUSD4POOL;
        
        _fromList2[0] = SNX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = sUSD;

        _fortressSwap.updateRoute(SNX, sUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // --------------------------------- from USDD ---------------------------------

        // USDD --> DAI
        _poolType1[0] = 6;

        _poolAddress1[0] = USDD3CRV;

        _fromList1[0] = USDD;

        _toList1[0] = DAI;

        _fortressSwap.updateRoute(USDD, DAI, _poolType1, _poolAddress1, _fromList1, _toList1);
        
        // USDD --> USDC
        _poolType1[0] = 7;

        _poolAddress1[0] = USDDFRAXBP;

        _fromList1[0] = USDD;

        _toList1[0] = USDC;

        _fortressSwap.updateRoute(USDD, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // USDD --> USDT
        _poolType1[0] = 6;

        _poolAddress1[0] = USDD3CRV;

        _fromList1[0] = USDD;

        _toList1[0] = USDT;

        _fortressSwap.updateRoute(USDD, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from FXS ---------------------------------

        // FXS --> ETH
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3FXSETH;

        _fromList1[0] = FXS;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(FXS, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // FXS --> FRAX
        _poolType1[0] = 1;

        _poolAddress1[0] = address(0);

        _fromList1[0] = FXS;

        _toList1[0] = FRAX;

        _fortressSwap.updateRoute(FXS, FRAX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // FXS --> DAI
        _poolType2[0] = 1;
        _poolType2[1] = 6;

        _poolAddress2[0] = address(0);
        _poolAddress2[1] = FRAX3CRV;
        
        _fromList2[0] = FXS;
        _fromList2[1] = FRAX;
        
        _toList2[0] = FRAX;
        _toList2[1] = DAI;

        _fortressSwap.updateRoute(FXS, DAI, _poolType2, _poolAddress2, _fromList2, _toList2);
        
        // FXS --> USDC
        _poolType2[0] = 1;
        _poolType2[1] = 6;

        _poolAddress2[0] = address(0);
        _poolAddress2[1] = FRAX3CRV;
        
        _fromList2[0] = FXS;
        _fromList2[1] = FRAX;
        
        _toList2[0] = FRAX;
        _toList2[1] = USDC;

        _fortressSwap.updateRoute(FXS, USDC, _poolType2, _poolAddress2, _fromList2, _toList2);

        // FXS --> USDT
        _poolType2[0] = 1;
        _poolType2[1] = 6;

        _poolAddress2[0] = address(0);
        _poolAddress2[1] = FRAX3CRV;
        
        _fromList2[0] = FXS;
        _fromList2[1] = FRAX;
        
        _toList2[0] = FRAX;
        _toList2[1] = USDT;

        _fortressSwap.updateRoute(FXS, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // --------------------------------- from SPELL ---------------------------------

        // SPELL --> ETH
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3SPELLETH;

        _fromList1[0] = SPELL;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(SPELL, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // SPELL --> MIM
        _poolType3[0] = 0;
        _poolType3[1] = 4;
        _poolType3[2] = 6;

        _poolAddress3[0] = uniV3SPELLETH;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = MIM3CRV;
        
        _fromList3[0] = SPELL;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;
        
        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = MIM;
        
        _fortressSwap.updateRoute(SPELL, MIM, _poolType3, _poolAddress3, _fromList3, _toList3);

        // SPELL --> DAI
        _poolType3[0] = 0;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = uniV3SPELLETH;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;
        
        _fromList3[0] = SPELL;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;
        
        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = DAI;
        
        _fortressSwap.updateRoute(SPELL, DAI, _poolType3, _poolAddress3, _fromList3, _toList3);

        // SPELL --> USDC
        _poolType3[0] = 0;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = uniV3SPELLETH;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;
        
        _fromList3[0] = SPELL;
        _fromList3[1] = ETH;
        _fromList3[2] = USDT;
        
        _toList3[0] = ETH;
        _toList3[1] = USDT;
        _toList3[2] = USDC;
        
        _fortressSwap.updateRoute(SPELL, USDC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // SPELL --> USDT
        _poolType2[0] = 0;
        _poolType2[1] = 4;

        _poolAddress2[0] = uniV3SPELLETH;
        _poolAddress2[1] = TRICRYPTO;
        
        _fromList2[0] = SPELL;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = USDT;

        _fortressSwap.updateRoute(SPELL, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // --------------------------------- from ALCX ---------------------------------

        // ALCX --> ETH
        _poolType1[0] = 0;

        _poolAddress1[0] = uniV3ALCXETH;

        _fromList1[0] = ALCX;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(ALCX, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ALCX --> alUSD
        _poolType2[0] = 11;
        _poolType2[1] = 6;

        _poolAddress2[0] = ALCXFRAXBP;
        _poolAddress2[1] = alUSD3CRV;
        
        _fromList2[0] = ALCX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = alUSD;

        _fortressSwap.updateRoute(ALCX, alUSD, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ALCX --> DAI
        _poolType2[0] = 11;
        _poolType2[1] = 8;

        _poolAddress2[0] = ALCXFRAXBP;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = ALCX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = DAI;

        _fortressSwap.updateRoute(ALCX, DAI, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ALCX --> USDC
        _poolType1[0] = 11;

        _poolAddress1[0] = ALCXFRAXBP;

        _fromList1[0] = ALCX;

        _toList1[0] = USDC;

        _fortressSwap.updateRoute(ALCX, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // ALCX --> USDT
        _poolType2[0] = 11;
        _poolType2[1] = 8;

        _poolAddress2[0] = ALCXFRAXBP;
        _poolAddress2[1] = CURVE_BP;
        
        _fromList2[0] = ALCX;
        _fromList2[1] = USDC;
        
        _toList2[0] = USDC;
        _toList2[1] = USDT;

        _fortressSwap.updateRoute(ALCX, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);

        // USDC --> ALCX
        _poolType1[0] = 11;

        _poolAddress1[0] = ALCXFRAXBP;

        _fromList1[0] = USDC;

        _toList1[0] = ALCX;

        _fortressSwap.updateRoute(USDC, ALCX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from FRAX ---------------------------------

        // FRAX --> USDC
        _poolType1[0] = 6;

        _poolAddress1[0] = FRAX3CRV;

        _fromList1[0] = FRAX;

        _toList1[0] = USDC;

        _fortressSwap.updateRoute(FRAX, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // FRAX --> USDT
        _poolType1[0] = 6;

        _poolAddress1[0] = FRAX3CRV;

        _fromList1[0] = FRAX;

        _toList1[0] = USDT;

        _fortressSwap.updateRoute(FRAX, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);

        // FRAX --> DAI
        _poolType1[0] = 6;

        _poolAddress1[0] = FRAX3CRV;

        _fromList1[0] = FRAX;

        _toList1[0] = DAI;

        _fortressSwap.updateRoute(FRAX, DAI, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from TUSD ---------------------------------

        // TUSD --> FRAX
        _poolType1[0] = 7;

        _poolAddress1[0] = TUSDFRAXBP;

        _fromList1[0] = TUSD;

        _toList1[0] = FRAX;

        _fortressSwap.updateRoute(TUSD, FRAX, _poolType1, _poolAddress1, _fromList1, _toList1);

        // TUSD --> USDC
        _poolType1[0] = 7;

        _poolAddress1[0] = TUSDFRAXBP;

        _fromList1[0] = TUSD;

        _toList1[0] = USDC;

        _fortressSwap.updateRoute(TUSD, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);

        // --------------------------------- from JPEG ---------------------------------

        // JPEG --> ETH
        _poolType1[0] = 5;

        _poolAddress1[0] = curveETHJPEG;

        _fromList1[0] = JPEG;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(JPEG, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // JPEG --> pETH
        _poolType2[0] = 5;
        _poolType2[1] = 2;

        _poolAddress2[0] = curveETHJPEG;
        _poolAddress2[1] = curveETHpETH;
        
        _fromList2[0] = JPEG;
        _fromList2[1] = ETH;
        
        _toList2[0] = ETH;
        _toList2[1] = pETH;

        _fortressSwap.updateRoute(JPEG, pETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // ----------------------------------------------------------------------------
        // --------------------------------- Balancer ---------------------------------
        // ----------------------------------------------------------------------------

        // balancerETHBAL --> auraBAL
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_ETHBAL_AURABAL;

        _fromList1[0] = BALANCER_WETHBAL;

        _toList1[0] = auraBAL;

        _fortressSwap.updateRoute(BALANCER_WETHBAL, auraBAL, _poolType1, _poolAddress1, _fromList1, _toList1);

        // auraBAL --> balancerETHBAL
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_ETHBAL_AURABAL;

        _fromList1[0] = auraBAL;

        _toList1[0] = BALANCER_WETHBAL;

        _fortressSwap.updateRoute(auraBAL, BALANCER_WETHBAL, _poolType1, _poolAddress1, _fromList1, _toList1);

        // BAL --> ETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHBAL;
        
        _fromList1[0] = BAL;
        
        _toList1[0] = ETH;

        _fortressSwap.updateRoute(BAL, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // BAL --> WETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHBAL;

        _fromList1[0] = BAL;

        _toList1[0] = WETH;

        _fortressSwap.updateRoute(BAL, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
    
        // BAL --> AURA
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_WETHAURA;
        
        _fromList2[0] = BAL;
        _fromList2[1] = WETH;
        
        _toList2[0] = WETH;
        _toList2[1] = AURA;

        _fortressSwap.updateRoute(BAL, AURA, _poolType2, _poolAddress2, _fromList2, _toList2);

        // BAL --> wstETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_WETHWSTETH;

        _fromList2[0] = BAL;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = wstETH;

        _fortressSwap.updateRoute(BAL, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // BAL --> sfrxETH
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
        
        _fortressSwap.updateRoute(BAL, sfrxETH, _poolType3, _poolAddress3, _fromList3, _toList3);

        // AURA --> BAL
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_WETHBAL;
        
        _fromList2[0] = AURA;
        _fromList2[1] = WETH;
        
        _toList2[0] = WETH;
        _toList2[1] = BAL;

        _fortressSwap.updateRoute(AURA, BAL, _poolType2, _poolAddress2, _fromList2, _toList2);

        // AURA --> WETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHAURA;

        _fromList1[0] = AURA;

        _toList1[0] = WETH;

        _fortressSwap.updateRoute(AURA, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // AURA --> ETH
        _poolType1[0] = 12;

        _poolAddress1[0] = BALANCER_WETHAURA;

        _fromList1[0] = AURA;

        _toList1[0] = ETH;

        _fortressSwap.updateRoute(AURA, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);

        // AURA --> wstETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_WETHWSTETH;

        _fromList2[0] = AURA;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = wstETH;

        _fortressSwap.updateRoute(AURA, wstETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // AURA --> sfrxETH
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
        
        _fortressSwap.updateRoute(AURA, sfrxETH, _poolType3, _poolAddress3, _fromList3, _toList3);

        // AURA --> SNX
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_WETHSNX;

        _fromList2[0] = AURA;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = SNX;

        _fortressSwap.updateRoute(AURA, SNX, _poolType2, _poolAddress2, _fromList2, _toList2);

        // BAL --> SNX
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_WETHSNX;

        _fromList2[0] = BAL;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = SNX;

        _fortressSwap.updateRoute(BAL, SNX, _poolType2, _poolAddress2, _fromList2, _toList2);
        
        // BAL --> rETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHBAL;
        _poolAddress2[1] = BALANCER_RETHWETH;

        _fromList2[0] = BAL;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = rETH;

        _fortressSwap.updateRoute(BAL, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // AURA --> rETH
        _poolType2[0] = 12;
        _poolType2[1] = 12;

        _poolAddress2[0] = BALANCER_WETHAURA;
        _poolAddress2[1] = BALANCER_RETHWETH;

        _fromList2[0] = AURA;
        _fromList2[1] = WETH;

        _toList2[0] = WETH;
        _toList2[1] = rETH;

        _fortressSwap.updateRoute(AURA, rETH, _poolType2, _poolAddress2, _fromList2, _toList2);

        // BAL --> USDC
        _poolType3[0] = 12;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = BALANCER_WETHBAL;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = BAL;
        _fromList3[1] = WETH;
        _fromList3[2] = USDT;

        _toList3[0] = WETH;
        _toList3[1] = USDT;
        _toList3[2] = USDC;

        _fortressSwap.updateRoute(BAL, USDC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // BAL --> DAI
        _poolType3[0] = 12;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = BALANCER_WETHBAL;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = BAL;
        _fromList3[1] = WETH;
        _fromList3[2] = USDT;

        _toList3[0] = WETH;
        _toList3[1] = USDT;
        _toList3[2] = DAI;

        _fortressSwap.updateRoute(BAL, DAI, _poolType3, _poolAddress3, _fromList3, _toList3);

        // BAL --> FIAT
        _poolType4[0] = 12;
        _poolType4[1] = 4;
        _poolType4[2] = 8;
        _poolType4[3] = 12;

        _poolAddress4[0] = BALANCER_WETHBAL;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = CURVE_BP;
        _poolAddress4[3] = BALANCER_FIATUSDCDAI;

        _fromList4[0] = BAL;
        _fromList4[1] = WETH;
        _fromList4[2] = USDT;
        _fromList4[3] = USDC;

        _toList4[0] = WETH;
        _toList4[1] = USDT;
        _toList4[2] = USDC;
        _toList4[3] = FIAT;

        _fortressSwap.updateRoute(BAL, FIAT, _poolType4, _poolAddress4, _fromList4, _toList4);

        // AURA --> USDC
        _poolType3[0] = 12;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = BALANCER_WETHAURA;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = AURA;
        _fromList3[1] = WETH;
        _fromList3[2] = USDT;

        _toList3[0] = WETH;
        _toList3[1] = USDT;
        _toList3[2] = USDC;

        _fortressSwap.updateRoute(AURA, USDC, _poolType3, _poolAddress3, _fromList3, _toList3);

        // AURA --> DAI
        _poolType3[0] = 12;
        _poolType3[1] = 4;
        _poolType3[2] = 8;

        _poolAddress3[0] = BALANCER_WETHAURA;
        _poolAddress3[1] = TRICRYPTO;
        _poolAddress3[2] = CURVE_BP;

        _fromList3[0] = AURA;
        _fromList3[1] = WETH;
        _fromList3[2] = USDT;

        _toList3[0] = WETH;
        _toList3[1] = USDT;
        _toList3[2] = DAI;

        _fortressSwap.updateRoute(AURA, DAI, _poolType3, _poolAddress3, _fromList3, _toList3);

        // AURA --> FIAT
        _poolType4[0] = 12;
        _poolType4[1] = 4;
        _poolType4[2] = 8;
        _poolType4[3] = 12;

        _poolAddress4[0] = BALANCER_WETHAURA;
        _poolAddress4[1] = TRICRYPTO;
        _poolAddress4[2] = CURVE_BP;
        _poolAddress4[3] = BALANCER_FIATUSDCDAI;

        _fromList4[0] = AURA;
        _fromList4[1] = WETH;
        _fromList4[2] = USDT;
        _fromList4[3] = USDC;

        _toList4[0] = WETH;
        _toList4[1] = USDT;
        _toList4[2] = USDC;
        _toList4[3] = FIAT;

        _fortressSwap.updateRoute(AURA, FIAT, _poolType4, _poolAddress4, _fromList4, _toList4);
    }
}