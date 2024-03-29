// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

import "test/arbitrum/lending/BaseTest.sol";

contract TestFRAXfcGLPPair is BaseTest {

    FortressGLPOracle oracle;
    FortressLendingPair lendingPair;

    function setUp() public {
        _setUp();

        oracle = new FortressGLPOracle(address(owner));

        // --------------------------------- deploy pair ---------------------------------

        // USDC asset (1e18 precision), fcGLP collateral (1e18 precision)
        ERC20 _asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fcGLP); // collateral
        string memory _name = "Fortress FRAX/fcGLP Lending Pair";
        string memory _symbol = "fFRAX/fcGLP";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(oracle); // numerator oracle (1e18 precision)
        // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)
        uint256 _oracleNormalization = 1e8; // 1^(18 + 18 - 8 + 18 - 18)
        address _rateContract = address(rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = address(owner);
        uint256 _maxLTV = 75000; // 75%
        uint256 _liquidationFee = 10000; // 10%
        
        lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, address(fortressSwap), _maxLTV, _liquidationFee);

        // --------------------------------- init pair ---------------------------------

        _testInitialize(address(lendingPair));
    }

    // --------------------------------- tests ---------------------------------

    function testCorrectFlowFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 10 ether);

        (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) = _testDepositLiquidity(address(lendingPair), _amount);

        uint256 _totalCollateral = _testLeveragePosition(address(lendingPair), FRAX);

        _testClosePosition(address(lendingPair), FRAX, _totalAssetsAfter, _totalSupplyAfter, _totalCollateral);

        _testRemoveLiquidity(address(lendingPair));

        _testPlatformFee(address(lendingPair));

        _testUpdateSwap(address(lendingPair));

        _testUpdatePauseSettings(address(lendingPair));

        _testUpdateFee(address(lendingPair));

        _testUpdateOwner(address(lendingPair));
    }

    // fails on FRAX --> WETH swap slippage
    // function testCorrectFlowWETH(uint256 _amount) public {
    //     vm.assume(_amount > 0.1 ether && _amount < 10 ether);

    //     _addFraxWethRouteToSwap();

    //     (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) = _testDepositLiquidity(address(lendingPair), _amount);

    //     uint256 _totalCollateral = _testLeveragePosition(address(lendingPair), WETH);

    //     _testClosePosition(address(lendingPair), WETH, _totalAssetsAfter, _totalSupplyAfter, _totalCollateral);

    //     _testRemoveLiquidity(address(lendingPair));

    //     _testPlatformFee(address(lendingPair));

    //     _testUpdateSwap(address(lendingPair));

    //     _testUpdatePauseSettings(address(lendingPair));

    //     _testUpdateFee(address(lendingPair));

    //     _testUpdateOwner(address(lendingPair));
    // }

    // // --------------------------------- internal functions ---------------------------------

    function _addFraxWethRouteToSwap() internal {
        vm.startPrank(owner);

        if (!(fortressSwap.routeExists(FRAX, WETH))) {
            uint256[] memory _poolType = new uint256[](1);
            address[] memory _poolAddress = new address[](1);
            address[] memory _fromList = new address[](1);
            address[] memory _toList = new address[](1);

            _poolType[0] = 14;
            
            _poolAddress[0] = address(0);
            
            _fromList[0] = FRAX;
            
            _toList[0] = WETH;
            
            fortressSwap.updateRoute(FRAX, WETH, _poolType, _poolAddress, _fromList, _toList);
        }

        
        if (!(fortressSwap.routeExists(WETH, FRAX))) {
            uint256[] memory _poolType = new uint256[](1);
            address[] memory _poolAddress = new address[](1);
            address[] memory _fromList = new address[](1);
            address[] memory _toList = new address[](1);

            _poolType[0] = 14;
            
            _poolAddress[0] = address(0);
            
            _fromList[0] = WETH;
            
            _toList[0] = FRAX;
            
            fortressSwap.updateRoute(WETH, FRAX, _poolType, _poolAddress, _fromList, _toList);
        }
        
        vm.stopPrank();
    }
}