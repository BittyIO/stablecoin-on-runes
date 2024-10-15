// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IUSDCOnRunes} from "./IUSDCOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {FiatTokenV2} from "../lib/usdc/usdc.sol";

/**
 * @title Bridge USDT on EVMs to Bitcoin Runes
 */
contract USDCOnRunes is IUSDCOnRunes, Ownable, ERC165, Initializable, ReentrancyGuard {
    error MintAmountLessThanMintFee();
    error WithdrawAmountMoreThanFee();
    error SetMintFeeOverLimit();
    error SetRedeemFeeOverLimit();

    uint256 constant MAX_FEE = 10 * 1e6;

    uint256 private mintFee;
    uint256 private redeemFee;
    address private feeReceiver;
    FiatTokenV2 private usdc;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IUSDCOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice set diffrent fee for different networks
     */
    function initialize(address usdcContract_, uint256 fee_, address feeReceiver_) public initializer {
        usdc = FiatTokenV2(usdcContract_);
        mintFee = fee_;
        redeemFee = fee_;
        feeReceiver = feeReceiver_;
        usdc.approve(address(this), type(uint256).max);
    }

    function mint(string calldata bitcoinAddress, uint256 amount) external nonReentrant {
        if (amount <= mintFee) {
            revert MintAmountLessThanMintFee();
        }
        usdc.transferFrom(msg.sender, address(this), amount);
        usdc.transferFrom(address(this), feeReceiver, mintFee);
        emit Minted(msg.sender, bitcoinAddress, amount, mintFee);
    }

    /**
     * @notice No one can stop people send redeem tx on Bitcoin, if redeem amount less than redeem fee, user will receive nothing and the redeem money will be kept as fee.
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner nonReentrant {
        if (amount <= redeemFee) {
            emit Redeemed(bitcoinTxId, receiver, 0, amount);
            return;
        }
        usdc.transferFrom(address(this), receiver, amount - redeemFee);
        usdc.transferFrom(address(this), feeReceiver, redeemFee);
        emit Redeemed(bitcoinTxId, receiver, amount, redeemFee);
    }

    // should be a role for FeeManager to set this
    function setReceiver(address receiver) external onlyOwner {
        feeReceiver = receiver;
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
