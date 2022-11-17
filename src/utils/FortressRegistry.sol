// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

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

contract FortressRegistry {

    struct AMMCompounder {
        string symbol;
        string name;
        address compounder;
        address[] underlyingAssets;
    }

    /// @notice The list of CurveCompounder assets.
    address[] public curveCompoundersList;
    /// @notice The list of BalancerCompounder assets.
    address[] public balancerCompoundersList;
    /// @notice The mapping from vault asset to CurveCompounder info.
    mapping(address => AMMCompounder) public curveCompounders;
    /// @notice The mapping from vault asset to BalancerCompounder info.
    mapping(address => AMMCompounder) public balancerCompounders;
    /// @notice The addresses of the contract owners.
    address[2] public owners;

    /********************************** Constructor **********************************/

    constructor() {
        owners[0] = msg.sender;
    }

    /********************************** View Functions **********************************/

    /** Curve Compounder **/

    /// @dev Get the list of addresses of CurveCompounders assets.
    /// @return - The list of addresses.
    function getCurveCompoundersList() public view returns (address[] memory) {
        return curveCompoundersList;
    }

    /// @dev Get the length of the CurveCompoundersList list.
    /// @return - The length of the list.
    function getCurveCompoundersListLength() public view returns (uint256) {
        return curveCompoundersList.length;
    }

    /// @dev Get the CurveCompounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific CurveCompounder.
    function getCurveCompounder(address _asset) public view returns (address) {
        return curveCompounders[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getCurveCompounderSymbol(address _asset) public view returns (string memory) {
        return curveCompounders[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getCurveCompounderName(address _asset) public view returns (string memory) {
        return curveCompounders[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getCurveCompounderUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return curveCompounders[_asset].underlyingAssets;
    }

    /** Balancer Compounder **/

    /// @dev Get the list of addresses of BalancerCompounders assets.
    /// @return - The list of addresses.
    function getBalancerCompoundersList() public view returns (address[] memory) {
        return balancerCompoundersList;
    }

    /// @dev Get the length of the BalancerCompoundersList list.
    /// @return - The length of the list.
    function getBalancerCompoundersListLength() public view returns (uint256) {
        return balancerCompoundersList.length;
    }

    /// @dev Get the BalancerCompounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific BalancerCompounder.
    function getBalancerCompounder(address _asset) public view returns (address) {
        return balancerCompounders[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific BalancerCompounder.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getBalancerCompounderSymbol(address _asset) public view returns (string memory) {
        return balancerCompounders[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific BalancerCompounder.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getBalancerCompounderName(address _asset) public view returns (string memory) {
        return balancerCompounders[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getBalancerCompounderUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return balancerCompounders[_asset].underlyingAssets;
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Register a CurveCompounder.
    /// @param _compounder - The address of the Compounder.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    function registerCurveCompounder(address _compounder, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveCompounders[_asset].compounder != address(0)) revert AlreadyRegistered();

        curveCompounders[_asset] = AMMCompounder({
            symbol: _symbol,
            name: _name,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });

        curveCompoundersList.push(_asset);
        emit RegisterCurveCompounder(_compounder, _asset, _symbol, _name, _underlyingAssets);
    }

    /// @dev Register a BalancerCompounder.
    /// @param _compounder - The address of the Compounder.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    function registerBalancerCompounder(address _compounder, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveCompounders[_asset].compounder != address(0)) revert AlreadyRegistered();

        balancerCompounders[_asset] = AMMCompounder({
            symbol: _symbol,
            name: _name,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        balancerCompoundersList.push(_asset);
        emit RegisterBalancerCompounder(_compounder, _asset, _symbol, _name, _underlyingAssets);
    }

    /// @dev Update the list of owners.
    /// @param _index - The slot on the list.
    /// @param _owner - The address of the new owner.
    function updateOwner(uint256 _index, address _owner) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();

        owners[_index] = _owner;
    }

    /********************************** Events & Errors **********************************/

    event RegisterCurveCompounder(address indexed _curveCompounder, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets);
    event RegisterBalancerCompounder(address indexed _curveCompounder, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets);

    error Unauthorized();
    error AlreadyRegistered();
}
