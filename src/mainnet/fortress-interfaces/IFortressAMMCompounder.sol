// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressAMMCompounder {

    /********************************** Events **********************************/

    event Deposit(uint256 indexed _pid, address indexed _recipient, uint256 _amount);
    event Withdraw(uint256 indexed _pid, address indexed _recipient, uint256 _shares);
    event Claim(uint256 indexed _pid, address indexed _recipient, uint256 _reward);
    event Harvest(address indexed _caller, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);
    event Migrate(uint256 indexed _pid, address indexed _recipient, address _migrator, uint256 _newPid);

    event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
    event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
    event UpdatePlatform(address indexed _platform);
    event UpdateSwap(address indexed _swap);
    event UpdateOwner(address indexed _owner);
    event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);
    event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);
    event PausePoolDeposit(uint256 indexed _pid, bool _status);
    event PausePoolWithdraw(uint256 indexed _pid, bool _status);
    event WithdrawPlatformFee();

    // /********************************** View Functions **********************************/

    // /// @notice Return the amount of pending rewards for specific pool.
    // /// @param _pid - The pool id.
    // /// @param _account - The address of user.
    // function pendingReward(uint256 _pid, address _account) external view returns (uint256);

    // /// @notice Returns whether the _token is part of the underlying Curve pool or not.
    // /// @param _pid The pool id to query.
    // /// @param _token The token to check.
    // // function isUnderlyingToken(uint256 _pid, address _token) public view returns (bool);

    // /// @notice Return the user share for specific user.
    // /// @param _pid The pool id to query.
    // /// @param _account The address of user.
    // function getUserShare(uint256 _pid, address _account) external view returns (uint256);

    // /// @notice Return the total underlying token deposited.
    // /// @param _pid The pool id to query.
    // function getTotalUnderlying(uint256 _pid) external view returns (uint256);

    // /// @notice Return the total pool share deposited.
    // /// @param _pid The pool id to query.
    // function getTotalShare(uint256 _pid) external view returns (uint256);

    // /********************************** Mutated Functions **********************************/

    /// @notice Deposit LP tokens to specific pool for someone.
    /// @param _pid The pool id.
    /// @param _amount The amount of token to deposit.
    /// @param _recipient The address of recipient who will recieve the token.
    /// @return _shares The amount of share after deposit.
    function deposit(uint256 _pid, uint256 _amount, address _recipient) external returns (uint256 _shares);

    // /// @notice Deposit a single base token of the caller to specific pool for someone.
    // /// @param _pid The pool id.
    // /// @param _token The base token.
    // /// @param _amount The amount of base token.
    // /// @param _minAmount The minimum amount of LP tokens to get from Curve.
    // /// @return _shares The amount of share after deposit.
    // function depositSingleBaseAsset(uint256 _pid, address _token, uint256 _amount, uint256 _minAmount) external payable returns (uint256 _shares);

    // /// @notice Withdraw LP Tokens from specific pool and send to someone.
    // /// @param _pid - The pool id.
    // /// @param _shares - The amount of shares to withdraw.
    // /// @param _recipient - The address of token zapping to.
    // /// @return _withdrawn - The amount of LP token sent to _recipient.
    // function withdraw(uint256 _pid, uint256 _shares, address _recipient) external returns (uint256 _withdrawn);

    // /// @notice claim pending rewards from specific pool and send to someone.
    // /// @param _pid - The pool id.
    // /// @param _recipient - The minimum amount of pending reward to receive.
    // /// @return _rewards - The amount of rewards sent to _recipient.
    // // function claim(uint256 _pid, uint256 _recipient) public returns (uint256 _rewards);

    // /// @notice Withdraw shares from specific pool, claim pending rewards and send to someone.
    // /// @param _pid - The pool id.
    // /// @param _shares - The amount of shares to withdraw.
    // /// @param _recipient - The address to send proceeds to.
    // /// @return _withdrawn - The amount of LP tokens sent to _recipient.
    // /// @return _claimed - The amount of reward sent to _recipient.
    // // function withdrawAndClaim(uint256 _pid, uint256 _shares, uint256 _recipient) external returns (uint256 _withdrawn, uint256 _claimed);
  
    // /// @notice Withdraw shares and cash in LP tokens for specific token, then send tokens to caller.
    // /// @param _pid The pool id.
    // /// @param _shares The amount of shares to withdraw.
    // /// @param _token The token to cash LP tokens to - must be one of the underlying pool's base tokens.
    // /// @param _minAmount The minimum amount of _token to receive.
    // /// @return _amount The amount of _token withdrawn.
    // function withdrawSingleBaseAsset(uint256 _pid, uint256 _shares, address _token, uint256 _minAmount) external returns (uint256 _amount);

    // /// @notice Withdraw shares and cash in LP tokens for specific token, then send tokens to caller.
    // /// @param _pid The pool id.
    // /// @param _migrator The address of the pool to migrate to.
    // /// @param _recipient The recipient of the vault shares.
    // /// @param _newPid The pid of the vault to deposit into.
    // function migrate(uint256 _pid, address _migrator, address _recipient, uint256 _newPid) external;

    /// @notice Harvest the pending rewards and convert to a token that can be deposited into the vault choosen be the user.
    /// @param _pid - The pool id.
    /// @param _token - The address of the token to swap the rewards to.
    /// @param _minBounty - The minimum amount of bounty to receive.
    /// @return _amount - The amount of _token harvested after swapping all other tokens to it.
    function harvest(uint256 _pid, address _token, uint256 _minBounty) external returns (uint256 _amount);
}