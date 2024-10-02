// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";
import "../src/IDaiOnRunes.sol";

contract DaiOnRunesTest is Test {
    DaiOnRunes public dor;
    address public delegate;

    function setUp() public {
        dor = new DaiOnRunes();
        dor.initialize(0, 0);
        delegate = makeAddr("delegate");
    }

    function testSetMintFee() public {
        uint256 fee = 10;
        dor.setMintFee(fee);
        assertEq(dor.getMintFee(), fee);
    }
}
