# Stable Coin On Runes

## Introduction

Stable Coin on Runes is a project that bridges USDT/USDC/Dai-on-EVM to Bitcoin Runes. As [Bitty](https://bitty.io) started with lending, and users need to borrow USDT, USDC, Dai against their assets, we bridge Stable Coin from EVM to Runes to meet this demand.

## Features

- [mint](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L46)
- [redeem](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L57)
- [setMintFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L71)
- [getMintFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L85)
- [setRedeemFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L79)
- [getRedeemFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L91)
- [setFeeReceiver](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L63)
- [getFeeReceiver](https://github.com/BittyIO/dai-on-runes/blob/main/src/IStableCoinOnRunes.sol#L97)

## Finalized Deployment

### USDT
|Chain|Address|
|-----|-------|
|Ethereum Sepolia|[0x0000000042e019fb911C2574d934a081E6D199c8](https://sepolia.etherscan.io/address/0x0000000042e019fb911C2574d934a081E6D199c8)
|Ethereum Mainnet|[0x0000000042e019fb911C2574d934a081E6D199c8](https://etherscan.io/address/0x0000000042e019fb911C2574d934a081E6D199c8)

### USDC
|Chain|Address|
|---|---|
|Ethereum Sepolia|[0x0000000030f400f934089CE101B558999FfE74d0](https://sepolia.etherscan.io/address/0x0000000030f400f934089CE101B558999FfE74d0)
|Ethereum Mainnet|[0x0000000030f400f934089CE101B558999FfE74d0](https://etherscan.io/address/0x0000000030f400f934089CE101B558999FfE74d0)

### Dai
|Chain|Address|
|---|---|
|Ethereum Sepolia|[0x00000000946c10Cb61A08a94886003D7B199b475](https://sepolia.etherscan.io/address/0x00000000946c10Cb61A08a94886003D7B199b475)
|Ethereum Mainnet|[0x00000000946c10Cb61A08a94886003D7B199b475](https://etherscan.io/address/0x00000000946c10Cb61A08a94886003D7B199b475)

## Developers
For developers, welcome new issue or PR, check doc [here](https://github.com/BittyIO/stablecoin-on-runes/blob/main/dev.md)

## Bitcoin Runes for Stable Coin On Runes

This section is currently under development. More information will be provided in future updates.
