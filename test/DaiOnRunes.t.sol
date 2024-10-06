// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";
import "../src/IDaiOnRunes.sol";

contract DaiOnRunesTest is Test {
    DaiOnRunes public dor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public recevier;
    address public alice;
    address public bob;
    Dai public dai;

    function setUp() public {
        dai = new Dai(11155111);
        dor = new DaiOnRunes();
        dor.initialize(address(dai), 2 * 1e18);
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        recevier = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getDaiAmount(11);
        vm.expectRevert(DaiOnRunes.SetMintFeeOverLimit.selector);
        dor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getDaiAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IDaiOnRunes.MintFeeUpdated(mintFee);
        dor.setMintFee(mintFee);
        assertEq(dor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getDaiAmount(11);
        vm.expectRevert(DaiOnRunes.SetRedeemFeeOverLimit.selector);
        dor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getDaiAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IDaiOnRunes.RedeemFeeUpdated(redeemFee);
        dor.setRedeemFee(redeemFee);
        assertEq(dor.getRedeemFee(), redeemFee);
    }

    function testMintAmountLessThanMintFee() public {
        uint256 mintAmount = dor.getMintFee() - 1;
        vm.expectRevert(DaiOnRunes.MintAmountLessThanMintFee.selector);
        dor.mint(bitcoinAddress, mintAmount);
    }

    function testGetFee() public {
        assertEq(dor.getFee(), 0);
        uint256 mintFee = dor.getMintFee();
        uint256 redeemFee = dor.getRedeemFee();
        dai.mint(alice, _getDaiAmount(100));
        vm.prank(alice);
        uint256 mintAmount = mintFee * 3;
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        dor.redeem(bitcoinTxId, recevier, mintFee * 2);
        assertEq(dor.getFee(), mintFee + redeemFee);
    }

    function testWithdrawMoreFee() public {
        assertEq(dor.getFee(), 0);
        uint256 mintFee = dor.getMintFee();
        uint256 redeemFee = dor.getRedeemFee();
        dai.mint(alice, _getDaiAmount(100));
        vm.prank(alice);
        uint256 mintAmount = mintFee + 1;
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        dor.redeem(bitcoinTxId, recevier, redeemFee + 1);
        vm.expectRevert(DaiOnRunes.WithdrawAmountMoreThanFee.selector);
        dor.withdrawFee(mintFee + redeemFee + 1);
    }

    function testMintDaiOnRunes() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IDaiOnRunes.Minted(alice, bitcoinAddress, mintAmount, dor.getMintFee());
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        assertEq(dai.balanceOf(alice), _getDaiAmount(1));
        assertEq(dai.balanceOf(address(dor)), _getDaiAmount(99));
    }

    function testRedeemLessThanRedeemFee() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = dor.getRedeemFee() - 1;
        dor.redeem(bitcoinTxId, bob, redeemAmount);
        assertEq(dai.balanceOf(bob), 0);
    }

    function testRedeemDaiOnRunes() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = mintAmount - dor.getMintFee();
        vm.expectEmit(true, true, true, true);
        emit IDaiOnRunes.Redeemed(bitcoinTxId, alice, redeemAmount, dor.getRedeemFee());
        dor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(dai.balanceOf(alice), _getDaiAmount(100) - dor.getMintFee() - dor.getRedeemFee());
    }

    function testWithdrawFee() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        dor.redeem(bitcoinTxId, alice, mintAmount - dor.getMintFee());
        uint256 withdrawFee = _getDaiAmount(4);
        vm.expectEmit(false, false, false, true);
        emit IDaiOnRunes.FeesWithdrawn(withdrawFee);
        dor.withdrawFee(withdrawFee);
        assertEq(dai.balanceOf(address(this)), withdrawFee);
        assertEq(dor.getFee(), 0);
    }

    function _getDaiAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e18;
    }
}
