// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IStableCoinOnRunes} from "./IStableCoinOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

interface DaiInterface {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address usr, uint256 wad) external returns (bool);
}

/**
 * @title Bridge Dai on EVMs to Bitcoin Runes
 */
contract DaiOnRunes is IStableCoinOnRunes, Ownable2Step, ERC165, Initializable, ReentrancyGuard, AccessControl {
    error MintAmountLessThanMintFee();
    error WithdrawAmountMoreThanFee();
    error SetMintFeeOverLimit();
    error SetRedeemFeeOverLimit();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    uint256 constant MAX_FEE = 10 * 1e18;

    uint256 private mintFee;
    uint256 private redeemFee;
    address private feeReceiver;
    DaiInterface private dai;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, AccessControl) returns (bool) {
        return interfaceId == type(IStableCoinOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor() {
        transferOwnership(tx.origin);
    }

    /**
     * @notice set diffrent fee for different networks
     */
    function initialize(address daiContract_) public initializer {
        dai = DaiInterface(daiContract_);
        dai.approve(address(this), type(uint256).max);
        _setRoleAdmin(FEE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Since bitcoin tx send Runes to users need transaction fee so mintFee should not be 0.
     */
    function mint(string calldata bitcoinAddress, uint256 amount) external nonReentrant {
        if (amount <= mintFee) {
            revert MintAmountLessThanMintFee();
        }
        dai.transferFrom(msg.sender, address(this), amount);
        dai.transferFrom(address(this), feeReceiver, mintFee);
        emit Minted(msg.sender, bitcoinAddress, amount, mintFee);
    }

    /**
     * @notice No one can stop people send redeem tx on Bitcoin, if redeem amount less than redeem fee, user will receive nothing and the redeem money will be kept as fee, since bitcoin tx need fee so redeemFee should not be 0.
     */
    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount)
        external
        nonReentrant
        onlyRole(MINTER_ROLE)
    {
        if (amount <= redeemFee) {
            dai.transferFrom(address(this), feeReceiver, amount);
            emit Redeemed(bitcoinTxId, receiver, amount, amount);
            return;
        }
        dai.transferFrom(address(this), receiver, amount - redeemFee);
        dai.transferFrom(address(this), feeReceiver, redeemFee);
        emit Redeemed(bitcoinTxId, receiver, amount, redeemFee);
    }

    function setFeeReceiver(address receiver) external onlyRole(FEE_MANAGER_ROLE) {
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
