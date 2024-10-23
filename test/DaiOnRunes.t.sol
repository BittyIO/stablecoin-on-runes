// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";
import "../src/IStableCoinOnRunes.sol";

contract DaiOnRunesTest is Test {
    DaiOnRunes public dor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public receiver;
    address public alice;
    address public bob;
    address public minter;
    address public feeManager;
    Dai public dai;
    uint256 aliceBalance;
    uint256 mintAmount;

    function setUp() public {
        dai = new Dai(11155111);
        dor = new DaiOnRunes();
        dor.initialize(address(dai));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        receiver = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        minter = makeAddr("minter");
        feeManager = makeAddr("feeManager");
        aliceBalance = _getDaiAmount(100);
        dai.mint(alice, aliceBalance);
        mintAmount = _getDaiAmount(99);
        dor.grantRole(dor.FEE_MANAGER_ROLE(), address(feeManager));
        dor.grantRole(dor.MINTER_ROLE(), address(minter));
        vm.prank(feeManager);
        dor.setMintFee(_getDaiAmount(2));
        vm.prank(feeManager);
        dor.setRedeemFee(_getDaiAmount(2));
        vm.prank(feeManager);
        dor.setFeeReceiver(address(this));
    }

    function testSetReceiverRoleError() public {
        vm.expectRevert();
        dor.setFeeReceiver(receiver);
    }

    function testMinterRoleError() public {
        vm.expectRevert();
        dor.mint(bitcoinAddress, _getDaiAmount(1));
    }

    function testSetReceiverWithRightRole() public {
        vm.prank(address(this));
        assertTrue(dor.hasRole(dor.FEE_MANAGER_ROLE(), address(feeManager)));
        vm.prank(feeManager);
        dor.setFeeReceiver(receiver);
        assertEq(dor.getFeeReceiver(), receiver);
    }

    function testSetMinterWithRightRole() public {
        vm.prank(address(this));
        assertTrue(dor.hasRole(dor.FEE_MANAGER_ROLE(), address(feeManager)));
        vm.prank(feeManager);
        dor.setFeeReceiver(receiver);
        assertEq(dor.getFeeReceiver(), receiver);
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getDaiAmount(11);
        vm.expectRevert(DaiOnRunes.SetMintFeeOverLimit.selector);
        vm.prank(feeManager);
        dor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getDaiAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.MintFeeUpdated(mintFee);
        vm.prank(feeManager);
        dor.setMintFee(mintFee);
        assertEq(dor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getDaiAmount(11);
        vm.expectRevert(DaiOnRunes.SetRedeemFeeOverLimit.selector);
        vm.prank(feeManager);
        dor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getDaiAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IStableCoinOnRunes.RedeemFeeUpdated(redeemFee);
        vm.prank(feeManager);
        dor.setRedeemFee(redeemFee);
        assertEq(dor.getRedeemFee(), redeemFee);
    }

    function testMintAmountLessThanMintFee() public {
        uint256 daiMintAmount = dor.getMintFee() - 1;
        vm.expectRevert(DaiOnRunes.MintAmountLessThanMintFee.selector);
        dor.mint(bitcoinAddress, daiMintAmount);
    }

    function testMintDaiOnRunes() public {
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Minted(alice, bitcoinAddress, mintAmount, dor.getMintFee());
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        uint256 mintFee = dor.getMintFee();
        assertEq(dai.balanceOf(alice), aliceBalance - mintAmount);
        assertEq(dai.balanceOf(address(dor)), mintAmount - mintFee);
        assertEq(dai.balanceOf(address(this)), mintFee);
    }

    function testRedeemLessThanRedeemFee() public {
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = dor.getRedeemFee() - 1;
        vm.prank(minter);
        dor.redeem(bitcoinTxId, bob, redeemAmount);
        assertEq(dai.balanceOf(bob), 0);
        assertEq(dai.balanceOf(address(dor)), mintAmount - dor.getRedeemFee());
        assertEq(dai.balanceOf(address(this)), dor.getRedeemFee());
    }

    function testRedeemDaiOnRunes() public {
        vm.prank(alice);
        dai.approve(address(dor), mintAmount);
        vm.prank(alice);
        dor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = mintAmount - dor.getMintFee();
        vm.expectEmit(true, true, true, true);
        emit IStableCoinOnRunes.Redeemed(bitcoinTxId, alice, redeemAmount, dor.getRedeemFee());
        vm.prank(minter);
        dor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(dai.balanceOf(alice), aliceBalance - dor.getMintFee() - dor.getRedeemFee());
        assertEq(dai.balanceOf(address(dor)), 0);
        assertEq(dai.balanceOf(address(this)), dor.getRedeemFee() + dor.getMintFee());
    }

    function _getDaiAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e18;
    }
}
