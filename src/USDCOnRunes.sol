// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IStableCoinOnRunes} from "./IStableCoinOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {FiatTokenV2} from "../lib/usdc/usdc.sol";

/**
 * @title Bridge USDC on EVMs to Bitcoin Runes
 */
contract USDCOnRunes is IStableCoinOnRunes, Ownable2Step, ERC165, Initializable, ReentrancyGuard, AccessControl {
    error MintAmountLessThanMintFee();
    error WithdrawAmountMoreThanFee();
    error SetMintFeeOverLimit();
    error SetRedeemFeeOverLimit();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    uint256 constant MAX_FEE = 10 * 1e6;

    uint256 private mintFee;
    uint256 private redeemFee;
    address private feeReceiver;
    FiatTokenV2 private usdc;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, AccessControl) returns (bool) {
        return interfaceId == type(IStableCoinOnRunes).interfaceId || super.supportsInterface(interfaceId);
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
        usdc.transferFrom(msg.sender, address(this), amount);
        usdc.transferFrom(address(this), feeReceiver, mintFee);
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
        if (amount <= redeemFee) {
            emit Redeemed(bitcoinTxId, receiver, 0, amount);
            return;
        }
        usdc.transferFrom(address(this), receiver, amount - redeemFee);
        usdc.transferFrom(address(this), feeReceiver, redeemFee);
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
