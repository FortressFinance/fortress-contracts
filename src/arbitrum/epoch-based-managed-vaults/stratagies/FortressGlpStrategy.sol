// SPDX-License-Identifier: MIT
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

//  _____         _                   _____ _     _____ _           _               
// |   __|___ ___| |_ ___ ___ ___ ___|   __| |___|   __| |_ ___ ___| |_ ___ ___ _ _ 
// |   __| . |  _|  _|  _| -_|_ -|_ -|  |  | | . |__   |  _|  _| .'|  _| -_| . | | |
// |__|  |___|_| |_| |_| |___|___|___|_____|_|  _|_____|_| |_| |__,|_| |___|_  |_  |
//                                           |_|                           |___|___|

// Github - https://github.com/FortressFinance

import {BaseStrategy} from "./BaseStrategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFortGlp} from "./interfaces/IFortGlp.sol";

contract FortressGlpStrategy is BaseStrategy {

    /// @notice The address of fortGLP
    address public fortGlp;
    
    /********************************** Constructor **********************************/

    constructor(address[] memory _assets, address _assetVault, address _platform, address _manager, address _fortGlp)
        BaseStrategy(_assets, _assetVault, _platform, _manager) {
            fortGlp = _fortGlp;
        }

    /********************************** View Functions **********************************/

    function isActive() public view override returns (bool) {
        if (isStrategiesActiveOverride) return false;

        if (IERC20(fortGlp).balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }

    /********************************** Manager Functions **********************************/

    function execute(bytes memory _configData) external override onlyManager returns (uint256) {
        (uint256 _amount, uint256 _minAmount, bool _entireBalance) = abi.decode(_configData, (uint256, uint256, bool));

        if (_entireBalance) {
            _amount = IERC20(assetVaultAsset).balanceOf(address(this));
        }
        uint256 _shares = IFortGlp(fortGlp).depositUnderlying(assetVaultAsset, _amount, address(this), _minAmount);

        return _shares;
    }

    function terminate(bytes memory _configData) external override onlyManager returns (uint256) {
        (uint256 _amount, uint256 _minAmount, bool _entireBalance) = abi.decode(_configData, (uint256, uint256, bool));

        if (_entireBalance) {
            _amount = IERC20(fortGlp).balanceOf(address(this));
        }
        _amount = IFortGlp(fortGlp).redeemUnderlying(assetVaultAsset, _amount, address(this), address(this), _minAmount);

        return _amount;
    }
}
