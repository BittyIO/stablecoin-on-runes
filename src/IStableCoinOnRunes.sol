// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

/**
 * @title Bridge Stable Coin on EVMs to Bitcoin Runes
 * @dev Interface for minting Stable Coin to Bitcoin Runes, redeeming it back to Ethereum, and managing fees
 */
interface IStableCoinOnRunes {
    /**
     * @dev Emitted when Stable Coin is minted to Bitcoin Runes
     * @param from The Ethereum address initiating the mint
     * @param bitcoinAddress The Bitcoin address receiving the minted Stable Coin
     * @param amount The amount of Stable Coin minted
     * @param fee The fee charged for minting
     */
    event Minted(address indexed from, string bitcoinAddress, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when Stable Coin is redeemed back to Ethereum
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address receiving the redeemed Stable Coin
     * @param amount The amount of Stable Coin redeemed
     * @param fee The fee charged for redeeming
     */
    event Redeemed(string bitcoinTxId, address indexed receiver, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when the mint fee is updated
     * @param newFee The new mint fee
     */
    event MintFeeUpdated(uint256 newFee);

    /**
     * @dev Emitted when the redeem fee is updated
     * @param newFee The new redeem fee
     */
    event RedeemFeeUpdated(uint256 newFee);

    /**
     * @notice Mint Stable Coin to Bitcoin Runes
     * @dev For gas efficiency, this function does not validate the Bitcoin address.
     * Validate your Bitcoin address before minting to avoid loss of funds.
     * @param bitcoinAddress The Bitcoin address for receiving the Stable Coin on Bitcoin Runes
     * @param amount The amount of Stable Coin to mint
     */
    function mint(string calldata bitcoinAddress, uint256 amount) external;

    /**
     * @notice Redeem Stable Coin back to an Ethereum address (owner only)
     * @dev Users send Stable Coin on Bitcoin Runes to the official redeem Bitcoin address with
     * op_return containing the Ethereum address for receiving Stable Coin. Only the owner's
     * multi-sig address can call this function to redeem Stable Coin back to the user's Ethereum address.
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address for receiving the Stable Coin
     * @param amount The amount of Stable Coin to redeem
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external;

    /**
     * @notice Set fee receiver (owner only)
     * @param receiver The Ethereum address for receiving the fee
     */
    function setFeeReceiver(address receiver) external;

    /**
     * @notice Set the mint fee (owner only)
     * @dev If the mint fee is n Stable Coin, user will receive (mint_amount - n) Stable Coin on Bitcoin Runes.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new mint fee to set
     */
    function setMintFee(uint256 newFee) external;

    /**
     * @notice Set the redeem fee (owner only)
     * @dev If the redeem fee is n Stable Coin, user will receive (redeem_amount - n) Stable Coin on Ethereum.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new redeem fee to set
     */
    function setRedeemFee(uint256 newFee) external;

    /**
     * @notice Get the current mint fee
     * @return The current mint fee
     */
    function getMintFee() external view returns (uint256);

    /**
     * @notice Get the current redeem fee
     * @return The current redeem fee
     */
    function getRedeemFee() external view returns (uint256);

    /**
     * @notice Get fee receiver
     * @return The current fee receiver
     */
    function getFeeReceiver() external view returns (address);
}
