// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IDaiOnRunes} from "./IDaiOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Dai} from "../lib/dss/src/dai.sol";

/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 */
contract DaiOnRunes is IDaiOnRunes, Ownable, ERC165, Initializable, ReentrancyGuard {
    error MintAmountLessThanMintFee();
    error WithdrawAmountMoreThanFee();
    error SetMintFeeOverLimit();
    error SetRedeemFeeOverLimit();

    uint256 constant MAX_FEE = 10 * 1e18;

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

    /**
     * @notice set diffrent fee for different networks
     */
    function initialize(address daiContract_, uint256 fee_) public initializer {
        dai = Dai(daiContract_);
        mintFee = fee_;
        redeemFee = fee_;
    }

    function mint(string calldata bitcoinAddress, uint256 amount) external nonReentrant {
        if (amount <= mintFee) {
            revert MintAmountLessThanMintFee();
        }
        fee += mintFee;
        dai.transferFrom(msg.sender, address(this), amount);
        emit Minted(msg.sender, bitcoinAddress, amount, mintFee);
    }

    /**
     * @notice No one can stop people send redeem tx on Bitcoin, if redeem amount less than redeem fee, user will receive nothing and the redeem money will be kept as fee.
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner nonReentrant {
        if (amount <= redeemFee) {
            emit Redeemed(bitcoinTxId, receiver, 0, amount);
            fee += amount;
            return;
        }
        fee += redeemFee;
        dai.transferFrom(address(this), receiver, amount - redeemFee);
        emit Redeemed(bitcoinTxId, receiver, amount, redeemFee);
    }

    function withdrawFee(uint256 amount) external onlyOwner nonReentrant {
        if (amount > fee) {
            revert WithdrawAmountMoreThanFee();
        }
        dai.transferFrom(address(this), owner(), amount);
        fee -= amount;
        emit FeesWithdrawn(amount);
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function setMintFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_FEE) {
            revert SetMintFeeOverLimit();
        }
        mintFee = newFee;
        emit MintFeeUpdated(newFee);
    }

    function setRedeemFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_FEE) {
            revert SetRedeemFeeOverLimit();
        }
        redeemFee = newFee;
        emit RedeemFeeUpdated(newFee);
    }

    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

    function getRedeemFee() external view returns (uint256) {
        return redeemFee;
    }
}
