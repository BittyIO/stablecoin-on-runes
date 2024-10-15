// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/USDCOnRunes.sol";
import "../src/IUSDCOnRunes.sol";

contract USDCOnRunesTest is Test {
    USDCOnRunes public usdcor;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public recevier;
    address public alice;
    address public bob;
    FiatTokenV2 public usdc;
    uint256 aliceBalance;
    uint256 mintAmount;

    function setUp() public {
        aliceBalance = _getUSDCAmount(100);
        usdc = new FiatTokenV2();
        usdc.initialize("USD Coin", "USDC", "USD", 6, address(this), address(this), address(this), address(this));
        usdc.initializeV2("USD Coin");
        usdc.configureMinter(address(this), aliceBalance * 2);
        usdc.mint(address(usdc), aliceBalance);
        usdcor = new USDCOnRunes();
        usdcor.initialize(address(usdc), _getUSDCAmount(2), address(this));
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        recevier = makeAddr("receiver");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        usdc.mint(alice, aliceBalance);
        mintAmount = _getUSDCAmount(99);
    }

    function testSetMintFeeOverLimit() public {
        uint256 mintFee = _getUSDCAmount(11);
        vm.expectRevert(USDCOnRunes.SetMintFeeOverLimit.selector);
        usdcor.setMintFee(mintFee);
    }

    function testSetMintFee() public {
        uint256 mintFee = _getUSDCAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IUSDCOnRunes.MintFeeUpdated(mintFee);
        usdcor.setMintFee(mintFee);
        assertEq(usdcor.getMintFee(), mintFee);
    }

    function testSetRedeemFeeOverLimit() public {
        uint256 redeemFee = _getUSDCAmount(11);
        vm.expectRevert(USDCOnRunes.SetRedeemFeeOverLimit.selector);
        usdcor.setRedeemFee(redeemFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = _getUSDCAmount(1);
        vm.expectEmit(false, false, false, true);
        emit IUSDCOnRunes.RedeemFeeUpdated(redeemFee);
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
        emit IUSDCOnRunes.Minted(alice, bitcoinAddress, mintAmount, usdcor.getMintFee());
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 mintFee = usdcor.getMintFee();
        assertEq(usdc.balanceOf(alice), aliceBalance - mintAmount);
        assertEq(usdc.balanceOf(address(usdcor)), mintAmount - mintFee);
        assertEq(usdc.balanceOf(address(this)), mintFee);
    }

    function testRedeemLessThanRedeemFee() public {
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = usdcor.getRedeemFee() - 1;
        usdcor.redeem(bitcoinTxId, bob, redeemAmount);
        assertEq(usdc.balanceOf(bob), 0);
        assertEq(usdc.balanceOf(address(usdcor)), mintAmount - usdcor.getRedeemFee());
        assertEq(usdc.balanceOf(address(this)), usdcor.getRedeemFee());
    }

    function testRedeemUSDCOnRunes() public {
        vm.prank(alice);
        usdc.approve(address(usdcor), mintAmount);
        vm.prank(alice);
        usdcor.mint(bitcoinAddress, mintAmount);
        uint256 redeemAmount = mintAmount - usdcor.getMintFee();
        vm.expectEmit(true, true, true, true);
        emit IUSDCOnRunes.Redeemed(bitcoinTxId, alice, redeemAmount, usdcor.getRedeemFee());
        usdcor.redeem(bitcoinTxId, alice, redeemAmount);
        assertEq(usdc.balanceOf(alice), aliceBalance - usdcor.getMintFee() - usdcor.getRedeemFee());
        assertEq(usdc.balanceOf(address(usdcor)), 0);
        assertEq(usdc.balanceOf(address(this)), usdcor.getRedeemFee() + usdcor.getMintFee());
    }

    function _getUSDCAmount(uint256 amount) internal pure returns (uint256) {
        return amount * 1e6;
    }
}
