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

    uint256 public lastSharePrice;
    uint256 public lowerBoundPercentage;
    uint256 public upperBoundPercentage;

    address public owner;

    bool public isCheckPriceDeviation;

    uint256 constant private DECIMAL_DIFFERENCE = 1e6;
    uint256 constant private BASE = 1e18;

    /********************************** Constructor **********************************/

    constructor(address _owner) {
        glpManager = IGlpManager(address(0x3963FfC9dff443c2A94f21b129D429891E32ec18));
        glp = IERC20(address(0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258));
        fcGLP = ERC4626(address(0x86eE39B28A7fDea01b53773AEE148884Db311B46));

        lowerBoundPercentage = 20;
        upperBoundPercentage = 20;
        
        owner = _owner;

        lastSharePrice = uint256(_getPrice());

        isCheckPriceDeviation = true;
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
        uint256 _assetPrice = glpManager.getPrice(false);

        uint256 _sharePrice = ((fcGLP.convertToAssets(_assetPrice) * DECIMAL_DIFFERENCE) / BASE);

        // check that fcGLP price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);

        return _sharePrice.toInt256();
    }

    /// @dev make sure that GLP price has not deviated by more than x% since last recorded price
    /// @dev used to limit the risk of GLP price manipulation
    function _checkPriceDeviation(uint256 _sharePrice) internal view {
        uint256 _lastSharePrice = lastSharePrice;
        uint256 _lowerBound = (_lastSharePrice * (100 - lowerBoundPercentage)) / 100;
        uint256 _upperBound = (_lastSharePrice * (100 + upperBoundPercentage)) / 100;

        if (_sharePrice < _lowerBound || _sharePrice > _upperBound) revert priceDeviationTooHigh();
    }

    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external onlyOwner {
        lastSharePrice = ((fcGLP.convertToAssets(glpManager.getPrice(false)) * DECIMAL_DIFFERENCE) / BASE);
    }

    function shouldCheckPriceDeviation(bool _check) external onlyOwner {
        isCheckPriceDeviation = _check;
    }

    function updatePriceDeviationBounds(uint256 _lowerBoundPercentage, uint256 _upperBoundPercentage) external onlyOwner {
        lowerBoundPercentage = _lowerBoundPercentage;
        upperBoundPercentage = _upperBoundPercentage;
    }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /********************************** Errors **********************************/

    error priceDeviationTooHigh();
}