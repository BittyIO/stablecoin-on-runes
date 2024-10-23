// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/USDTOnRunes.sol";
import "../src/IStableCoinOnRunes.sol";
import {TetherToken} from "../lib/usdt/TetherToken.sol";

contract USDTOnRunesTest is Test {
    USDTOnRunes public usdtor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public receiver;
    address public alice;
    address public bob;
    address public minter;
    address public feeManager;
    TetherToken public usdt;
    uint256 aliceBalance;
    uint256 mintAmount;

    function setUp() public {
        aliceBalance = _getUSDTAmount(100);
        usdt = new TetherToken(aliceBalance, "Tether USD", "USDT", 6);
        usdtor = new USDTOnRunes();
        usdtor.initialize(address(usdt));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        receiver = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        usdt.transfer(alice, aliceBalance);
        minter = makeAddr("minter");
        feeManager = makeAddr("feeManager");
        mintAmount = _getUSDTAmount(99);
        usdtor.grantRole(usdtor.FEE_MANAGER_ROLE(), address(feeManager));
        usdtor.grantRole(usdtor.MINTER_ROLE(), address(minter));
        vm.prank(feeManager);
        usdtor.setMintFee(_getUSDTAmount(2));
        vm.prank(feeManager);
        usdtor.setRedeemFee(_getUSDTAmount(2));
        vm.prank(feeManager);
        usdtor.setFeeReceiver(address(this));
    }

    function testSetReceiverRoleError() public {
        vm.expectRevert();
        usdtor.setFeeReceiver(receiver);
    }

    function testMinterRoleError() public {
        vm.expectRevert();
        usdtor.mint(bitcoinAddress, _getUSDTAmount(1));
    }

    function testSetReceiverWithRightRole() public {
        vm.prank(address(this));
        assertTrue(usdtor.hasRole(usdtor.FEE_MANAGER_ROLE(), address(feeManager)));
        vm.prank(feeManager);
        usdtor.setFeeReceiver(receiver);
        assertEq(usdtor.getFeeReceiver(), receiver);
    }

    function testSetMinterWithRightRole() public {
        vm.prank(address(this));
        assertTrue(usdtor.hasRole(usdtor.FEE_MANAGER_ROLE(), address(feeManager)));
        vm.prank(feeManager);
        usdtor.setFeeReceiver(receiver);
        assertEq(usdtor.getFeeReceiver(), receiver);
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getUSDTAmount(11);
        vm.expectRevert(USDTOnRunes.SetMintFeeOverLimit.selector);
        vm.prank(feeManager);
        usdtor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getUSDTAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.MintFeeUpdated(mintFee);
        vm.prank(feeManager);
        usdtor.setMintFee(mintFee);
        assertEq(usdtor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getUSDTAmount(11);
        vm.expectRevert(USDTOnRunes.SetRedeemFeeOverLimit.selector);
        vm.prank(feeManager);
        usdtor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getUSDTAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.RedeemFeeUpdated(redeemFee);
        vm.prank(feeManager);
        usdtor.setRedeemFee(redeemFee);
        assertEq(usdtor.getRedeemFee(), redeemFee);
    }

    function testMintAmountLessThanMintFee() public {
        uint256 usdtMintAmount = usdtor.getMintFee() - 1;
        vm.expectRevert(USDTOnRunes.MintAmountLessThanMintFee.selector);
        usdtor.mint(bitcoinAddress, usdtMintAmount);
    }

    function testMintUSDTOnRunes() public {
        vm.prank(alice);
        usdt.approve(address(usdtor), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Minted(alice, bitcoinAddress, mintAmount, usdtor.getMintFee());
        vm.prank(alice);
        usdtor.mint(bitcoinAddress, mintAmount);
        uint256 mintFee = usdtor.getMintFee();
        assertEq(usdt.balanceOf(alice), aliceBalance - mintAmount);
        assertEq(usdt.balanceOf(address(usdtor)), mintAmount - mintFee);
        assertEq(usdt.balanceOf(address(this)), mintFee);
    }

    function testRedeemLessThanRedeemFee() public {
        vm.prank(alice);
        usdt.approve(address(usdtor), mintAmount);
        vm.prank(alice);
        usdtor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = usdtor.getRedeemFee() - 1;
        vm.prank(minter);
        usdtor.redeem(bitcoinTxId, bob, redeemAmount);
        assertEq(usdt.balanceOf(bob), 0);
        assertEq(usdt.balanceOf(address(usdtor)), mintAmount - usdtor.getRedeemFee());
        assertEq(usdt.balanceOf(address(this)), usdtor.getRedeemFee());
    }

    function testRedeemUSDTOnRunes() public {
        vm.prank(alice);
        usdt.approve(address(usdtor), mintAmount);
        vm.prank(alice);
        usdtor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = mintAmount - usdtor.getMintFee();
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Redeemed(bitcoinTxId, alice, redeemAmount, usdtor.getRedeemFee());
        vm.prank(minter);
        usdtor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(usdt.balanceOf(alice), aliceBalance - usdtor.getMintFee() - usdtor.getRedeemFee());
        assertEq(usdt.balanceOf(address(usdtor)), 0);
        assertEq(usdt.balanceOf(address(this)), usdtor.getRedeemFee() + usdtor.getMintFee());
    }

    function _getUSDTAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e6;
    }
}
