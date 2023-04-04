// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import {BaseTest, ERC20, SafeERC20, IERC20} from "test/arbitrum/concentrators/BaseTest.sol";

// import "src/shared/lending/FortressLendingPair.sol";

// contract TestLendingPair is BaseTest {

//     function setUp() public {
//         _setUp();
//     }

//     function testSanity() public {
//         assertTrue(true);

//         // ERC20 _asset, string memory _name, string memory _symbol, bytes memory _configData, address _owner, uint256 _maxLTV, uint256 _liquidationFee
//         ERC20 _asset = ERC20(address(USDC));
//         string memory _name = "Fortress USDC/fcGLP Lending Pair";
//         string memory _symbol = "fUSDC/fcGLP";
//         address _oracleMultiply = address(USD_USDC_FEED);
//         address _oracleDivide = address(USD_fcGLP_FEED); // todo
//         uint256 _oracleNormalization = 1e18; // todo - wrong decimals
//         address _rateContract = address(0); // todo
//         // (address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract,)
//         //     = abi.decode(_configData, (address, address, address, uint256, address, bytes));
//         bytes memory _configData = abi.encode(fcGLP, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
//         address _owner = address(owner);
//         uint256 _maxLTV = 75000; // 75%
//         uint256 _liquidationFee = 10000; // 10%
//         FortressLendingPair _lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, _maxLTV, _liquidationFee);
//     }
// }