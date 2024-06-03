# Proveably Random Raffle Contract

## About

This Code is to Create a Proveably Random Smart Contract

## That we want it to do?

1. Users can inter by paying for a ticket

   1. The ticket Fee is going to go to the winner.

2. After X amount of time the lottery is Automatically draw Lottery.

   1. and this will be done programaticaly.

3. Using Chainlink VRF and Chainlink Automation
   1. Chainlink VRF for -> Randomeness
   2. Chainlink Automation -> Time base Trigger.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
