// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

/**
 * @title Bridge Ethereum DAI to Bitcoin Runes
 * @dev
 */
interface IDaiOnRunes {
  
    // @notice Emitted when minting DAI to Bitcoin Runes
    event minted(address indexed from, string bitcoinAddress);

    // @notice Emitted when redeeming DAI back to Ethereum
    event redeemed(address indexed to, address indexed receiver, uint256 amount);

    /**
     * @notice Mint DAI to Bitcoin Runes
     * Revert if the bitcoin address is invalid
     *
     * @param bitcoinAddress The Bitcoin address for receiving the DAI on Bitcoin Runes
     */
    function mint(string bitcoinAddress) external

    /**
     * @notice Redeem amount of DAI back to the Ethereum address, ownerOnly
     * People send DAI on Bitcoin Runes to the official redeem bitcoin address with op_return of the ethereum address for receiving DAI on etherum, ownerOnly multi-sig address use this function to redeem DAI in this contract back to the user ethereum address
     *
     * @param bitcoinTxId The Bitcoin transaction id of the redeem transaction
     * @param addr The address for receiving the DAI on ethereum
     * @param amount The amount for redeem the DAI
     */
    function redeem(string bitcoinTxId, address addr, uint256 amount) external;
}
