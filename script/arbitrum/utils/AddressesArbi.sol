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

    // The address of Sushi wstETH/WETH pool
    address constant BALANCER_WSTETHWETH = 0xFB5e6d0c1DfeD2BA000fBC040Ab8DF3615AC329c;

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

    // ------------------------------------- Fortress -------------------------------------

    // The address of first FortressSwap contract.
    address constant FortressSwapV1 = 0xd2DA200a79AbC6526EABACF98F8Ea4C26F34796F;

    // The address of first FortressRegistry contract.
    address constant FortressRegistryV1 = 0x5D21D171b265E5212B3E673759C971537b6a0d01;
}