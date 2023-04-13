// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./FortressLendingCore.sol";

/// @notice The child contract of FortressLendingCore that is deployed for each pair. Can be used to add additional functionality
contract FortressLendingPair is FortressLendingCore {

    constructor(ERC20 _asset, string memory _name, string memory _symbol, bytes memory _configData, address _owner, address _swap, uint256 _maxLTV, uint256 _liquidationFee)
        FortressLendingCore(_asset, _name, _symbol, _configData, _owner, _swap, _maxLTV, _liquidationFee)
    {}
}