// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 * @dev Interface for minting Dai to Bitcoin Runes, redeeming it back to Ethereum, and managing fees
 */
interface IDaiOnRunes {
    /**
     * @dev Emitted when Dai is minted to Bitcoin Runes
     * @param from The Ethereum address initiating the mint
     * @param bitcoinAddress The Bitcoin address receiving the minted Dai
     * @param amount The amount of Dai minted
     * @param fee The fee charged for minting
     */
    event Minted(address indexed from, string indexed bitcoinAddress, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when Dai is redeemed back to Ethereum
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address receiving the redeemed Dai
     * @param amount The amount of Dai redeemed
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
     */
    event FeesWithdrawn(uint256 amount);

    /**
     * @notice Mint Dai to Bitcoin Runes
     * @dev For gas efficiency, this function does not validate the Bitcoin address.
     * Validate your Bitcoin address before minting to avoid loss of funds.
     * @param bitcoinAddress The Bitcoin address for receiving the Dai on Bitcoin Runes
     * @param amount The amount of Dai to mint
     */
    function mint(string calldata bitcoinAddress, uint256 amount) external;

    /**
     * @notice Redeem Dai back to an Ethereum address (owner only)
     * @dev Users send Dai on Bitcoin Runes to the official redeem Bitcoin address with
     * op_return containing the Ethereum address for receiving Dai. Only the owner's
     * multi-sig address can call this function to redeem Dai back to the user's Ethereum address.
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address for receiving the Dai
     * @param amount The amount of Dai to redeem
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external;

    /**
     * @notice Set the mint fee (owner only)
     * @dev If the mint fee is n Dai, user will receive (mint_amount - n) Dai on Bitcoin Runes.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new mint fee to set
     */
    function setMintFee(uint256 newFee) external;

    /**
     * @notice Set the redeem fee (owner only)
     * @dev If the redeem fee is n Dai, user will receive (redeem_amount - n) Dai on Ethereum.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new redeem fee to set
     */
    function setRedeemFee(uint256 newFee) external;

    /**
     * @notice Get the current fee
     * @return The total (mintFee + redeemFee)
     */
    function getFee() external view returns (uint256);

    /**
     * @notice Withdraw the accumulated mint and redeem fees (owner only)
     * @dev For each redeem and mint operation, the fee will be added to this contract to be withdrawn by the contract owner.
     */
    function withdrawFee(uint256 amount) external;

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
