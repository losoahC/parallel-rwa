// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Compliance.sol";

contract ComplianceTest is Test {
    Compliance comp;
    address admin = address(this);

    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        comp = new Compliance(admin);
    }

    function test_whitelist_required() public {
        comp.setWhitelisted(alice, true);

        (bool ok, uint8 reason) = comp.canTransfer(alice, bob, 100);
        assertFalse(ok);
        assertEq(reason, 2); // receiver not whitelisted
    }

    function test_frozen_blocks_transfer() public {
        comp.setWhitelisted(alice, true);
        comp.setWhitelisted(bob, true);
        comp.setFrozen(alice, true);

        (bool ok, uint8 reason) = comp.canTransfer(alice, bob, 100);
        assertFalse(ok);
        assertEq(reason, 3); // sender frozen
    }

    function test_success() public {
        comp.setWhitelisted(alice, true);
        comp.setWhitelisted(bob, true);

        (bool ok, uint8 reason) = comp.canTransfer(alice, bob, 100);
        assertTrue(ok);
        assertEq(reason, 0);
    }
}
