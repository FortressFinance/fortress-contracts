// // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from "@solmate/mixins/ERC4626.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IGlpManager} from "../interfaces/IGlpManager.sol";

contract FortressGLPOracle is AggregatorV3Interface {

    using SafeCast for uint256;

    IGlpManager public immutable glpManager;
    IERC20 public immutable glp;
    ERC4626 public immutable fcGLP;

    uint256 public maxSpread;
    uint256 public lastGlpPrice;
    uint256 public lowerBoundPercentage;
    uint256 public upperBoundPercentage;

    address public owner;

    bool public isCheckGlpPrice;

    uint256 constant private DECIMAL_DIFFERENCE = 1e6;
    uint256 constant private BASE = 1e18;

    /********************************** Constructor **********************************/

    constructor(uint256 _maxSpread, address _owner) {
        glpManager = IGlpManager(address(0x3963FfC9dff443c2A94f21b129D429891E32ec18));
        glp = IERC20(address(0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258));
        fcGLP = ERC4626(address(0x86eE39B28A7fDea01b53773AEE148884Db311B46));

        maxSpread = _maxSpread;
        lowerBoundPercentage = 10; // 10% of lastGlpPrice
        upperBoundPercentage = 10; // 10% of lastGlpPrice
        
        owner = _owner;

        lastGlpPrice = glpManager.getPrice(false);

        isCheckGlpPrice = true;
    }

    /********************************** Modifiers **********************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /********************************** External Functions **********************************/

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function description() external pure returns (string memory) {
        return "fcGLP USD Oracle";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external pure returns (uint80, int256, uint256, uint256, uint80) {
        revert("Not implemented");
    }

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, _getPrice(), 0, 0, 0);
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal view returns (int256) {
        uint256 _glpPrice = glpManager.getPrice(false);

        // check glp price deviation from last recorded price
        if (isCheckGlpPrice) _checkGlpPriceDeviation(_glpPrice);
        // check fcGLP/GLP exchange rate
        _checkVaultSpread();
        
        return ((fcGLP.convertToAssets(_glpPrice) * DECIMAL_DIFFERENCE) / BASE).toInt256();
    }

    /// @dev make sure that fcGLP/GLP exchange rate is not bigger than maxSpread
    /// @dev used to limit the risk of fcGLP vault manipulation  
    function _checkVaultSpread() internal view {
        uint256 _vaultSpread = fcGLP.convertToAssets(1e18);

        if (_vaultSpread > maxSpread) revert("vault spread too big");
    }

    /// @dev make sure that GLP price has not deviated by more than x% since last recorded price
    /// @dev used to limit the risk of GLP price manipulation
    function _checkGlpPriceDeviation(uint256 _glpPrice) internal view {
        uint256 _lastGlpPrice = lastGlpPrice;
        uint256 lowerBound = (_lastGlpPrice * (100 - lowerBoundPercentage)) / 100;
        uint256 upperBound = (_lastGlpPrice * (100 + upperBoundPercentage)) / 100;

        if (_glpPrice < lowerBound) revert("glp price too low");
        if (_glpPrice > upperBound) revert("glp price too high");

        lastGlpPrice = _glpPrice; 
    }

    /********************************** Owner Functions **********************************/

    /// @dev should be called at least once a day
    function updateLastGlpPrice() external onlyOwner {
        lastGlpPrice = glpManager.getPrice(false);
    }

    function shouldCheckGlpPrice(bool _check) external onlyOwner {
        isCheckGlpPrice = _check;
    }

    function updateMaxSpread(uint256 _maxSpread) external onlyOwner {
        maxSpread = _maxSpread;
    }

    // function updateMaxPriceDeviationPercentage(uint256 _maxPriceDeviationPercentage) external onlyOwner {
    //     maxPriceDeviationPercentage = _maxPriceDeviationPercentage;
    // }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
}