// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "script/arbitrum/utils/AddressesArbi.sol";

import {ERC20} from "@solmate/mixins/ERC4626.sol";

import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";


import {FortressLendingPair} from "src/shared/lending/FortressLendingPair.sol";
import {VariableInterestRate, IRateCalculator} from "src/shared/lending/VariableInterestRate.sol";
import {FortressWstETHwETHOracle} from "src/shared/lending/oracles/FortressWstETHwETHOracle.sol";

import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";

contract InitFraxfcwstETHwETHPair is Script, AddressesArbi, InitBaseArbi {

    IRateCalculator _rateCalculator;
    FortressLendingPair _lendingPair;
    FortressWstETHwETHOracle _fcWstETHwETHOracle;
    ERC20 __asset;

    function run() public {
        

        uint256 deployerPrivateKey = vm.envUint("GBC_DEPLOYER_PRIVATE_KEY");
        address deployer = vm.envAddress("GBC_DEPLOYER_ADDRESS");
        address owner = vm.envAddress("FORTRESS_MULTISIG_OWNER");

        vm.startBroadcast(deployerPrivateKey);

        _rateCalculator = new VariableInterestRate();
        _fcWstETHwETHOracle = new FortressWstETHwETHOracle(owner,address(fcwstETHwETH));

        // FRAX asset (1e18 precision), fcwstETHwETH collateral (1e18 precision)
        __asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fcwstETHwETH); // collateral
        string memory _name = "Fortress Lending FRAX/fcWstETHwETH Pair";
        string memory _symbol = "fFRAX/fcWstETHwETH";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(_fcWstETHwETHOracle); // numerator oracle (1e18 precision)
        // oracle normalization 1^(18 - precision of numerator oracle + precision of denominator oracle + precision of asset token - precision of collateral token)
        uint256 _oracleNormalization = 1e8; // 1^(18 - 18 + 8 + 18 - 18)
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
        console.log("_fcWstETHwETHOracle: ", address(_fcWstETHwETHOracle));
        console.log("_lendingPair: ", address(_lendingPair));
        console.log("============================================================");
        console.log("============================================================");

        vm.stopBroadcast();
    }

}