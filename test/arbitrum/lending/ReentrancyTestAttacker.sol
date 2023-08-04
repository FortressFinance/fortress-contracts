// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IBalancerV2StablePool} from "src/shared/lending/interfaces/IBalancerV2StablePool.sol";
import {IBalancerVault} from "src/shared/lending/interfaces/IBalancerVault.sol";

interface Oracle {
    function latestRoundData() external returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract ReentrancyTestAttacker  {

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    IBalancerVault _vault = IBalancerVault(address(0xBA12222222228d8Ba445958a75a0704d566BF2C8));
    bytes32 _poolId;
    address[] _tokens;
    int256 lastPrice;
    Oracle oracle;

    constructor(address _oracle) {
        _poolId = IBalancerV2StablePool(address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f)).getPoolId();
        (_tokens,,) = _vault.getPoolTokens(_poolId);
        oracle = Oracle(_oracle);
    }

    function execReentrancy(uint _amount) external payable {
        IERC20(WETH).approve(address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), _amount);
        uint256[] memory _amounts = new uint256[](2);
        _amounts[1] = _amount;

        _vault.joinPool{value : msg.value}(
                    _poolId,
                    address(this), // sender
                    address(this), // recipient
                    IBalancerVault.JoinPoolRequest({
                        assets: _tokens,
                        maxAmountsIn: _amounts,
                        userData: abi.encode(
                            IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                            _amounts, // amountsIn
                            0 // minimumBPT
                        ),
                        fromInternalBalance: false
                    })
                );
        // _vault.exitPool(
        //             _poolId,
        //             address(this), // sender
        //             payable(address(this)), // recipient
        //             IBalancerVault.ExitPoolRequest({
        //                 assets: _tokens,
        //                 minAmountsOut: _amounts,
        //                 userData: abi.encode(
        //                     IBalancerVault.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT,
        //                     _amounts, 
        //                     1 //token index
        //                 ),
        //                 toInternalBalance: false
        //             })
        //         );
    }
    
    fallback() external payable {
        (,lastPrice,,,) = oracle.latestRoundData();
    }

    function getLastPrice() external view returns(uint256) {
        return uint256(lastPrice);
    }
}