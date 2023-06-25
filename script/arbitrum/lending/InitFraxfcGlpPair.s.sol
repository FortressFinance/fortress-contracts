// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "script/arbitrum/utils/AddressesArbi.sol";

import {ERC20} from "@solmate/mixins/ERC4626.sol";

import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";

import {FortressLendingPair} from "src/shared/lending/FortressLendingPair.sol";
import {VariableInterestRate, IRateCalculator} from "src/shared/lending/VariableInterestRate.sol";
import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

contract InitFraxfcGlpPair is Script, AddressesArbi {

    IRateCalculator _rateCalculator;
    FortressLendingPair _lendingPair;
    FortressGLPOracle _fcGLPOracle;
    ERC20 _asset;

    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("GBC_DEPLOYER_PRIVATE_KEY");
        address deployer = vm.envAddress("GBC_DEPLOYER_ADDRESS");
        address owner = vm.envAddress("FORTRESS_MULTISIG_OWNER");

        vm.startBroadcast(deployerPrivateKey);

        _rateCalculator = new VariableInterestRate();
        _fcGLPOracle = new FortressGLPOracle(owner);

        // FRAX asset (1e18 precision), fcGLP collateral (1e18 precision)
        _asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fcGLP); // collateral
        string memory _name = "Fortress Lending FRAX/fcGLP Pair";
        string memory _symbol = "fFRAX/fcGLP";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(_fcGLPOracle); // numerator oracle (1e18 precision)
        // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)
        uint256 _oracleNormalization = 1e8; // 1^(18 + 18 - 8 + 18 - 18)
        address _rateContract = address(_rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = deployer;
        uint256 _maxLTV = 80000; // 80%
        uint256 _liquidationFee = 10000; // 10%
        
        _lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, FortressSwapV2, _maxLTV, _liquidationFee);

        bytes memory _rateInitCallData;
        _lendingPair.initialize(_rateInitCallData);

        _lendingPair.updateOwner(owner);

        console.log("============================================================");
        console.log("============================================================");
        console.log("_rateCalculator: ", address(_rateCalculator));
        console.log("_fcGLPOracle: ", address(_fcGLPOracle));
        console.log("_lendingPair: ", address(_lendingPair));
        console.log("============================================================");
        console.log("============================================================");

        vm.stopBroadcast();
    }
}

// ---- Notes ----

//   _rateCalculator:  0xea43a662841294bA9bBf45656B6d67c85093b319
//   _fcGLPOracle:  0x907F41f19D101e99bE967359740C66160D25281F
//   _lendingPair:  0x21dA5B5718ebce131071eD43D13483DD3C585F04

// forge script script/arbitrum/InitFraxfcGlpPair.s.sol:InitFraxfcGlpPair --rpc-url $RPC_URL --broadcast
// https://abi.hashex.org/ - for constructor
// forge flatten --output GlpCompounder.sol src/arbitrum/compounders/gmx/GlpCompounder.sol
// forge verify-contract --watch --chain-id 42161 --compiler-version v0.8.17+commit.8df45f5f --verifier-url https://api.arbiscan.io/api 0xB900A00418bbD1A1b7e1b00A960A22EA540918a2 src/shared/lending/FortressLendingPair.sol:FortressLendingPair
// --constructor-args $(cast abi-encode "constructor(address)" 0xBF73FEBB672CC5B8707C2D75cB49B0ee2e2C9DaA)