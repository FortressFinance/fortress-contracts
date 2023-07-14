// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";

import {InitTriCryptoGlp} from "script/arbitrum/utils/concentrators/curve/InitTriCryptoGlp.sol";
import {AMMConcentratorBase} from "src/shared/concentrators/AMMConcentratorBase.sol";
import {YieldOptimizersRegistry} from "src/shared/utils/YieldOptimizersRegistry.sol";

contract InitConcentrator is Script, AddressesArbi, InitTriCryptoGlp {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // address deployer = vm.envAddress("DEPLOYER");
        address owner = vm.envAddress("OWNER");
        // address platform = owner;

        // address ammOperations = 0x860b5691C95a2698bAd732E88F95C2e947AA4aDB;

        vm.startBroadcast(deployerPrivateKey);

        YieldOptimizersRegistry(yieldOptimizersRegistry).registerAmmConcentrator(true, fctrTriCryptofcGLP, fcGLP, TRICRYPTO_LP);

        vm.stopBroadcast();
    }
}

// forge script script/arbitrum/InitFortressArbi.s.sol:InitFortress --rpc-url $RPC_URL --broadcast
// forge verify-contract --watch --chain-id 42161 --compiler-version v0.8.17+commit.8df45f5f --verifier-url https://api.arbiscan.io/api 0xB900A00418bbD1A1b7e1b00A960A22EA540918a2 src/shared/lending/FortressLendingPair.sol:FortressLendingPair
// --constructor-args $(cast abi-encode "constructor(address)" 0xBF73FEBB672CC5B8707C2D75cB49B0ee2e2C9DaA)