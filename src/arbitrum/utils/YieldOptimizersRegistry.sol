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

    enum TargetAsset {
        fortETH,
        fortUSD,
        fortCrypto1, 
        fortCrypto2
    }

    /// @notice The list of Curve ETH Concentrator vaults
    address[] public curveConcentratorEth;

    /// @notice The list of Curve USD Concentrator vaults
    address[] public curveConcentratorUsd;

    /// @notice The list of Curve Crypto1 Concentrator vaults
    address[] public curveConcentratorCrypto1;

    /// @notice The list of Curve ETH Compounder vaults
    address[] public curveConcentratorCrypto1;

    /// @notice The list of CurveCompounder primary assets
    address[] public curveCompoundersPrimaryAssets;

    /// @notice The list of BalancerCompounder primary assets
    address[] public balancerCompoundersPrimaryAssets;

    /// @notice The list of TokenCompounder primary assets
    address[] public tokenCompoundersPrimaryAssets;

    /// @notice The list of CurveConcentrator primary assets
    address[] public curveConcentratorPrimaryAssets;

    /// @notice The list of BalancerConcentrator primary assets
    address[] public balancerConcentratorPrimaryAssets;

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
        }
    }

    /// @dev Get the address of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The address of the Compounder Vault
    function getCompounderVault(AMMType _ammType, address _asset) external view returns (address) {
        if (_ammType == AMMType.Curve) {
            return curveCompounders[_asset];
        } else if (_ammType == AMMType.Balancer) {
            return balancerCompounders[_asset];
        }
    }

    /// @dev Get the address of all underlying assets for a specific Compounder Vault given AMMType and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getCompounderUnderlyingAssets(AMMType _ammType, address _asset) external view returns (address[] memory) {
        if (_ammType == AMMType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).getUnderlyingAssets();
        } else if (_ammType == AMMType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).getUnderlyingAssets();
        }
    }

    /// @dev Get the name of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The name of the Compounder Vault
    function getCompounderName(CompounderType _compounderType, address _asset) external view returns (string memory) {
        if (_compounderType == CompounderType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).name();
        } else if (_compounderType == CompounderType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).name();
        }
    }

    /// @dev Get the symbol of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The symbol of the Compounder Vault
    function getCompounderSymbol(CompounderType _compounderType, address _asset) external view returns (string memory) {
        if (_compounderType == CompounderType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).symbol();
        } else if (_compounderType == CompounderType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).symbol();
        }
    }

    /// @dev Get the description of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The description of the Compounder Vault
    function getCompounderDescription(CompounderType _compounderType, address _asset) external view returns (string memory) {
        if (_compounderType == CompounderType.Curve) {
            return IFortressCompounder(curveCompounders[_asset]).description();
        } else if (_compounderType == CompounderType.Balancer) {
            return IFortressCompounder(balancerCompounders[_asset]).description();
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
    /// @return - The name of the Token Compounder Vault
    function getTokenCompounderName(address _asset) external view returns (string memory) {
        return IFortressCompounder(tokenCompounders[_asset]).name();
    }

    /// @dev Get the symbol of a Token Compounder Vault for a specific Primary Asset
    /// @return - The symbol of the Token Compounder Vault
    function getTokenCompounderSymbol(address _asset) external view returns (string memory) {
        return IFortressCompounder(tokenCompounders[_asset]).symbol();
    }

    /// @dev Get the description of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The description of the Compounder Vault
    function getTokenCompounderDescription(address _asset) external view returns (string memory) {
        return IFortressCompounder(tokenCompounders[_asset]).description();
    }

    // -------------------------------------------------------------
    // --------------------- AMM Concentrators ---------------------
    // -------------------------------------------------------------

    /// @dev Get the addresses of the Primary Assets of all AMM Concentrator vaults for a specific AMMType
    /// @return - The list of addresses of Primary Assets
    function getConcentratorPrimaryAssets(AMMType _ammType) external view returns (address[] memory) {
        if (_ammType == AMMType.Curve) {
            return curveConcentratorPrimaryAssets;
        } else if (_ammType == AMMType.Balancer) {
            return balancerConcentratorPrimaryAssets;
        }
    }

    /// @dev Get the addresses of the Concentrator Vaults for a specific AMMType and Target Asset
    /// @return - The list of addresses of Concentrator Vaults
    function getConcentrators(AMMType _ammType, TargetAsset _targetAsset) external view returns (address[] memory) {
        if (_ammType == AMMType.Curve) {
            if (_targetAsset == TargetAsset.fortETH) {
                return curveConcentratorEth;
            } else if (_targetAsset == TargetAsset.fortUSD) {
                return curveConcentratorUsd;
            } else if (_targetAsset == TargetAsset.fortCrypto1) {
                return curveConcentratorCrypto1;
            } else if (_targetAsset == TargetAsset.fortCrypto2) {
                return curveConcentratorCrypto2;
            } 
        } else if (_ammType == AMMType.Balancer) {
            if (_targetAsset == TargetAsset.fortETH) {
                return curveConcentratorEth;
            } else if (_targetAsset == TargetAsset.fortUSD) {
                return curveConcentratorUsd;
            } else if (_targetAsset == TargetAsset.fortCrypto1) {
                return curveConcentratorCrypto1;
            } else if (_targetAsset == TargetAsset.fortCrypto2) {
                return curveConcentratorCrypto2;
            }
        }
    }

    // TODO
    // getConcentratorSymbol(AMMType _ammType, TargetAsset _targetAsset, address _asset) returns string of symbol of Concentrator Vault of a specific asset.
    function getConcentratorSymbol(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (string memory) {
        if (_ammType == AMMType.Curve) {
            return IFortressConcentrator(curveConcentrators[_targetAsset][_asset]).symbol();
        } else if (_ammType == AMMType.Balancer) {
            return IFortressConcentrator(balancerConcentrators[_targetAsset][_asset]).symbol();
        }
    }

    // getConcentratorName(AMMType _ammType, TargetAsset _targetAsset, address _asset) returns string of name of Concentrator Vault of a specific asset.

    // getConcentratorUnderlyingAssets(AMMType _ammType, TargetAsset _targetAsset, address _asset) returns address array[] of underlying assets of Concentrator Vault of a specific asset.

    // getConcentratorTargetVault(AMMType _ammType, TargetAsset _targetAsset) returns address of Compounder vault of specific Concentrator Vault.

    // getAllConcentratorTargetAssets() returns (TargetAsset[])
}