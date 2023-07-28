// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FortressWstETHwETHOracle} from "src/shared/lending/oracles/FortressWstETHwETHOracle.sol";

import "test/arbitrum/lending/BaseTest.sol";
import "script/arbitrum/lending/InitFraxfcwstETHwETHPair.s.sol";


contract TestFRAXfcWstETHwETHPair is BaseTest, InitFraxfcwstETHwETHPair {

    FortressWstETHwETHOracle oracle;
    FortressLendingPair lendingPair;

    function setUp() public {
        _setUp();
        _addFraxWethRouteToSwap();

        oracle = new FortressWstETHwETHOracle(address(owner),address(fcwstETHwETH));

        // --------------------------------- deploy pair ---------------------------------
        ERC20 _asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fcwstETHwETH); // collateral
        string memory _name = "Fortress Lending FRAX/fcWstETHwETH Pair";
        string memory _symbol = "fFRAX/fcWstETHwETH";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(oracle); // numerator oracle (1e6 precision) (fcTriCrypto contract's ```decimals``` is faulty)
        // oracle normalization 1^(18 - precision of numerator oracle + precision of denominator oracle + precision of asset token - precision of collateral token)
        uint256 _oracleNormalization = 1e20; // 1^(18 - 6 + 8 + 18 - 18)
        address _rateContract = address(rateCalculator);
        
        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");
        
        address _owner = address(owner);
        uint256 _maxLTV = 80000; // 80%
        uint256 _liquidationFee = 10000; // 10%
        
        lendingPair = new FortressLendingPair(_asset, _name, _symbol, _configData, _owner, address(fortressSwap), _maxLTV, _liquidationFee);

        // --------------------------------- init pair ---------------------------------

        _testInitialize(address(lendingPair));
    }

    // --------------------------------- tests ---------------------------------
    
    function testCorrectFlowWeth(uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 10 ether);

        (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) = _testDepositLiquidity(address(lendingPair), _amount);

        uint256 _totalCollateral = _testLeveragePosition(address(lendingPair), WETH);

        _testClosePosition(address(lendingPair), WETH, _totalAssetsAfter, _totalSupplyAfter, _totalCollateral);

        _testRemoveLiquidity(address(lendingPair));

        _testPlatformFee(address(lendingPair));

        _testUpdateSwap(address(lendingPair));

        _testUpdatePauseSettings(address(lendingPair));

        _testUpdateFee(address(lendingPair));

        _testUpdateOwner(address(lendingPair));
    }

    // --------------------------------- internal functions ---------------------------------

    function _addFraxWethRouteToSwap() internal {
        vm.startPrank(owner);

        if (!(fortressSwap.routeExists(FRAX, WETH))) {
            // uint256[] memory _poolType = new uint256[](1);
            // address[] memory _poolAddress = new address[](1);
            // address[] memory _fromList = new address[](1);
            // address[] memory _toList = new address[](1);

            // _poolType[0] = 14;
            
            // _poolAddress[0] = address(0);
            
            // _fromList[0] = FRAX;
            
            // _toList[0] = WETH;
            
            // fortressSwap.updateRoute(FRAX, WETH, _poolType, _poolAddress, _fromList, _toList);

            uint256[] memory _poolType = new uint256[](3);
            address[] memory _poolAddress = new address[](3);
            address[] memory _fromList = new address[](3);
            address[] memory _toList = new address[](3);

            _poolType[0] = 2;
            _poolType[1] = 2;
            _poolType[2] = 4;

            _poolAddress[0] = CURVE_FRAXBP;
            _poolAddress[1] = CURVE_BP;
            _poolAddress[2] = CURVE_TRICRYPTO;

            _fromList[0] = FRAX;
            _fromList[1] = USDC;
            _fromList[2] = USDT;

            _toList[0] = USDC;
            _toList[1] = USDT;
            _toList[2] = WETH;

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