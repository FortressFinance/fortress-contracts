# FROM ubuntu:22.04

# for M1/M2 Macs
FROM --platform=linux/amd64 ubuntu:22.04

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.foundry/bin

# install dependencies
RUN apt-get update && apt-get install curl git build-essential sudo apt-transport-https software-properties-common python3 python3-pip -y

# setup solc and slither
RUN sudo apt-get update \
 && pip3 install slither-analyzer solc-select \
 && solc-select install 0.8.17 \
 && solc-select use 0.8.17

# install foundry
RUN apt-get update \
 && curl -L https://foundry.paradigm.xyz | bash \
 && foundryup

WORKDIR /fortress-contracts

# USAGE:
# docker build -t fortress-contracts .
# docker run -it --rm -v $(pwd):/fortress-contracts fortress-contracts

# NOTES:
# 1. update Foundry dependencies with `forge update lib/forge-std`
# 2. resolve https://github.com/paritytech/substrate/issues/1070 with `curl https://sh.rustup.rs -sSf | sh -s -- -y`