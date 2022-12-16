// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "src/concentrators/balancer/BalancerAuraBALConcentrator.sol";

// import "./Addresses.sol";

// contract AddPoolsBalancerAuraBALConcentrator is Addresses {
contract AddPoolsBalancerAuraBALConcentrator{}
//     function addBalancerAuraBALConcentratorPools(address _compounderAddress) public {
        
//         uint256 _convexPid;
//         uint256 _platformFeePercentage = 25000000; // 2.5%
//         uint256 _harvestBountyPercentage = 25000000; // 2.5%
//         // uint256 _withdrawFeePercentage = 25000000; // 10%
//         uint256 _withdrawFeePercentage = 1000000; // 0.1%
//         // address _poolAddress;
//         address[] memory _rewardTokens2 = new address[](2);
//         // address[] memory _rewardTokens3 = new address[](3);

//         BalancerAuraBALConcentrator _blancerAuraBALConcentrator = BalancerAuraBALConcentrator(_compounderAddress);

//         // ETH/AURA (https://info.balancer.xeonus.io/#/pools/0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274)
//         _convexPid = 20;
//         // _poolAddress = BALANCER_ETHAURA;
//         _rewardTokens2[0] = BAL;
//         _rewardTokens2[1] = AURA;
    
//         _blancerAuraBALConcentrator.addPool(_convexPid, _rewardTokens2, _withdrawFeePercentage, _platformFeePercentage, _harvestBountyPercentage);
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