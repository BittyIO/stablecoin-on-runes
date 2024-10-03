// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";
import "../src/IDaiOnRunes.sol";

contract DaiOnRunesTest is Test {
    DaiOnRunes public dor;
    uint256 public fee;
    string public bitcoinAddress;
    string public bitcoinTxId;
    address public recevier;

    function setUp() public {
        fee = 20;
        dor = new DaiOnRunes();
        dor.initialize(fee);
        bitcoinAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bitcoinTxId = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16";
        recevier = makeAddr("receiver");
    }

    function testSetMintFee() public {
        uint256 mintFee = 10;
        dor.setMintFee(mintFee);
        assertEq(dor.getMintFee(), mintFee);
    }

    function testSetRedeemFee() public {
        uint256 redeemFee = 10;
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
        dor.mint(bitcoinAddress, mintFee + 1);
        dor.redeem(bitcoinTxId, recevier, redeemFee + 1);
        assertEq(dor.getFee(), mintFee + redeemFee);
    }

    function testWithdrawMoreFee() public {
        assertEq(dor.getFee(), 0);
        uint256 mintFee = dor.getMintFee();
        uint256 redeemFee = dor.getRedeemFee();
        dor.mint(bitcoinAddress, mintFee + 1);
        dor.redeem(bitcoinTxId, recevier, redeemFee + 1);
        vm.expectRevert("withdraw amount more than fee");
        dor.withdrawFee(mintFee + redeemFee + 1);
    }
}
