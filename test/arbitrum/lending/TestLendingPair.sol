// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/BaseTest.sol";

import "src/shared/lending/FortressLendingPair.sol";

contract TestLendingPair is BaseTest {

    function setUp() public {
        _setUp();
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
    // 2 - consider implementing a implementing a spread limit to fcGLP exchange rate (i.e. if price of fcGLP is bigger than X% of the price of GLP - make sure the spread % needs to be updated)
    
    function testSanity() public {
        assertTrue(true);

        // ERC20 _asset, string memory _name, string memory _symbol, bytes memory _configData, address _owner, uint256 _maxLTV, uint256 _liquidationFee
        ERC20 _asset = ERC20(address(USDC));
        string memory _name = "Fortress USDC/fcGLP Lending Pair";
        string memory _symbol = "fUSDC/fcGLP";
        address _oracleMultiply = address(USD_USDC_FEED);
        address _oracleDivide = address(USD_fcGLP_FEED); // todo
        uint256 _oracleNormalization = 1e18; // todo - wrong decimals
        address _rateContract = address(0); // todo
        // (address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract,)
        //     = abi.decode(_configData, (address, address, address, uint256, address, bytes));
        bytes memory _configData = abi.encode(fcGLP, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        address _owner = address(owner);
        uint256 _maxLTV = 75000; // 75%
        uint256 _liquidationFee = 10000; // 10%
        FortressLendingPair _lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, _maxLTV, _liquidationFee);
    }
}