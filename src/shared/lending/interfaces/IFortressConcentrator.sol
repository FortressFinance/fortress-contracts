// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressConcentrator {

    /// @dev Claims all rewards for _owner and sends them to _receiver
    /// @param _owner - The owner of rewards
    /// @param _receiver - The recipient of rewards
    /// @return _rewards - The amount of Compounder shares sent to the _receiver
    function claim(address _owner, address _receiver) external returns (uint256 _rewards);
}