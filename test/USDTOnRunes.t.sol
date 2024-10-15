// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/USDTOnRunes.sol";
import "../src/IUSDTOnRunes.sol";

contract USDTOnRunesTest is Test {
    USDTOnRunes public usdtor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public recevier;
    address public alice;
    address public bob;
    TetherToken public usdt;
    uint256 aliceBalance;
    uint256 mintAmount;

    function setUp() public {
        aliceBalance = _getUSDTAmount(100);
        usdt = new TetherToken(aliceBalance, "Tether USD", "USDT", 6);
        usdtor = new USDTOnRunes();
        usdtor.initialize(address(usdt), _getUSDTAmount(2), address(this));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        recevier = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        usdt.transfer(alice, aliceBalance);
        mintAmount = _getUSDTAmount(99);
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getUSDTAmount(11);
        vm.expectRevert(USDTOnRunes.SetMintFeeOverLimit.selector);
        usdtor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getUSDTAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IUSDTOnRunes.MintFeeUpdated(mintFee);
        usdtor.setMintFee(mintFee);
        assertEq(usdtor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getUSDTAmount(11);
        vm.expectRevert(USDTOnRunes.SetRedeemFeeOverLimit.selector);
        usdtor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getUSDTAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IUSDTOnRunes.RedeemFeeUpdated(redeemFee);
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
        emit IUSDTOnRunes.Minted(alice, bitcoinAddress, mintAmount, usdtor.getMintFee());
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
        emit IUSDTOnRunes.Redeemed(bitcoinTxId, alice, redeemAmount, usdtor.getRedeemFee());
        usdtor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(usdt.balanceOf(alice), aliceBalance - usdtor.getMintFee() - usdtor.getRedeemFee());
        assertEq(usdt.balanceOf(address(usdtor)), 0);
        assertEq(usdt.balanceOf(address(this)), usdtor.getRedeemFee() + usdtor.getMintFee());
    }

    function _getUSDTAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e6;
    }
}
