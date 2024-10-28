// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/DaiOnRunes.sol";
import "../src/USDTOnRunes.sol";
import "../src/USDCOnRunes.sol";

contract GetInitCodeHashTest is Test {
    function testGetUSDTInitCodeHash() public pure {
        bytes memory bytecode = type(USDTOnRunes).creationCode;
        console.logBytes32(keccak256(abi.encodePacked(bytecode)));
    }

    function testGetUSDCInitCodeHash() public pure {
        bytes memory bytecode = type(USDCOnRunes).creationCode;
        console.logBytes32(keccak256(abi.encodePacked(bytecode)));
    }

    function testGetDaiInitCodeHash() public pure {
        bytes memory bytecode = type(DaiOnRunes).creationCode;
        console.logBytes32(keccak256(abi.encodePacked(bytecode)));
    }

    function testGetRole() public pure {
        bytes32 minterRole = keccak256("MINTER_ROLE");
        console.logBytes32(minterRole);
        bytes32 feeManagerRole = keccak256("FEE_MANAGER_ROLE");
        console.logBytes32(feeManagerRole);
    }
}
