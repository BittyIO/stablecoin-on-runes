# How to run the project
Install [foundry](https://book.getfoundry.sh/)

- build
```
forge build
```

- test
```
forge test 
```

- gas-report
```
forge test --gas-report
```

- format code
install [prettier-solidity](https://github.com/prettier-solidity/prettier-plugin-solidity)

```
npx prettier --write --plugin=prettier-plugin-solidity 'src/**/*.sol' 'test/**/*.sol'
```

- get salt by [create2crunch](https://github.com/0age/create2crunch) and change it in [deploy usdt script](https://github.com/BittyIO/stabecoin-on-runes/blob/main/script/deploy.usdt.s.sol#L23), [deploy usdc script](https://github.com/BittyIO/stabecoin-on-runes/blob/main/script/deploy.usdc.s.sol#L23), [deploy dai script](https://github.com/BittyIO/stabecoin-on-runes/blob/main/script/deploy.dai.s.sol#L23)


- deploy

```
forge script --broadcast -vvvv --rpc-url {rpc_url} \
    --private-key {private_key} \
    --etherscan-api-key {ethercan_api_key} \
    script/deploy.usdt(usdc,dai).s.sol:Deploy
```

- verify

```
forge verify-contract \
    --chain-id {chain_id} \
    {contract_address} \
    --etherscan-api-key {ethercan_api_key} \
    src/{contract}.sol:{contract}
```

- verify-check
```
forge verify-check {GUID} \
    --etherscan-api-key {ethercan_api_key} \
    --chain-id {chain_id}
```

- initialize with stablecoin address
  - USDT
      - Sepolia testnet: ```0x7169d38820dfd117c3fa1f22a697dba58d90ba06```
      - Mainnet: ```0xdac17f958d2ee523a2206206994597c13d831ec7```

  - USDC
      - Sepolia testnet: ```0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238```
      - Mainnet: ```0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48```

  - Dai
      - Sepolia testnet: ```0x00000003e70d172083eE05BE31607F24F17d8492```
      - Mainnet: ```0x6b175474e89094c44da98b954eedeac495271d0f```
