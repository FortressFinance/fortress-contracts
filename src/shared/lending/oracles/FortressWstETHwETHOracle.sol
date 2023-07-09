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

import {IBalancerV2StablePool} from "../interfaces/IBalancerV2StablePool.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";

import "./BaseOracle.sol";

contract FortressWstETHwETHOracle is BaseOracle {

    using SafeCast for uint256;

    IChainlinkAggregator public WETH = IChainlinkAggregator(address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612)); //ETH feed
    address constant wstETHwETH = address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f);
    
    /********************************** Constructor **********************************/

    constructor(address _owner, address _vault) BaseOracle(_owner, _vault) {}

    /********************************** Modifiers **********************************/

    /// @notice Triggers the Vault's reentrancy guard
    /// @dev This staticcall always reverts, but we need to make sure it doesn't fail due to a re-entrancy attack (abi.encoded BAL#400).
    modifier reentrancyCheck() {
        address balancerVault = IBalancerV2StablePool(wstETHwETH).getVault();
        (, bytes memory revertData) = balancerVault.staticcall{ gas: 10_000 }(
            abi.encodeWithSelector(IBalancerVault(balancerVault).manageUserBalance.selector, 0)
        );
        if (revertData.length != 0) revert reentrancy();
        _;
    }

    /********************************** External Functions **********************************/

    function description() external pure override returns (string memory) {
        return "fcwstETHwETH USD Oracle";
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal view override reentrancyCheck returns (int256) {
        
        int256 _wETHPrice = _getwETHPrice();
        uint256 _assetPrice = IBalancerV2StablePool(wstETHwETH).getRate() * uint256(_wETHPrice);
        uint256 _sharePrice = ((ERC4626(vault).convertToAssets(_assetPrice) * DECIMAL_DIFFERENCE) / BASE);

        // check that vault share price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return _sharePrice.toInt256();
    }

    function _getwETHPrice() internal view returns (int256) {
            (, int256 wethPrice, ,uint256 wethUpdatedAt, ) = WETH.latestRoundData();
            if (wethPrice == 0) revert zeroPrice();
            if (wethUpdatedAt < block.timestamp - (24 * 3600)) revert stalePrice();
            return wethPrice;
    }

    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external override onlyOwner reentrancyCheck {
                
        int256 _wETHPrice = _getwETHPrice();
        uint256 _assetPrice = IBalancerV2StablePool(wstETHwETH).getRate() * uint256(_wETHPrice);

        lastSharePrice = ((ERC4626(vault).convertToAssets(_assetPrice) * DECIMAL_DIFFERENCE) / BASE);

        emit LastSharePriceUpdated(lastSharePrice);
    }

    function updatePriceFeed(address _wethPriceFeed) external onlyOwner {
        WETH = IChainlinkAggregator(_wethPriceFeed);

    }
    
    /********************************** Errors **********************************/

    error reentrancy();

}