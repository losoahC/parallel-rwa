// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RWA20} from "../src/RWA20.sol";
import "../src/Compliance.sol";

contract RWA20Test is Test {
    RWA20 token;
    Compliance comp;

    function setUp() public {
        comp = new Compliance(address(this));
        token = new RWA20("ParallelRWA", "PRWA", address(this), address(comp));
    }

    function _makeAddrs(uint256 n) internal pure returns (address[] memory a) {
        a = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            a[i] = address(uint160(uint256(keccak256(abi.encodePacked("INV", i)))));
        }
    }

    function _makeAmts(uint256 n, uint256 base) internal pure returns (uint256[] memory x, uint256 sum) {
        x = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            uint256 v = base + i;
            x[i] = v;
            sum += v;
        }
    }

    function test_batchMint_batchRedeem_100() public {
        uint256 n = 100;
        address[] memory inv = _makeAddrs(n);
        (uint256[] memory amt, uint256 sum) = _makeAmts(n, 1e18);

        uint256 g0 = gasleft();
        for (uint256 i = 0; i < n; i++) {
            comp.setWhitelisted(inv[i], true);
        }
        token.batchMint(inv, amt);
        emit log_named_uint("gas.batchMint(100)", g0 - gasleft());

        assertEq(token.totalSupply(), sum);

        address[] memory from = new address[](50);
        uint256[] memory ramt = new uint256[](50);
        uint256 rsum = 0;

        for (uint256 i = 0; i < 50; i++) {
            from[i] = inv[i];
            ramt[i] = amt[i] / 2;
            rsum += ramt[i];
        }

        g0 = gasleft();
        token.batchRedeem(from, ramt);
        emit log_named_uint("gas.batchRedeem(50)", g0 - gasleft());

        assertEq(token.totalSupply(), sum - rsum);

        for (uint256 i = 0; i < 50; i++) {
            assertEq(token.balanceOf(inv[i]), amt[i] - ramt[i]);
        }
    }

    function test_onlyIssuer() public {
        address attacker = address(0xBEEF);
        address[] memory inv = _makeAddrs(1);
        uint256[] memory amt = new uint256[](1);
        amt[0] = 1e18;

        vm.prank(attacker);
        vm.expectRevert("NOT_ISSUER");
        // Could not reach
        token.batchMint(inv, amt);
    }

    function test_mint_blocked_by_compliance() public {
        address bob = address(0xB);

        // bob not whitelisted
        address[] memory inv = new address[](1);
        inv[0] = bob;
        uint256[] memory amt = new uint256[](1);
        amt[0] = 100;

        vm.expectRevert(abi.encodeWithSelector(RWA20.ComplianceFailed.selector, uint8(2)));
        token.batchMint(inv, amt);
    }
}
