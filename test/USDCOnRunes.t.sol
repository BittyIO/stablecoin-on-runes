// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/USDCOnRunes.sol";
import "../src/IStableCoinOnRunes.sol";
import {FiatTokenV2} from "../lib/usdc/usdc.sol";

contract USDCOnRunesTest is Test {
    USDCOnRunes public usdcor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public receiver;
    address public alice;
    address public bob;
    address public minter;
    address public feeManager;
    FiatTokenV2 public usdc;
    uint256 aliceBalance;
    uint256 mintAmount;

    function setUp() public {
        aliceBalance = _getUSDCAmount(100);
        usdc = new FiatTokenV2();
        usdc.initialize(
            "USD Coin",
            "USDC",
            "USD",
            6,
            address(this),
            address(this),
            address(this),
            address(this)
        );
        usdc.initializeV2("USD Coin");
        usdc.configureMinter(address(this), aliceBalance * 2);
        usdc.mint(address(usdc), aliceBalance);
        usdcor = new USDCOnRunes();
        usdcor.initialize(address(usdc));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        receiver = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        usdc.mint(alice, aliceBalance);
        minter = makeAddr("minter");
        feeManager = makeAddr("feeManager");
        mintAmount = _getUSDCAmount(99);
        usdcor.grantRole(usdcor.FEE_MANAGER_ROLE(), address(feeManager));
        usdcor.grantRole(usdcor.MINTER_ROLE(), address(minter));
        vm.prank(feeManager);
        usdcor.setMintFee(_getUSDCAmount(2));
        vm.prank(feeManager);
        usdcor.setRedeemFee(_getUSDCAmount(2));
        vm.prank(feeManager);
        usdcor.setFeeReceiver(address(this));
    }

    function testSetReceiverRoleError() public {
        vm.expectRevert();
        usdcor.setFeeReceiver(receiver);
    }

    function testMinterRoleError() public {
        vm.expectRevert();
        usdcor.mint(bitcoinAddress, _getUSDCAmount(1));
    }

    function testSetReceiverWithRightRole() public {
        vm.prank(address(this));
        assertTrue(
            usdcor.hasRole(usdcor.FEE_MANAGER_ROLE(), address(feeManager))
        );
        vm.prank(feeManager);
        usdcor.setFeeReceiver(receiver);
        assertEq(usdcor.getFeeReceiver(), receiver);
    }

    function testSetMinterWithRightRole() public {
        vm.prank(address(this));
        assertTrue(
            usdcor.hasRole(usdcor.FEE_MANAGER_ROLE(), address(feeManager))
        );
        vm.prank(feeManager);
        usdcor.setFeeReceiver(receiver);
        assertEq(usdcor.getFeeReceiver(), receiver);
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getUSDCAmount(11);
        vm.expectRevert(USDCOnRunes.SetMintFeeOverLimit.selector);
        vm.prank(feeManager);
        usdcor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getUSDCAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.MintFeeUpdated(mintFee);
        vm.prank(feeManager);
        usdcor.setMintFee(mintFee);
        assertEq(usdcor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getUSDCAmount(11);
        vm.expectRevert(USDCOnRunes.SetRedeemFeeOverLimit.selector);
        vm.prank(feeManager);
        usdcor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getUSDCAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.RedeemFeeUpdated(redeemFee);
        vm.prank(feeManager);
        usdcor.setRedeemFee(redeemFee);
        assertEq(usdcor.getRedeemFee(), redeemFee);
    }

    function testMintAmountLessThanMintFee() public {
        uint256 usdcMintAmount = usdcor.getMintFee() - 1;
        vm.expectRevert(USDCOnRunes.MintAmountLessThanMintFee.selector);
        usdcor.mint(bitcoinAddress, usdcMintAmount);
    }

    function testMintUSDCOnRunes() public {
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Minted(
            alice,
            bitcoinAddress,
            mintAmount,
            usdcor.getMintFee()
        );
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 mintFee = usdcor.getMintFee();
        assertEq(usdc.balanceOf(alice), aliceBalance - mintAmount);
        assertEq(usdc.balanceOf(address(usdcor)), mintAmount - mintFee);
        assertEq(usdc.balanceOf(address(this)), mintFee);
    }

    function testRedeemLessThanRedeemFee() public {
        vm.prank(feeManager);
        usdcor.setFeeReceiver(receiver);
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = usdcor.getRedeemFee() - 1;
        vm.prank(minter);
        usdcor.redeem(bitcoinTxId, bob, redeemAmount);
        assertEq(usdc.balanceOf(bob), 0);
        assertEq(usdc.balanceOf(receiver), redeemAmount + usdcor.getMintFee());
        assertEq(
            usdc.balanceOf(address(usdcor)),
            mintAmount - usdcor.getMintFee() - redeemAmount
        );
    }

    function testRedeemUSDCOnRunes() public {
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = mintAmount - usdcor.getMintFee();
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Redeemed(
            bitcoinTxId,
            alice,
            redeemAmount,
            usdcor.getRedeemFee()
        );
        vm.prank(minter);
        usdcor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(
            usdc.balanceOf(alice),
            aliceBalance - usdcor.getMintFee() - usdcor.getRedeemFee()
        );
        assertEq(usdc.balanceOf(address(usdcor)), 0);
        assertEq(
            usdc.balanceOf(address(this)),
            usdcor.getRedeemFee() + usdcor.getMintFee()
        );
    }

    function testRedeemSameBitcoinTxId() public {
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        vm.prank(minter);
        usdcor.redeem(bitcoinTxId, alice, mintAmount);
        vm.expectRevert(USDCOnRunes.BitcoinTxAlreadySent.selector);
        vm.prank(minter);
        usdcor.redeem(bitcoinTxId, alice, mintAmount);
    }

    function _getUSDCAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e6;
    }
}
