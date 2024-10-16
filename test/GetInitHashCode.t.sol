// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";

contract GetInitCodeHashTest is Test {
    function testGetInitCodeHash() public pure {
        bytes memory bytecode = type(DaiOnRunes).creationCode;
        console.logBytes32(keccak256(abi.encodePacked(bytecode)));
    }
}
