// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

import "test/arbitrum/lending/BaseTest.sol";

contract TestUSDCfcGLPPair is BaseTest {

    FortressGLPOracle oracle;
    FortressLendingPair lendingPair;

    function setUp() public {
        _setUp();

        oracle = new FortressGLPOracle(address(owner));

        // --------------------------------- deploy pair ---------------------------------

        // USDC asset (1e18 precision), fcGLP collateral (1e18 precision)
        ERC20 _asset = ERC20(address(USDC)); // asset
        address _collateral = address(fcGLP); // collateral
        string memory _name = "Fortress USDC/fcGLP Lending Pair";
        string memory _symbol = "fUSDC/fcGLP";
        address _oracleMultiply = address(USD_USDC_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(oracle); // numerator oracle (1e18 precision)
        uint256 _oracleNormalization = 1e28; // 1^(18 + 18 - 8 + 18 - 18)
        address _rateContract = address(rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = address(owner);
        uint256 _maxLTV = 75000; // 75%
        uint256 _liquidationFee = 10000; // 10%
        
        lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, _maxLTV, _liquidationFee);

        // --------------------------------- init pair ---------------------------------

        // _testInitialize(address(lendingPair));
    }

    // -- Dual Oracle --
    // 
    // Asset MKR is 1e18
    // Collateral WBTC 1e8
    // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    // ETH MKR Feed ==> ETH/MKR (returns ETH per MKR) --> MKR already at denomminator --> ETH/MKR will be oracleMultiply
    // ETH BTC Feed ==> ETH/WBTC (returns ETH per WBTC) --> WBTC also at denomminator, but we want it at numerator  --> ETH/WBTC will be oracleDivide
    // rate = ETHMKRFeed / ETHWBTCFeed --> WBTC/MKR
    // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)

    // -- Dual Oracle --
    //
    // Asset USDC is 1e18
    // Collateral fcGLP 1e18
    // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    // USD USDC Feed ==> USD/USDC (returns USD per USDC) --> USDC already at denomminator --> USD/USDC will be oracleMultiply
    // USD fcGLP Feed ==> USD/fcGLP (returns USD per fcGLP) --> fcGLP also at denomminator, but we want it at numerator  --> USD/fcGLP will be oracleDivide
    // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)

    // NOTES
    // 1 - consider implementing a delay between users entering and existing a position
    // 101757704720708598950851302
    // 982716741444437407

    function testSanity() public {
        assertTrue(true);
        _testInitialize(address(lendingPair));
    }
}