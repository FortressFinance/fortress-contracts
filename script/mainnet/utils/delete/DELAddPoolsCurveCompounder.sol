// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// import "src/compounders/curve/CurveCompounder.sol";

// import "./Addresses.sol";

// contract AddPoolsCurveCompounder is Addresses {
contract AddPoolsCurveCompounder{}
//     function addCurveCompounderPools(address _compounderAddress) public {

//         uint256 _convexPid;
//         // The type of the pool:
//         // 0 - 3Pool
//         // 1 - PlainPool
//         // 2 - CryptoV2Pool
//         // 3 - CrvMetaPool
//         // 4 - FraxMetaPool
//         // 5 - ETHPool
//         // 6 - ETHV2Pool
//         // 7 - Base3Pool
//         // 8 - FraxCryptoMetaPool
//         // 9 - 4Pool
//         uint256 _poolType;
//         uint256 _platformFeePercentage = 25000000; // 2.5%
//         uint256 _harvestBountyPercentage = 25000000; // 2.5%
//         // uint256 _withdrawFeePercentage = 10000000; // 1%
//         uint256 _withdrawFeePercentage = 1000000; // 0.1%
//         address _poolAddress;
//         address[] memory _rewardTokens2 = new address[](2);
//         address[] memory _rewardTokens3 = new address[](3);

//         CurveCompounder _curveCompounder = CurveCompounder(payable(_compounderAddress));

//         // ETH/stETH (https://curve.fi/steth)
//         _convexPid = 25;
//         _poolAddress = curveETHstETH;
//         _poolType = 5;
//         _rewardTokens3[0] = CVX;
//         _rewardTokens3[1] = CRV;
//         _rewardTokens3[2] = LDO;
    
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens3, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // 3Pool (https://curve.fi/3pool)
//         _convexPid = 9;
//         _poolAddress = CURVE_BP;
//         _poolType = 7;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // USDC/FRAX (https://curve.fi/fraxusdc)
//         _convexPid = 100;
//         _poolAddress = FRAX_BP;
//         _poolType = 1;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // FRAX/3CRV (https://curve.fi/frax)
//         _convexPid = 32;
//         _poolAddress = FRAX3CRV;
//         _poolType = 3;
//         _rewardTokens3[0] = CVX;
//         _rewardTokens3[1] = CRV;
//         _rewardTokens3[2] = FXS;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens3, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // TriCrypto2 (https://curve.fi/tricrypto2)
//         _convexPid = 38;
//         _poolAddress = TRICRYPTO;
//         _poolType = 0;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // sUSD/DAI/USDC/USDT (https://curve.fi/susdv2)
//         _convexPid = 4;
//         _poolAddress = sUSD4POOL;
//         _poolType = 9;
//         _rewardTokens3[0] = CVX;
//         _rewardTokens3[1] = CRV;
//         _rewardTokens3[2] = SNX;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens3, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // CRV/cvxCRV (https://curve.fi/factory/22)
//         _convexPid = 41;
//         _poolAddress = curveCRVcvxCRV;
//         _poolType = 1;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // CRV/ETH (https://curve.fi/crveth)
//         _convexPid = 61;
//         _poolAddress = curveETHCRV;
//         _poolType = 6;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // CVX/crvFRAX (https://curve.fi/factory-crypto/95)
//         _convexPid = 117;
//         _poolAddress = CVXFRAXBP;
//         _poolType = 8;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // TUSD/crvFRAX (https://curve.fi/factory/144)
//         _convexPid = 108;
//         _poolAddress = TUSDFRAXBP;
//         _poolType = 4;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // FPI/FRAX (https://curve.fi/factory-crypto/48)
//         _convexPid = 82;
//         _poolAddress = curveFRAXFPI;
//         _poolType = 2;
//         _rewardTokens2[0] = CVX;
//         _rewardTokens2[1] = CRV;
        
//         _curveCompounder.addPool(_convexPid, _poolAddress, _poolType, _rewardTokens2, _platformFeePercentage, _harvestBountyPercentage, _withdrawFeePercentage);

//         // rebBTC/wBTC (https://curve.fi/ren) - convex id 6

//         // renBTC/wBTC/sBTC (https://curve.fi/sbtc) - 7

//         // Curve.fi GUSD/3Crv (gusd3CRV) - 10

//         // ETH/sETH (https://curve.fi/seth) - 23

//         // cyDAI/cyUSDT/cyUSDC (https://curve.fi/ib) - 29

//         // LINK/sLINK (https://curve.fi/link) - 30 

