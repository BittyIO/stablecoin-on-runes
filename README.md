# a contract to bridge stable

//deposit DAI to contract
- deposit(amount)

//query the DAI balance of an address
- balanceOf(eth_address)

//withdraw DAI to ethereum address
- withdraw(ethereum_address, amount)

//mint DAI to bitcoin Runes
- mint(amount, btc_address)

//redeem DAI to ethereum address, ownerOnly
- redeem(redeem_bitcoin_tx, ethereum_address, amount)
