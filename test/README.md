dev notes

- run specific tests:
    - 'forge test --match-contract ComplicatedContractTest --match-test testDeposit'
    - This will run the tests in the ComplicatedContractTest test contract with testDeposit in the name.
    - Inverse versions of these flags also exist (--no-match-contract and --no-match-test).

    - You can run tests in filenames that match a glob pattern with --match-path. Inverse is --no-match-path.

- github workflow:
    - https://github.com/ZeframLou/foundry-template/blob/main/.github/workflows/CI.yml
    - https://book.getfoundry.sh/config/continous-integration

- testing events:
    // set the event
    event Transfer(address indexed from, address indexed to, uint256 amount);
    // set emitter
    ExpectEmit emitter = new ExpectEmit();
    // set which topics/data to listen for - 1st 'true' is for 1st topic, 2nd 'true' is for 2nd topic, etc. 4th argument is for data (non-indexed-topics)
    vm.expectEmit(true, true, false, true);
    // The actual data of the event we expect
    emit Transfer(address(this), address(1337), 1337);
    // The event we get - which will be compared to the above data (address(this), address(1337), 1337)
    emitter.t();

- understanding traces:
    - https://book.getfoundry.sh/forge/traces

- fork testing:
    - https://book.getfoundry.sh/forge/fork-testing
    - forge test --fork-url <your_rpc_url>
    - all test functions are isolated - meaning each test function is executed with a copy of the state after "setUp" function and is executed in its own stand-alone EVM

- gas optimizations:
    - use 'Forge snapshot' https://book.getfoundry.sh/forge/gas-snapshots

- slither + Mythril:
    - https://book.getfoundry.sh/config/static-analyzers