// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IStableCoinOnRunes} from "./IStableCoinOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

interface USDTInterface {
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
}

/**
 * @title Bridge USDT on EVMs to Bitcoin Runes
 */
contract USDTOnRunes is
    IStableCoinOnRunes,
    Ownable2Step,
    ERC165,
    Initializable,
    ReentrancyGuard,
    AccessControl
{
    error MintAmountLessThanMintFee();
    error WithdrawAmountMoreThanFee();
    error SetMintFeeOverLimit();
    error SetRedeemFeeOverLimit();
    error BitcoinTxAlreadySent();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    uint256 constant MAX_FEE = 10 * 1e6;

    uint256 private mintFee;
    uint256 private redeemFee;
    address private feeReceiver;
    USDTInterface private usdt;

    mapping(bytes32 => bool) private isBitcoinTxSent;
    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IStableCoinOnRunes).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    constructor() {
        transferOwnership(tx.origin);
    }

    function initialize(address usdtContract_) public initializer {
        usdt = USDTInterface(usdtContract_);
        usdt.approve(address(this), type(uint256).max);
        _setRoleAdmin(FEE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Since bitcoin tx send Runes to users need transaction fee so mintFee should not be 0.
     */
    function mint(
        string calldata bitcoinAddress,
        uint256 amount
    ) external nonReentrant {
        if (amount <= mintFee) {
            revert MintAmountLessThanMintFee();
        }
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.transferFrom(address(this), feeReceiver, mintFee);
        emit Minted(msg.sender, bitcoinAddress, amount, mintFee);
    }

    /**
     * @notice No one can stop people send redeem tx on Bitcoin, if redeem amount less than redeem fee, user will receive nothing and the redeem money will be kept as fee, since bitcoin tx need fee so redeemFee should not be 0.
     */
    function redeem(
        string calldata bitcoinTxId,
        address receiver,
        uint256 amount
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        bytes32 bitcoinTxIdHash = keccak256(abi.encodePacked(bitcoinTxId));
        require(!isBitcoinTxSent[bitcoinTxIdHash], BitcoinTxAlreadySent());
        if (amount <= redeemFee) {
            usdt.transferFrom(address(this), feeReceiver, amount);
            isBitcoinTxSent[bitcoinTxIdHash] = true;
            emit Redeemed(bitcoinTxId, receiver, amount, amount);
            return;
        }
        usdt.transferFrom(address(this), receiver, amount - redeemFee);
        usdt.transferFrom(address(this), feeReceiver, redeemFee);
        isBitcoinTxSent[bitcoinTxIdHash] = true;
        emit Redeemed(bitcoinTxId, receiver, amount, redeemFee);
    }

    function setFeeReceiver(
        address receiver
    ) external onlyRole(FEE_MANAGER_ROLE) {
        feeReceiver = receiver;
    }

    function getFeeReceiver() external view returns (address) {
        return feeReceiver;
    }

    function setMintFee(uint256 newFee) external onlyRole(FEE_MANAGER_ROLE) {
        if (newFee > MAX_FEE) {
            revert SetMintFeeOverLimit();
        }
        mintFee = newFee;
        emit MintFeeUpdated(newFee);
    }

    function setRedeemFee(uint256 newFee) external onlyRole(FEE_MANAGER_ROLE) {
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
