// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

/**
 * @title Bridge USDT on EVMs to Bitcoin Runes
 * @dev Interface for minting USDT to Bitcoin Runes, redeeming it back to Ethereum, and managing fees
 */
interface IUSDTOnRunes {
    /**
     * @dev Emitted when USDT is minted to Bitcoin Runes
     * @param from The Ethereum address initiating the mint
     * @param bitcoinAddress The Bitcoin address receiving the minted USDT
     * @param amount The amount of USDT minted
     * @param fee The fee charged for minting
     */
    event Minted(address indexed from, string indexed bitcoinAddress, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when USDT is redeemed back to Ethereum
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address receiving the redeemed USDT
     * @param amount The amount of USDT redeemed
     * @param fee The fee charged for redeeming
     */
    event Redeemed(string indexed bitcoinTxId, address indexed receiver, uint256 amount, uint256 fee);

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
     * @dev Emitted when fees are withdrawn by the owner
     * @param amount The amount of fees withdrawn
     * @param to The address to receive the fee
     */
    event FeesWithdrawn(uint256 amount, address indexed to);

    /**
     * @notice Mint USDT to Bitcoin Runes
     * @dev For gas efficiency, this function does not validate the Bitcoin address.
     * Validate your Bitcoin address before minting to avoid loss of funds.
     * @param bitcoinAddress The Bitcoin address for receiving the USDT on Bitcoin Runes
     * @param amount The amount of USDT to mint
     */
    function mint(string calldata bitcoinAddress, uint256 amount) external;

    /**
     * @notice Redeem USDT back to an Ethereum address (owner only)
     * @dev Users send USDT on Bitcoin Runes to the official redeem Bitcoin address with
     * op_return containing the Ethereum address for receiving USDT. Only the owner's
     * multi-sig address can call this function to redeem USDT back to the user's Ethereum address.
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address for receiving the USDT
     * @param amount The amount of USDT to redeem
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external;

    /**
     * @notice Set fee receiver (owner only)
     * @param receiver The Ethereum address for receiving the fee
     */
    function setReceiver(address receiver) external;

    /**
     * @notice Set the mint fee (owner only)
     * @dev If the mint fee is n USDT, user will receive (mint_amount - n) USDT on Bitcoin Runes.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new mint fee to set
     */
    function setMintFee(uint256 newFee) external;

    /**
     * @notice Set the redeem fee (owner only)
     * @dev If the redeem fee is n USDT, user will receive (redeem_amount - n) USDT on Ethereum.
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
}
