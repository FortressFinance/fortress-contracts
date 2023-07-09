// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "script/arbitrum/utils/AddressesArbi.sol";

import {ERC20} from "@solmate/mixins/ERC4626.sol";

import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";


import {FortressLendingPair} from "src/shared/lending/FortressLendingPair.sol";
import {VariableInterestRate, IRateCalculator} from "src/shared/lending/VariableInterestRate.sol";
import {FortressTriCryptoOracle} from "src/shared/lending/oracles/FortressTriCryptoOracle.sol";

import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";

contract InitFraxfcTriCryptoPair is Script, AddressesArbi, InitBaseArbi {

    IRateCalculator _rateCalculator;
    FortressLendingPair _lendingPair;
    FortressTriCryptoOracle _fcTriCryptoOracle;
    ERC20 __asset;

    function run() public {
        

        uint256 deployerPrivateKey = vm.envUint("GBC_DEPLOYER_PRIVATE_KEY");
        address deployer = vm.envAddress("GBC_DEPLOYER_ADDRESS");
        address owner = vm.envAddress("FORTRESS_MULTISIG_OWNER");

        vm.startBroadcast(deployerPrivateKey);

        _rateCalculator = new VariableInterestRate();
        _fcTriCryptoOracle = new FortressTriCryptoOracle(owner,address(fcTriCrypto));

        // FRAX asset (1e18 precision), fcTriCrypto collateral (1e18 precision)
        __asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fcTriCrypto); // collateral
        string memory _name = "Fortress Lending FRAX/fcTriCrypto Pair";
        string memory _symbol = "fFRAX/fcTriCrypto";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(_fcTriCryptoOracle); // numerator oracle (1e6 precision) (fcTriCrypto contract's ```decimals``` is faulty)
        // oracle normalization 1^(18 - precision of numerator oracle + precision of denominator oracle + precision of asset token - precision of collateral token)
        uint256 _oracleNormalization = 1e20; // 1^(18 - 6 + 8 + 18 - 18)
        address _rateContract = address(_rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = deployer;
        uint256 _maxLTV = 80000; // 80%
        uint256 _liquidationFee = 10000; // 10%
        
        _lendingPair = new FortressLendingPair(__asset, _name, _symbol, _configData, _owner, FortressSwapV2, _maxLTV, _liquidationFee);

        bytes memory _rateInitCallData;
        _lendingPair.initialize(_rateInitCallData);

        _lendingPair.updateOwner(owner);

        console.log("============================================================");
        console.log("============================================================");
        console.log("_rateCalculator: ", address(_rateCalculator));
        console.log("_fcTriCryptoPOracle: ", address(_fcTriCryptoOracle));
        console.log("_lendingPair: ", address(_lendingPair));
        console.log("============================================================");
        console.log("============================================================");

        vm.stopBroadcast();
    }

    // ---- Notes ----

    //     _rateCalculator:  0xB2f8801d3942cCA2Cc088Ffdc84368A36F1cebE2
    //   _fcTriCryptoPOracle:  0x779823E3bE15a07a91473C0ac6634170b36eb63a
    //   _lendingPair:  0x6a3e946B83fDD9b2B6650D909332C42397FF774f
}