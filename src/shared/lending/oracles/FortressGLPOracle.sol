// // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from "@solmate/mixins/ERC4626.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IGlpManager} from "../interfaces/IGlpManager.sol";

import "forge-std/console.sol";

contract FortressGLPOracle is AggregatorV3Interface {

    using SafeCast for uint256;

    IGlpManager public immutable glpManager;
    IERC20 public immutable glp;
    ERC4626 public immutable fcGLP;

    uint256 public maxSpread;

    address public owner;

    uint256 constant private DECIMAL_DIFFERENCE = 1e6;
    uint256 constant private BASE = 1e18;

    /********************************** Constructor **********************************/

    constructor(uint256 _maxSpread, address _owner) {
        glpManager = IGlpManager(address(0x3963FfC9dff443c2A94f21b129D429891E32ec18));
        glp = IERC20(address(0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258));
        fcGLP = ERC4626(address(0x86eE39B28A7fDea01b53773AEE148884Db311B46));

        maxSpread = _maxSpread;
        owner = _owner;
    }

    /********************************** Modifiers **********************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /********************************** Pure Functions **********************************/

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

    /********************************** View Functions **********************************/

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, _getPrice(), 0, 0, 0);
    }

    function _getPrice() internal view returns (int256) {
        uint256 _glpPrice = glpManager.getPrice(false) * DECIMAL_DIFFERENCE;

        _checkVaultSpread();
        
        return (fcGLP.convertToAssets(_glpPrice) / BASE).toInt256();
    }

    /// @dev make sure that fcGLP/GLP exchange rate is not bigger than maxSpread
    /// @dev used to limit the risk of fcGLP vault manipulation  
    function _checkVaultSpread() internal view {
        uint256 _vaultSpread = fcGLP.convertToAssets(1e18);

        if (_vaultSpread > maxSpread) revert("Vault spread too big");
    }

    /********************************** Owner Functions **********************************/

    function updateMaxSpread(uint256 _maxSpread) external onlyOwner {
        maxSpread = _maxSpread;
    }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
}