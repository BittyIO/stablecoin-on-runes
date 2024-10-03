// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IDaiOnRunes} from "./IDaiOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 */
contract DaiOnRunes is IDaiOnRunes, Ownable, ERC165, Initializable {
    uint256 private mintFee;
    uint256 private redeemFee;
    uint256 private fee;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IDaiOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    function initialize(uint256 fee) public initializer {
        mintFee = fee;
        redeemFee = fee;
    }

    function mint(string calldata bitcoinAddress, uint256 amount) external {
        require(amount > mintFee, "mint amount less than mint fee");
        fee += mintFee;
    }

    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner {
        require(amount > redeemFee, "redeem amount less than redeem fee");
        fee += redeemFee;
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        require(amount <= fee, "withdraw amount more than fee");
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }

    function setRedeemFee(uint256 newFee) external onlyOwner {
        redeemFee = newFee;
    }

    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

    function getRedeemFee() external view returns (uint256) {
        return redeemFee;
    }
}
