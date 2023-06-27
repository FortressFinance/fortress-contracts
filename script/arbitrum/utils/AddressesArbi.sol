// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AddressesArbi {

    // ------------------------------------- tokens -------------------------------------
    
    // The address representing ETH in Curve V1.
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // The address of WBTC token.
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    // The address of USDT token.
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    // The address of USDC token.
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    // The address of FRAX token.
    address constant FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    // The address of CRV token.
    address constant CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;
    // The address of CVX token.
    address constant CVX = 0xb952A807345991BD529FDded05009F5e80Fe8F45;
    // The address of WETH token.
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // The address of LINK token.
    address constant LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    // The address of renBTC token.
    address constant RENBTC = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
    // The address of fsGLP (un-transferable) token.
    address constant fsGLP = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    // The address of sGLP token.
    address constant sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    // The address of wstETH token.
    address constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    // The address of Y2K token.
    address constant Y2K = 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f;

    // The address of BAL token.
    address constant BAL = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;
    // The address of AURA BAL token.
    address constant AURA = 0x223738a747383d6F9f827d95964e4d8E8AC754cE;
    
    
    // ------------------------------------- Curve LP Tokens -------------------------------------

    // The address of TriCrypto LP token (https://curve.fi/#/arbitrum/pools/tricrypto/deposit).
    address constant TRICRYPTO_LP = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;
    // The address of WBTC/renBTC LP token
    address constant WBTCRENBTC_LP = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
    // The address of USDC/FRAX LP token
    address constant FRAXBP_LP = 0xC9B8a3FDECB9D5b218d02555a8Baf332E5B740d5;
    // The address of USDC/USDT LP token
    address constant CRVBP_LP = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    // ------------------------------------- Curve Pools -------------------------------------

    // The address of TriCrypto pool (https://curve.fi/#/arbitrum/pools/tricrypto/deposit).
    address constant CURVE_TRICRYPTO = 0x960ea3e3C7FB317332d990873d354E18d7645590;
    // The address of WBTC/renBTC Curve pool
    address constant CURVE_WBTCRENBTC = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
    // The address of USDC/USDT Curve pool
    address constant CURVE_BP = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    // The address of USDC/FRAX Curve pool
    address constant CURVE_FRAXBP = 0xC9B8a3FDECB9D5b218d02555a8Baf332E5B740d5;

    // ------------------------------------- Sushi Pools -------------------------------------

    // The address of Sushi CRV/WETH pool
    address constant SUSHI_CRVWETH = 0xbe3B9c3700171183b2B3F827D8833212d0197a96;
    // The address of Sushi WBTC/WETH pool
    address constant SUSHI_WBTCWETH = 0x515e252b2b5c22b4b2b6Df66c2eBeeA871AA4d69;

    // ------------------------------------- Balancer Pools -------------------------------------

    // The address of Balancer wstETH/WETH pool
    address constant BALANCER_WSTETHWETH = 0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f;
    // The address of Balancer BAL/WETH pool
    address constant BALANCER_BALWETH = 0xcC65A812ce382aB909a11E434dbf75B34f1cc59D;

    // ------------------------------------- UniV3 Pools -------------------------------------

    // The address of CRV/WETH pool
    address constant UNIV3_CRVWETH = 0xBA80CEdE54Bf09f8160F7d6AD4a9d6ae3a9852d9;
    // The address of USDC/WETH pool
    address constant UNIV3_USDCWETH = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    // The address of LINK/WETH pool
    address constant UNIV3_LINKWETH = 0x468b88941e7Cc0B88c1869d68ab6b570bCEF62Ff;

    // ------------------------------------- GMX -------------------------------------
    
    // The address of LINK/WETH pool
    address constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;

    // ------------------------------------- oracles -------------------------------------

    // The address of Chainlink USD/USDC price feed
    address constant USD_USDC_FEED = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    // The address of Chainlink USD/FRAX price feed
    address constant USD_FRAX_FEED = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;

    // ------------------------------------- Fortress -------------------------------------

    // The address of FortressSwap contract.
    address constant FortressSwap = 0xBbF847A344ceBC46DD226dc2682A703ebe37eB9e;
    address constant FortressSwapV2 = 0xf3E720a128072A5832f32F8fF639f7813B6ab255;
    // The address of first FortressRegistry contract.
    address constant FortressRegistryV1 = 0x5D21D171b265E5212B3E673759C971537b6a0d01;
    // The address of fcGLP contract.
    address constant fcGLP = 0x86eE39B28A7fDea01b53773AEE148884Db311B46;
    // The address of fcTriCrypto contract.
    address constant fcTriCrypto = 0x32ED4f40ce345Eca65F24735Ad9D35c7fF3460E5;
    // The address of fc2Pool contract.
    address constant fc2Pool = 0xe16F15266cD00c418fB63e505361de32ce90Ac9f;
    // The address of fcFraxBP contract.
    address constant fcFraxBP = 0xe0Ef16f92DdC7f2AA3DADC0fDd3cdEd262Df03D6;
    //
    // address constant ammOperations = 0x860b5691C95a2698bAd732E88F95C2e947AA4aDB;
    //
    address constant yieldOptimizersRegistry = 0x03605C3A3dAf860774448df807742c0d0e49460C;
    address constant multiClaimer = 0x259c2B9F14Ef98620d529feEf6d0D22269fDfbeD;
    address constant fctrTriCryptofcGLP = 0x4cdEE506E9130f8A8947D80DCe1AbfDf0fa36fb5;
    address constant fctrFraxBPfcGLP = 0xA7C12b4B98E6A38c51B12668773DAe855DdDecf8;
}