// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "src/mainnet/concentrators/balancer/AuraBalConcentrator.sol";
// import "src/mainnet/utils/FortressSwap.sol";
// import "src/mainnet/utils/FortressRegistry.sol";
// import "script/mainnet/utils/Addresses.sol";

// import "script/mainnet/utils/InitBase.sol";
contract InitWETHAURAConcentrator {}
// contract InitWETHAURAConcentrator is InitBase {

//     function _initWETHAURAConcentrator(address _owner, address _fortressRegistry, address _fortressSwap, address _platform, address _compounder) public returns (address) {

//         // ------------------------- init fortress swap -------------------------

//         FortressSwap _swap = FortressSwap(payable(_fortressSwap));

//         // AURA --> BAL
//         if (!(_swap.routeExists(AURA, BAL))) {
//             _poolType2[0] = 12;
//             _poolType2[1] = 12;

//             _poolAddress2[0] = BALANCER_WETHAURA;
//             _poolAddress2[1] = BALANCER_WETHBAL;

//             _fromList2[0] = AURA;
//             _fromList2[1] = WETH;

//             _toList2[0] = WETH;
//             _toList2[1] = BAL;

//             _swap.updateRoute(AURA, BAL, _poolType2, _poolAddress2, _fromList2, _toList2);
//         }

//         // ------------------------- init WETH/AURA compounder -------------------------
        
//         _boosterPoolId = 0;
//         _asset = BALANCER_WETHAURA;
//         _symbol = "fortress-bWETHAURA";
//         _name = "Fortress Balancer WETH/AURA";

//         _rewardAssets2[0] = BAL;
//         _rewardAssets2[1] = AURA;

//         _underlyingAssets2[0] = WETH;
//         _underlyingAssets2[1] = AURA;

//         AuraBalConcentrator auraBalConcentrator = new AuraBalConcentrator(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _boosterPoolId, _rewardAssets2, _underlyingAssets2, _compounder);

//         // ------------------------- init registry -------------------------

//         FortressRegistry(_fortressRegistry).registerBalancerAuraBalConcentrator(address(auraBalConcentrator), _asset, _symbol, _name, _underlyingAssets2, _compounder);

//         return address(auraBalConcentrator);
//     }
// }

// // Balancer USD Stable Pool (staBAL3) - 0
// // Balancer 50 SNX 50 WETH (B-50SNX-5...) - 1
// // Balancer 60 WETH 40 DAI (B-60WETH-...) - 2
// // Balancer stETH Stable Pool (B-stETH-S...) - 3
// // Balancer Aave Boosted StablePool (... bb-a-USD) - 4
// // Balancer 30 FEI 70 WETH (B-30FEI-7...) - 5
// // Balancer 50 USDC 50 WETH (B-50USDC-...) - 6
// // Balancer 50 WBTC 50 WETH (B-50WBTC-...) - 7
// // Balancer 80 LDO 20 WETH (B-80LDO-2...) - 8
// // Balancer 80 GNO 20 WETH (B-80GNO-2...) - 9
// // 20WETH-80WNCG (20WETH-80...) - 10
// // 20WBTC-80BADGER (20WBTC-80...) - 11
// // Balancer 50 WETH 50 YFI (B-50WETH-...) - 12
// // 50DFX-50WETH (50DFX-50W...) - 13
// // CREAM (CREAM_ETH) - 14
// // USDC-PAL (USDC-PAL) - 15
// // 33auraBAL-33graviAURA-33WETH (33auraBAL...) - 16
// // FIAT-USDC-DAI Stable Pool (FUD) - 17
// // 40WBTC-40DIGG-20graviAURA (40WBTC-40...) - 18
// // Balancer auraBAL Stable Pool (B-auraBAL...) - 19
// // 50WETH-50AURA (50WETH-50...) - 20
// // Balancer rETH Stable Pool (B-rETH-ST...) - 21
// // 50COW-50WETH BPT (50COW-50W...) - 22
// // 50COW-50GNO BPT (50COW-50G...) - 23
// // 20WETH-80FDT (20WETH-80...) - 24
// // Balancer sdBAL Stable Pool (B-sdBAL-S...) - 25
// // 20DAI-80TCR (20DAI-80T...) - 26
// // 80TEMPLE-20DAI (80TEMPLE-...) - 27
// // 80D2D-20USDC (80D2D-20U...) - 28
// // 50WETH-50FOLD (50WETH-50...) - 29
// // 50OHM-25DAI-25WETH (50OHM-25D...) - 30
// // 20WETH-80WNCG (20WETH-80...) - 31
// // Balancer 50 COMP 50 WETH (B-50COMP-...) - 32
// // 20WBTC-80BADGER (20WBTC-80...) - 33
// // 40WBTC-40DIGG-20graviAURA (40WBTC-40...) - 34
// // Balancer 50wstETH-50LDO (50WSTETH-...) - 35
// // Balancer 50rETH-50RPL (50rETH-50...) - 36
// // 50INV-50DOLA (50INV-50D...) - 37
// // 80TEMPLE-20DAI (80TEMPLE-...) - 38
// //  MAI-USDC StablePool (MAI-USDC-...) - 39
// // 50Silo-50WETH (50Silo-50...) - 40
// // Balancer Aave Boosted StablePool (bb-a-USD) - 41
// // 50COW-50GNO BPT (50COW-50G...) - 42
// // 50COW-50WETH BPT (50COW-50W...) - 43
// // 20WETH-80FDT (20WETH-80...) - 44
// // 50DFX-50WETH (50DFX-50W...) - 45
// // USDC-PAL (USDC-PAL) - 46
// // 20DAI-80TCR (20DAI-80T...) - 47
// // 80D2D-20USDC (80D2D-20U...) - 48