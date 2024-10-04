// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IDaiOnRunes} from "./IDaiOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Dai} from "../lib/dss/src/dai.sol";

/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 */
contract DaiOnRunes is IDaiOnRunes, Ownable, ERC165, Initializable {
    uint256 private mintFee;
    uint256 private redeemFee;
    uint256 private fee;
    Dai private dai;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IDaiOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    function initialize(address daiContract_) public initializer {
        dai = Dai(daiContract_);
        mintFee = 2 * 1e18;
        redeemFee = 2 * 1e18;
    }

    function mint(string calldata bitcoinAddress, uint256 amount) external {
        require(amount > mintFee, "mint amount less than mint fee");
        fee += mintFee;
        uint256 balance = dai.balanceOf(msg.sender);
        dai.transferFrom(msg.sender, address(this), amount);
    }

    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner {
        require(amount > redeemFee, "redeem amount less than redeem fee");
        fee += redeemFee;
        dai.transferFrom(address(this), receiver, amount - redeemFee);
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        require(amount <= fee, "withdraw amount more than fee");
        dai.transferFrom(address(this), owner(), amount);
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
