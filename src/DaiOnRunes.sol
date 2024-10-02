// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IDaiOnRunes} from "./IDaiOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 * @dev Interface for minting Dai to Bitcoin Runes, redeeming it back to Ethereum, and managing fees
 */
contract DaiOnRunes is IDaiOnRunes, Ownable, ERC165, Initializable {
    uint256 private mintFee;
    uint256 private redeemFee;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IDaiOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    function initialize(uint256 mintFee_, uint256 redeemFee_) public initializer {
        mintFee = mintFee_;
        redeemFee = redeemFee_;
    }

    /**
     * @notice Mint Dai to Bitcoin Runes
     * @dev For gas efficiency, this function does not validate the Bitcoin address.
     * Validate your Bitcoin address before minting to avoid loss of funds.
     * @param bitcoinAddress The Bitcoin address for receiving the Dai on Bitcoin Runes
     * @param amount The amount of Dai to mint
     */
    function mint(string calldata bitcoinAddress, uint256 amount) external {}

    /**
     * @notice Redeem Dai back to an Ethereum address (owner only)
     * @dev Users send Dai on Bitcoin Runes to the official redeem Bitcoin address with
     * op_return containing the Ethereum address for receiving Dai. Only the owner's
     * multi-sig address can call this function to redeem Dai back to the user's Ethereum address.
     * @param bitcoinTxId The Bitcoin transaction ID of the redeem transaction
     * @param receiver The Ethereum address for receiving the Dai
     * @param amount The amount of Dai to redeem
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner {}

    /**
     * @notice Set the mint fee (owner only)
     * @dev If the mint fee is n Dai, user will receive (mint_amount - n) Dai on Bitcoin Runes.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new mint fee to set
     */
    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }

    /**
     * @notice Set the redeem fee (owner only)
     * @dev If the redeem fee is n Dai, user will receive (redeem_amount - n) Dai on Ethereum.
     * There will be a max fee hard coded in the contract to limit the power of contract owner.
     * @param newFee The new redeem fee to set
     */
    function setRedeemFee(uint256 newFee) external onlyOwner {
        redeemFee = newFee;
    }

    /**
     * @notice Withdraw the accumulated mint and redeem fees (owner only)
     * @dev For each redeem and mint operation, the fee will be added to this contract to be withdrawn by the contract owner.
     */
    function withdrawFee() external onlyOwner {}

    /**
     * @notice Get the current mint fee
     * @return The current mint fee
     */
    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

    /**
     * @notice Get the current redeem fee
     * @return The current redeem fee
     */
    function getRedeemFee() external view returns (uint256) {
        return redeemFee;
    }
}
