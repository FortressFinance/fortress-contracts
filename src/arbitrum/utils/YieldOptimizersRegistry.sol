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

//  _____         _                   _____     _   _ _____         _     _           
// |   __|___ ___| |_ ___ ___ ___ ___|  _  |___| |_|_| __  |___ ___|_|___| |_ ___ _ _ 
// |   __| . |  _|  _|  _| -_|_ -|_ -|     |  _| . | |    -| -_| . | |_ -|  _|  _| | |
// |__|  |___|_| |_| |_| |___|___|___|__|__|_| |___|_|__|__|___|_  |_|___|_| |_| |_  |
//                                                             |___|             |___|

// Github - https://github.com/FortressFinance

contract YieldOptimizersRegistry {

    enum AMMType {
        Curve,
        Balancer
    }

    /// @notice The list of CurveCompounder primary assets
    address[] public curveCompoundersPrimaryAssets;

    /// @notice The list of BalancerCompounder primary assets
    address[] public balancerCompoundersPrimaryAssets;

    /// @notice The list of TokenCompounder primary assets
    address[] public tokenCompoundersPrimaryAssets;

    // /// @notice The list of CurveConcentrator primary assets
    // address[] public curveConcentratorPrimaryAssets;

    // /// @notice The list of BalancerConcentrator primary assets
    // address[] public balancerConcentratorPrimaryAssets;

    /// @notice The mapping from Primary Asset to Curve Compounder Vault address
    mapping(address => address) public curveCompounders;

    /// @notice The mapping from Primary Asset to Balancer Compounder Vault address
    mapping(address => address) public balancerCompounders;

    /// @notice The mapping from Primary Asset to Token Compounder Vault address
    mapping(address => address) public tokenCompounders;

    // -----------------------------------------------------------
    // --------------------- AMM Compounders ---------------------
    // -----------------------------------------------------------

    /// @dev Get the list of addresses of the Primary Assets of all Compounder vaults for a specific AMMType
    /// @return - The list of addresses of Primary Assets
    function getCompoundersPrimaryAssets(AMMType _ammType) external view returns (address[] memory) {
        if (_ammType == AMMType.Curve) {
            return curveCompoundersPrimaryAssets;
        } else if (_ammType == AMMType.Balancer) {
            return balancerCompoundersPrimaryAssets;
        } else {
            return 0;
        }
    }

    /// @dev Get the address of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The address of the Compounder Vault
    function getCompounderVault(AMMType _ammType, address _asset) external view returns (address) {
        if (_ammType == AMMType.Curve) {
            return curveCompounders[_asset];
        } else if (_ammType == AMMType.Balancer) {
            return balancerCompounders[_asset];
        } else {
            return 0;
        }
    }

    /// @dev Get the address of all underlying assets for a specific Compounder Vault given AMMType and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getCompounderUnderlyingAssets(AMMType _ammType, address _asset) external view returns (address[] memory) {
        if (_ammType == AMMType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).getUnderlyingAssets();
        } else if (_ammType == AMMType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).getUnderlyingAssets();
        } else {
            return 0;
        }
    }

    /// @dev Get the name of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The name of the Compounder Vault
    function getCompounderName(CompounderType _compounderType, address _asset) external view returns (string memory) {
        if (_compounderType == CompounderType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).name();
        } else if (_compounderType == CompounderType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).name();
        } else {
            return "";
        }
    }

    /// @dev Get the symbol of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The symbol of the Compounder Vault
    function getCompounderSymbol(CompounderType _compounderType, address _asset) external view returns (string memory) {
        if (_compounderType == CompounderType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).symbol();
        } else if (_compounderType == CompounderType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).symbol();
        } else {
            return "";
        }
    }

    // -------------------------------------------------------------
    // --------------------- Token Compounders ---------------------
    // -------------------------------------------------------------

    /// @dev Get the addresses of the Primary Assets of all Token Compounder vaults
    /// @return - The list of addresses of Primary Assets
    function getTokenCompoundersPrimaryAssets() external view returns (address[] memory) {
        return tokenCompoundersPrimaryAssets;
    }

    /// @dev Get the address of a Token Compounder Vault for a specific Primary Asset
    /// @return - The address of the Token Compounder Vault
    function getTokenCompounderVault(address _asset) external view returns (address) {
        return tokenCompounders[_asset];
    }

    /// @dev Get the address of all underlying assets for a specific Token Compounder Vault given AMMType and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getTokenCompounderUnderlyingAssets(address _asset) external view returns (address[] memory) {
        return IFortressCompounder(tokenCompounders[_asset]).getUnderlyingAssets();
    }

    /// @dev Get the name of a Token Compounder Vault for a specific Primary Asset
    function getTokenCompounderName(address _asset) external view returns (string memory) {
        return IFortressCompounder(tokenCompounders[_asset]).name();
    }

    // -------------------------------------------------------------
    // --------------------- AMM Concentrators ---------------------
    // -------------------------------------------------------------

    // function getConcentratorPrimaryAssetList(AMMType _ammType) external view returns (address[] memory) {
    //     if (_ammType == AMMType.Curve) {
    //         return curveConcentratorPrimaryAssets;
    //     } else if (_ammType == AMMType.Balancer) {
    //         return balancerConcentratorPrimaryAssets;
    //     } else {
    //         revert("Invalid AMMType");
    //     }
    // }

    // AMM Concentrators:

    // ** ConcentratorType is Curve/Balancer/Solidly. (basically AMM type)

    // ** TargetAsset is fortGLP/fortETH/fortTricrypto/fortUSD.

    // getConcentratorsList(ConcentratorType _concentratorType, TargetAsset _targetAsset) returns address array[] of Concentrator Vault addresses.

    // getConcentrator(ConcentratorType _concentratorType, TargetAsset _targetAsset, address _asset) returns address of Concentrator Vault of a specific asset.

    // getConcentratorSymbol(ConcentratorType _concentratorType, TargetAsset _targetAsset, address _asset) returns string of symbol of Concentrator Vault of a specific asset.

    // getConcentratorName(ConcentratorType _concentratorType, TargetAsset _targetAsset, address _asset) returns string of name of Concentrator Vault of a specific asset.

    // getConcentratorUnderlyingAssets(ConcentratorType _concentratorType, TargetAsset _targetAsset, address _asset) returns address array[] of underlying assets of Concentrator Vault of a specific asset.

    // getConcentratorTargetVault(ConcentratorType _concentratorType, TargetAsset _targetAsset) returns address of Compounder vault of specific Concentrator Vault.

    // getAllConcentratorTargetAssets() returns (TargetAsset[])
}