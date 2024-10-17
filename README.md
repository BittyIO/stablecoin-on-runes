# Stable Coin On Runes

## Introduction

Stable Coin on Runes is a project that bridges USDT/USDC/Dai-on-EVM to Bitcoin Runes. As [Bitty](https://bitty.io) started with lending, and users need to borrow USDT, USDC, Dai against their assets, we've created Dai on Runes to meet this demand.

## Features

### User Functions

- **[mint](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L53)**: Allows users to mint Dai on Runes.

### Contract Owner Function

- **[redeem](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L64)**: Enables the contract owner to redeem Dai.
- **[setMintFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L72)**: Allows the owner to set the fee for minting.
- **[setRedeemFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L80)**: Allows the owner to set the fee for redeeming.
- **[withdrawFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L94)**: Enables the owner to withdraw accumulated fees.

### Read Functions

- **[getFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L86)**: Retrieves the current fee information.
- **[getMintFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L100)**: Gets the current minting fee.
- **[getRedeemFee](https://github.com/BittyIO/dai-on-runes/blob/main/src/IDaiOnRunes.sol#L106)**: Gets the current redeeming fee.

## Bitcoin Runes for Dai On Runes

This section is currently under development. More information will be provided in future updates.

## Getting Started

(Add instructions on how to set up and use the project, including any prerequisites, installation steps, and basic usage examples.)

## Contributing

(Add guidelines for how others can contribute to the project, including coding standards, pull request process, etc.)

## License

(Specify the license under which this project is released.)

## Contact

(Provide contact information or links for users to get support or ask questions about the project.)
