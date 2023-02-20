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

    struct TargetAssets {
        fortETH,
        fortUSD,
        fortCrypto1, 
        fortCrypto2
    }

    // -------------- Compounders --------------

    // Curve Compounders

    /// @notice The list of CurveCompounder primary assets
    address[] public curveCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Curve Compounder Vault address
    mapping(address => address) public curveCompounders;

    // Balancer Compounders

    /// @notice The list of BalancerCompounder primary assets
    address[] public balancerCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Balancer Compounder Vault address
    mapping(address => address) public balancerCompounders;

    // Token Compounders

    /// @notice The list of TokenCompounder primary assets
    address[] public tokenCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Token Compounder Vault address
    mapping(address => address) public tokenCompounders;

    // -------------- Concentrators --------------
    
    // Concentrators Target Assets

    /// @notice The instance of Concentrator Target Assets
    TargetAssets public concentratorTargetAssets;

    // Curve Concentrators

    /// @notice The list of CurveConcentrator primary assets
    address[] public curveConcentratorPrimaryAssets;

    /// @notice The list of Curve ETH Concentrator vaults
    address[] public curveConcentratorEth;

    /// @notice The list of Curve USD Concentrator vaults
    address[] public curveConcentratorUsd;

    /// @notice The list of Curve Crypto1 Concentrator vaults
    address[] public curveConcentratorCrypto1;

    /// @notice The list of Curve Crypto2 Concentrator vaults
    address[] public curveConcentratorCrypto2;

    // Balancer Concentrators

    /// @notice The list of BalancerConcentrator primary assets
    address[] public balancerConcentratorPrimaryAssets;

    /// @notice The list of Curve ETH Concentrator vaults
    address[] public balancerConcentratorEth;

    /// @notice The list of Balancer USD Concentrator vaults
    address[] public balancerConcentratorUsd;

    /// @notice The list of Balancer Crypto1 Concentrator vaults
    address[] public balancerConcentratorCrypto1;

    /// @notice The list of Balancer Crypto2 Concentrator vaults
    address[] public balancerConcentratorCrypto2;

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

    /// @dev Get the address of a Concentrator Vault for a specific AMMType, Target Asset, and Primary Asset
    /// @return - The address of the Concentrator Vault
    function getConcentrator(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (address) {
        if (_ammType == AMMType.Curve) {
            if (_targetAsset == TargetAsset.fortETH) {
                return curveConcentratorEth[_asset];
            } else if (_targetAsset == TargetAsset.fortUSD) {
                return curveConcentratorUsd[_asset];
            } else if (_targetAsset == TargetAsset.fortCrypto1) {
                return curveConcentratorCrypto1[_asset];
            } else if (_targetAsset == TargetAsset.fortCrypto2) {
                return curveConcentratorCrypto2[_asset];
            } 
        } else if (_ammType == AMMType.Balancer) {
            if (_targetAsset == TargetAsset.fortETH) {
                return balancerConcentratorEth[_asset];
            } else if (_targetAsset == TargetAsset.fortUSD) {
                return balancerConcentratorUsd[_asset];
            } else if (_targetAsset == TargetAsset.fortCrypto1) {
                return balancerConcentratorCrypto1[_asset];
            } else if (_targetAsset == TargetAsset.fortCrypto2) {
                return balancerConcentratorCrypto2[_asset];
            }
        }
    }

    /// @dev Get the symbol of a Concentrator Vault for a specific AMMType, Target Asset, and Primary Asset
    /// @return - The symbol of the Concentrator Vault
    function getConcentratorSymbol(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (string memory) {
        return IFortressConcentrator(getConcentrator(_ammType, _targetAsset, _asset)).symbol();
    }

    /// @dev Get the name of a Concentrator Vault for a specific AMMType, Target Asset, and Primary Asset
    /// @return - The name of the Concentrator Vault
    function getConcentratorName(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (string memory) {
        return IFortressConcentrator(getConcentrator(_ammType, _targetAsset, _asset)).name();
    }

    /// @dev Get the underlying assets of a Concentrator Vault for a specific AMMType, Target Asset, and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getConcentratorUnderlyingAssets(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (address[] memory) {
        return IFortressConcentrator(getConcentrator(_ammType, _targetAsset, _asset)).getUnderlyingAssets();
    }

    /// @dev Get the target asset of a Concentrator Vault for a specific AMMType, Target Asset, and Primary Asset
    /// @return - The address of the target asset, which is a Fortress Compounder Vault
    function getConcentratorTargetVault(AMMType _ammType, TargetAsset _targetAsset, address _asset) external view returns (address) {
        return IFortressConcentrator(getConcentrator(_ammType, _targetAsset, _asset)).compounder();
    }
}