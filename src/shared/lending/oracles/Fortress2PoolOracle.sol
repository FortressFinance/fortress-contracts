// // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝

// 
// 
// 
// 

// Github - https://github.com/FortressFinance

import {ERC4626} from "@solmate/mixins/ERC4626.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurvePool} from "../interfaces/ICurvePool.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol"; 


contract Fortress2PoolOracle is AggregatorV3Interface {

    using SafeCast for uint256;

    ICurvePool public immutable twoPool;
    ERC4626 public immutable fc2Pool;
    IChainlinkAggregator public USDC;
    IChainlinkAggregator public USDT;

    uint256 public lastSharePrice;
    uint256 public lowerBoundPercentage;
    uint256 public upperBoundPercentage;
    uint256 public vaultMaxSpread;

    address public owner;

    bool public isCheckPriceDeviation;

    uint256 constant private DECIMAL_DIFFERENCE = 1e6;
    uint256 constant private BASE = 1e18;

    /********************************** Constructor **********************************/

    constructor(address _owner) {
        twoPool = ICurvePool(address(0x7f90122BF0700F9E7e1F688fe926940E8839F353)); 
        fc2Pool = ERC4626(address(0xe16F15266cD00c418fB63e505361de32ce90Ac9f));

        USDC = IChainlinkAggregator(address(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3));
        USDT = IChainlinkAggregator(address(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7));

        lowerBoundPercentage = 20;
        upperBoundPercentage = 20;
        
        owner = _owner;

        uint256 _vaultSpread = fc2Pool.convertToAssets(1e18);
        vaultMaxSpread = _vaultSpread * 110 / 100; // limit to 10% of the vault spread

        lastSharePrice = uint256(_getPrice());

        isCheckPriceDeviation = true;
    }

    /********************************** Modifiers **********************************/

    modifier onlyOwner() {
        if (msg.sender != owner) revert notOwner();
        _;
    }

    /********************************** External Functions **********************************/

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function description() external pure returns (string memory) {
        return "fc2Pool USD Oracle";
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
        uint256 minAssetPrice = uint256(_getMinAssetPrice());
        uint256 _assetPrice = twoPool.get_virtual_price() * minAssetPrice;

        uint256 _sharePrice = ((fc2Pool.convertToAssets(_assetPrice) * DECIMAL_DIFFERENCE) / BASE);

        // check that fc2Pool price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return _sharePrice.toInt256();
    }

    function _getMinAssetPrice() internal view returns (uint256) {
        (, int256 usdcPrice, ,uint256 usdcUpdatedAt, ) = USDC.latestRoundData();
        if (usdcPrice == 0) revert zeroPrice();
        if (usdcUpdatedAt >= block.timestamp - 3600) revert stalePrice();

        (, int256 usdtPrice, ,uint256 usdtUpdatedAt, ) = USDT.latestRoundData();
        if (usdtPrice == 0) revert zeroPrice();
        if (usdtUpdatedAt >= block.timestamp - 3600) revert stalePrice();
        
        return Math.min(uint256(usdcPrice), uint256(usdtPrice));
    }

    /// @dev make sure that lp token price has not deviated by more than x% since last recorded price
    /// @dev used to limit the risk of lp token price manipulation
    function _checkPriceDeviation(uint256 _sharePrice) internal view {
        uint256 _lastSharePrice = lastSharePrice;
        uint256 _lowerBound = (_lastSharePrice * (100 - lowerBoundPercentage)) / 100;
        uint256 _upperBound = (_lastSharePrice * (100 + upperBoundPercentage)) / 100;

        if (_sharePrice < _lowerBound || _sharePrice > _upperBound) revert priceDeviationTooHigh();
    }

    function _checkVaultSpread() internal view {
        if (fc2Pool.convertToAssets(1e18) > vaultMaxSpread) revert vaultMaxSpreadExceeded();
    }

    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external onlyOwner {
        uint256 minAssetPrice = uint256(_getMinAssetPrice());
        uint256 _assetPrice = twoPool.get_virtual_price() * minAssetPrice;

        lastSharePrice = ((fc2Pool.convertToAssets(_assetPrice) * DECIMAL_DIFFERENCE) / BASE);

        emit LastSharePriceUpdated(lastSharePrice);
    }

    function shouldCheckPriceDeviation(bool _check) external onlyOwner {
        isCheckPriceDeviation = _check;

        emit PriceDeviationCheckUpdated(_check);
    }

    function updatePriceDeviationBounds(uint256 _lowerBoundPercentage, uint256 _upperBoundPercentage) external onlyOwner {
        lowerBoundPercentage = _lowerBoundPercentage;
        upperBoundPercentage = _upperBoundPercentage;

        emit PriceDeviationBoundsUpdated(_lowerBoundPercentage, _upperBoundPercentage);
    }

    function updateVaultMaxSpread(uint256 _vaultMaxSpread) external onlyOwner {
        vaultMaxSpread = _vaultMaxSpread;

        emit VaultMaxSpreadUpdated(_vaultMaxSpread);
    }

    function updatePriceFeed(address _usdtPriceFeed, address _usdcPriceFeed) external onlyOwner {
        USDC = IChainlinkAggregator(_usdcPriceFeed);
        USDT = IChainlinkAggregator(_usdtPriceFeed);

        emit PriceFeedUpdated(_usdtPriceFeed, _usdcPriceFeed);
    }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;

        emit OwnershipTransferred(owner, _owner);
    }

    /********************************** Events **********************************/

    event LastSharePriceUpdated(uint256 lastSharePrice);
    event PriceDeviationCheckUpdated(bool isCheckPriceDeviation);
    event PriceDeviationBoundsUpdated(uint256 lowerBoundPercentage, uint256 upperBoundPercentage);
    event VaultMaxSpreadUpdated(uint256 vaultMaxSpread);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PriceFeedUpdated(address indexed usdtPriceFeed, address indexed usdcPriceFeed);

    /********************************** Errors **********************************/

    error priceDeviationTooHigh();
    error vaultMaxSpreadExceeded();
    error notOwner();
    error zeroPrice();
    error stalePrice();
}