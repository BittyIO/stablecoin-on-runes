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
        dor.initialize(address(dai));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        recevier = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function testSetMintFee() public {
        uint256 mintFee = _getDaiAmount(10);
        dor.setMintFee(mintFee);
        assertEq(dor.getMintFee(), mintFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getDaiAmount(10);
        dor.setRedeemFee(redeemFee);
        assertEq(dor.getRedeemFee(), redeemFee);
    }

    function testMintAmountLessThanMintFee() public {
        uint256 mintAmount = dor.getMintFee() - 1;
        vm.expectRevert("mint amount less than mint fee");
        dor.mint(bitcoinAddress, mintAmount);
    }

    function testRedeemAmountLessThanRedeemFee() public {
        uint256 redeemAmount = dor.getRedeemFee() - 1;
        vm.expectRevert("redeem amount less than redeem fee");
        dor.redeem(bitcoinTxId, recevier, redeemAmount);
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
        vm.expectRevert("withdraw amount more than fee");
        dor.withdrawFee(mintFee + redeemFee + 1);
    }

    function testMintDaiOnRunes() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        assertEq(dai.balanceOf(alice), _getDaiAmount(1));
        assertEq(dai.balanceOf(address(dor)), _getDaiAmount(99));
    }

    function testRedeemDaiOnRunes() public {
        dai.mint(alice, _getDaiAmount(100));
        uint256 mintAmount = _getDaiAmount(99);
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        dor.redeem(bitcoinTxId, alice, mintAmount - dor.getMintFee());
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
	dor.withdrawFee(withdrawFee);
	assertEq(dai.balanceOf(address(this)), withdrawFee);
    }

    function _getDaiAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e18;
    }
}
