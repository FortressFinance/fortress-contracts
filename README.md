[![Foundry][foundry-badge]][foundry]
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

# 🏰 Fortress Finance Smart Contracts

This is the main Fortress Finance public smart contract repository.


## 🔧 Set up local development environment

### Requirements

-   [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Local Setup Steps

```sh
# Clone the repository
git clone https://github.com/FortressFinance/fortress-contracts.git

# Change directory into the cloned repo
cd fortress-contracts

# Create a .env file
touch .env

# Add your mainnet RPC URL to the .env file
echo "MAINNET_RPC_URL=<YOUR_MAINNET_RPC_URL_LINK>" >> .env

# Add your mainnet RPC URL to the .env file
echo "ARBITRUM_RPC_URL=<YOUR_ARBITRUM_RPC_URL_LINK>" >> .env

# build the docker image
docker build -t fortress .

# run the image with a volume to the current working directory and enter the container
docker run -it -v "/${PWD}:/fortress-contracts" fortress bash

# build the project
forge build
```
### Running Tests

To run tests, run the following commands

```sh
# run tests
forge test

# run slither
slither .
```
## 📜 Contract Addresses

 - [Deployed Addresses](https://docs.fortress.finance/resources/smart-contracts).

## 📖 Documentation

[Documentation](http://docs.fortress.finance/).


## 💗 Contributing

Contributions are always welcome!

Come say hey in our [Discord server](https://discord.gg/HnD3JsDKGy).

