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
        uint256 _oracleNormalization = 1e8; // 1^(18 + 18 - 8 + 18 - 18)
        address _rateContract = address(rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = address(owner);
        uint256 _maxLTV = 75000; // 75%
        uint256 _liquidationFee = 10000; // 10%
        
        lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, address(fortressSwap), _maxLTV, _liquidationFee);

        // _addUsdcFraxRouteToSwap();

        // --------------------------------- init pair ---------------------------------

        _testInitialize(address(lendingPair));
    }

    // NOTES
    // 1 - consider implementing a delay between users entering and existing a position

    // --------------------------------- tests ---------------------------------

    function testCorrectFlowUSDC() public {
        // vm.assume(_amount > 0.1 ether && _amount < 10 ether);
        uint256 _amount = 1 ether;

        _addUsdcFraxRouteToSwap();

        _testDepositLiquidity(address(lendingPair), _amount);

        _testLeveragePosition(address(lendingPair), FRAX);
    }

    // --------------------------------- internal functions ---------------------------------

    function _addUsdcFraxRouteToSwap() internal {
        vm.startPrank(owner);
        if (!(fortressSwap.routeExists(USDC, FRAX))) {
            uint256[] memory _poolType = new uint256[](1);
            address[] memory _poolAddress = new address[](1);
            address[] memory _fromList = new address[](1);
            address[] memory _toList = new address[](1);

            _poolType[0] = 2;
            
            _poolAddress[0] = CURVE_FRAXBP;

            _fromList[0] = USDC;
            
            _toList[0] = FRAX;

            fortressSwap.updateRoute(USDC, FRAX, _poolType, _poolAddress, _fromList, _toList);
        }
        vm.stopPrank();
    }
}