//         // TUSD/3CRV (https://curve.fi/tusd) - 31

//         // LUSD/3CRV (https://curve.fi/lusd) - 33

//         // BUSD/3CRV (https://curve.fi/busdv2) - 34

//         // alUSD/3CRV (https://curve.fi/alusd) - 36

//         // MIM/3CRV (https://curve.fi/mim) - 40

//         // ibJPY/sJPY (https://curve.fi/factory/28) - 42

//         // inGBP/sGBP (https://curve.fi/factory/30) - 43

//         // ibAUD/sAUD (https://curve.fi/factory/29) - 44

//         // ibEUR/sEUR (https://curve.fi/factory/3) - 45

//         // ibCHF/sCHF (https://curve.fi/factory/31) - 46

//         // ibKRW/sKRW (https://curve.fi/factory/2) - 47

//         // alETH/ETH (https://curve.fi/factory/38) - 49

//         // ibBTC, wibBTC/renBTC/wBTC/sBTC (https://curve.fi/factory/60) - 53

//         // EURs/USDC (https://curve.fi/eursusd) - 54

//         // EURT/3CRV (https://curve.fi/eurtusd) - 55

//         // OUSD/3CRV (https://curve.fi/factory/9) - 56

//         // agEUR/EURt/EURs (https://curve.fi/factory/66) - 60

//         // DOLA/3CRV (https://curve.fi/factory/27) - 62

//         // RAI/3CRV (https://curve.fi/rai) -63

//         // CVX/ETH (https://curve.fi/cvxeth) - 64

//         // T/ETH (https://curve.fi/teth) - 67

//         // YFI/ETH (https://curve.fi/factory-crypto/8) - 68

//         // FEI/3CRV (https://curve.fi/factory/11) - 71

//         // FXS/cvxFXS (https://curve.fi/factory-crypto/18) - 72

//         // rETH/wstETH (https://curve.fi/factory/89) - 73

//         // BADGER/wBTC (https://curve.fi/factory-crypto/4) - 74

//         // PWRD/3CRV (https://curve.fi/factory/44) - 76

//         // pBTC/renBTC/wBTC/sBTC (https://curve.fi/factory/99) - 77

//         // BEAN/3CRV (https://curve.fi/factory/152) - 80

//         // SDT/ETH (https://curve.fi/factory-crypto/11) - 83

//         // KP3R/ETH (https://curve.fi/factory-crypto/39) - 90

//         // pUSD/3CRV (https://curve.fi/factory/113) - 91

//         // OHM/ETH (https://curve.fi/factory-crypto/21) - 92

//         // sdCRV/CRV (https://curve.fi/factory/109) - 93

//         // sdANG/ANG (https://curve.fi/factory/101) -94 

//         // STG/USDC (https://curve.fi/factory-crypto/37) - 95

//         // USDD/3CRV (https://curve.fi/factory/116) - 96

//         // sdFXS/FXS (https://curve.fi/factory/100) - 98

//         // TOKE/ETH (https://curve.fi/factory-crypto/55) - 99

//         // sUSD/crvFRAX (https://curve.fi/factory/136) - 101

//         // LUSD/crvFRAX (https://curve.fi/factory/137) - 102

//         // apeUSD/crvFRAX (https://curve.fi/factory/138) - 103

//         // GUSD/crvFRAX (https://curve.fi/factory/140) - 104

//         // BUSD/crvFRAX (https://curve.fi/factory/141) - 105

//         // alUSD/crvFRAX (https://curve.fi/factory/147) - 106
 
//         // USDD/crvFRAX (https://curve.fi/factory/135) - 107

//         // xFRAXTEMPLELP/UNIV2 (https://curve.fi/factory/127) - 109

//         // EUROc/3crv (https://curve.fi/euroc) - 110

//         // tBTC/renBTC/wBTC/sBTC (https://curve.fi/factory/41) - 111

//         // pUSD/crvFRAX (https://curve.fi/factory/174) - 114

//         // DOLA/crvFRAX (https://curve.fi/factory/176) - 115

//         // agEUR/crvFRAX (https://curve.fi/factory-crypto/93) - 116

//         // cvxCRV/crvFRAX (https://curve.fi/factory-crypto/97) - 118

//         // cvxFXS/crvFRAX (https://curve.fi/factory-crypto/94) - 119

//         // ALCX/crvFRAX (https://curve.fi/factory-crypto/96) - 120

//         // MAI/crvFRAX (https://curve.fi/factory/175) - 121
//         // cbETH/ETH () - 127
//         // frxETH/ETH () - 128
//     }
// }