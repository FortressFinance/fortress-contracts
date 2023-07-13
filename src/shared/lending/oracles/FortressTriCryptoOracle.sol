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

//  _____         _                   _____     _ _____             _       _____             _     
// |   __|___ ___| |_ ___ ___ ___ ___|_   _|___|_|     |___ _ _ ___| |_ ___|     |___ ___ ___| |___ 
// |   __| . |  _|  _|  _| -_|_ -|_ -| | | |  _| |   --|  _| | | . |  _| . |  |  |  _| .'|  _| | -_|
// |__|  |___|_| |_| |_| |___|___|___| |_| |_| |_|_____|_| |_  |  _|_| |___|_____|_| |__,|___|_|___|
//                                                         |___|_|                                  

// Github - https://github.com/FortressFinance

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {ICurveV2Pool} from "../interfaces/ICurveV2Pool.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import "./BaseOracle.sol";

// interface ICurvePool {
//     function A() external view returns (uint256);
//     function gamma() external view returns (uint256);
//     function get_virtual_price() external view returns (uint256);
// }

contract FortressTriCryptoOracle is BaseOracle {

    using FixedPointMathLib for uint256;

    IChainlinkAggregator public btcUSDFeed = IChainlinkAggregator(address(0x6ce185860a4963106506C203335A2910413708e9));
    IChainlinkAggregator public ethUSDFeed = IChainlinkAggregator(address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612));
    IChainlinkAggregator public usdtUSDFeed = IChainlinkAggregator(address(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7));

    address public constant triCrypto = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    /********************************** Constructor **********************************/

    constructor(address _owner, address _vault) BaseOracle(_owner, _vault) {}

    /********************************** External Functions **********************************/

    function description() external pure override returns (string memory) {
        return "fcTriCrypto USD Oracle";
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal view override returns (int256) {
        
        uint256 _lpPrice = _getLPprice(
            _getUSDPrice(btcUSDFeed) * 1e10,
            _getUSDPrice(ethUSDFeed) * 1e10,
            _getUSDPrice(usdtUSDFeed) * 1e10
        );
        uint256 _sharePrice = ERC4626(vault).convertToAssets(_lpPrice);

        // check that vault share price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return int256(_sharePrice);
    }

    function _getUSDPrice(IChainlinkAggregator _feed) internal view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = _feed.latestRoundData();
        
        if (answer <= 0) revert zeroPrice();
        if (updatedAt < block.timestamp - (24 * 3600)) revert stalePrice();
        
        return uint256(answer);
    }

    function _getLPprice(uint p1, uint p2, uint p3) internal view returns(uint256) {
        return 3 * ICurveV2Pool(triCrypto).get_virtual_price() * cubicRoot(p1 * p2 / 1e18 * p3) / 1e18;
    }

    function cubicRoot(uint x) internal pure returns (uint) {
        uint D = x / 1e18;
        for (uint i; i < 255;) {
            uint D_prev = D;
            D = D * (2e18 + x / D * 1e18 / D * 1e18 / D) / (3e18);
            uint diff = (D > D_prev) ? D - D_prev : D_prev - D;
            if (diff < 2 || diff * 1e18 < D) return D;
            unchecked { ++i; }
        }
        revert didNotConverge();
    }

    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external override onlyOwner {
        uint256 _lpPrice = _getLPprice(
            _getUSDPrice(btcUSDFeed) * 1e10,
            _getUSDPrice(ethUSDFeed) * 1e10,
            _getUSDPrice(usdtUSDFeed) * 1e10
        );
        lastSharePrice = ERC4626(vault).convertToAssets(_lpPrice);
        emit LastSharePriceUpdated(lastSharePrice);
    }

    function updatePriceFeed(address _btcUSDFeed, address _ethUSDFeed, address _usdtUSDFeed) external onlyOwner {
        btcUSDFeed = IChainlinkAggregator(_btcUSDFeed);
        ethUSDFeed = IChainlinkAggregator(_ethUSDFeed);
        usdtUSDFeed = IChainlinkAggregator(_usdtUSDFeed);
    }
}