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

//  __ __ ___ _____ _____ _                     _____ _           _               
// |  |  |_  |  |  |   __|_|___ ___ ___ ___ ___|   __| |_ ___ ___| |_ ___ ___ _ _ 
// |_   _|  _|    -|   __| |   | .'|   |  _| -_|__   |  _|  _| .'|  _| -_| . | | |
//   |_| |___|__|__|__|  |_|_|_|__,|_|_|___|___|_____|_| |_| |__,|_| |___|_  |_  |
//                                                                       |___|___|

// Github - https://github.com/FortressFinance

import {BaseStrategy, IAssetVault} from "./BaseStrategy.sol";
import {IY2KVaultFactory} from "./interfaces/IY2KVaultFactory.sol";
import {IY2KVault} from "./interfaces/IY2KVault.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Y2KFinanceStrategy is BaseStrategy {

    /// @notice Address of the Y2K Vault Factory
    address vaultFactory;

    /// @notice Array of vaults that were used
    address[] vaults;
    /// @notice Array of vault IDs that were used
    uint256[] vaultIDs;

    /********************************** Constructor **********************************/

    constructor(address _assetVault, address _platform, address _manager)
        BaseStrategy(_assetVault, _platform, _manager) {
            vaultFactory = address(0x984E0EB8fB687aFa53fc8B33E12E04967560E092);
        }

    /********************************** View Functions **********************************/

    function isActive() public view override returns (bool) {
        if (isStrategiesActiveOverride) return false;
        if (IERC20(assetVaultPrimaryAsset).balanceOf(address(this)) > 0) return true;

        address[] memory _vaults = vaults;
        uint256[] memory _vaultIDs = vaultIDs;
        for (uint256 i = 0; i < vaults.length; i++) {
            if (IY2KVault(_vaults[i]).balanceOf(address(this), _vaultIDs[i]) > 0) return true;
        }

        return false;
    }

    /********************************** Manager Functions **********************************/

    /// @dev Executes the strategy - deposit into a Y2K Risk/Hedge Vault
    /// @dev _configData:
    /// @dev _index - index of the vault in the vaultFactory, determines the asset and the strike vault
    /// @dev _amount - amount of the assetVaultPrimaryAsset to deposit, will be set to the balance if set to type(uint256).max
    /// @dev _id - id of the vault in the vaultFactory, determines end date of the Epoch
    /// @dev _type - true for Risk Vault, false for Hedge Vault
    function execute(bytes memory _configData) external override onlyManager returns (uint256) {
        
        (uint256 _id, uint256 _amount, uint256 _before, address _vault) = _getConfig(_configData);

        _approve(assetVaultPrimaryAsset, _vault, _amount);
        IY2KVault(_vault).deposit(_id, _amount, address(this));

        uint256 _shares = IY2KVault(_vault).balanceOf(address(this), _id) - _before;

        // TODO
        // if (_getStakingContract(_vault, _id) != address(0)) _stake(_shares);

        return _shares;
    }

    /// @dev Terminates the strategy - withdraw from fortGLP
    /// @dev _configData:
    /// @dev _index - index of the vault in the vaultFactory, determines the asset and the strike vault
    /// @dev _amount - amount of the assetVaultPrimaryAsset to deposit, will be set to the balance if set to type(uint256).max
    /// @dev _id - id of the vault in the vaultFactory, determines end date of the Epoch
    /// @dev _type - true for Risk Vault, false for Hedge Vault
    function terminate(bytes memory _configData) external override onlyManager returns (uint256) {
        
        (uint256 _id, uint256 _amount, uint256 _before, address _vault) = _getConfig(_configData);

        // TODO
        // if (_getStakingContract(_vault, _id) != address(0)) _unstake(_shares);

        IY2KVault(_vault).withdraw(_id, _amount, address(this), address(this));

        return IY2KVault(_vault).balanceOf(address(this), _id) - _before;
    }

    /********************************** Internal Functions **********************************/

    function _getConfig(bytes memory _configData) internal returns (uint256, uint256, uint256, address) {
        (uint256 _index, uint256 _amount, uint256 _id, bool _type) = abi.decode(_configData, (uint256, uint256, uint256, bool));

        address _assetVaultPrimaryAsset = assetVaultPrimaryAsset;
        if (_amount == type(uint256).max) {
            _amount = IERC20(_assetVaultPrimaryAsset).balanceOf(address(this));
        }

        (address[] memory _vaults) = IY2KVaultFactory(vaultFactory).getVaults(_index);

        address _vault = _type == true ? _vaults[1] : _vaults[0];
        if (_vault == address(0)) revert NonExistent();

        vaults.push(_vault);
        vaultIDs.push(_id);

        uint256 _before = IY2KVault(_vault).balanceOf(address(this), _id);

        return (_id, _amount, _before, _vault);
    }
}
