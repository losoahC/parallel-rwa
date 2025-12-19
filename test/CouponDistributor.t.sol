// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/CouponDistributor.sol";

contract MockUSDC {
    string public constant name = "MockUSDC";
    string public constant symbol = "USDC";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "INSUFFICIENT");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balanceOf[from] >= amt, "INSUFFICIENT");
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        return true;
    }
}

contract CouponDistributorTest is Test {
    CouponDistributor dist;
    MockUSDC usdc;

    address issuer = address(this);

    function setUp() public {
        usdc = new MockUSDC();
        dist = new CouponDistributor(issuer, address(usdc));
    }

    function test_batchCouponDistribution() public {
        address[] memory holders = new address[](3);
        holders[0] = address(0xA);
        holders[1] = address(0xB);
        holders[2] = address(0xC);

        uint256[] memory coupons = new uint256[](3);
        coupons[0] = 100;
        coupons[1] = 200;
        coupons[2] = 300;

        usdc.mint(issuer, 1000);
        usdc.transfer(address(dist), 600);

        dist.batchDistribute(holders, coupons);

        assertEq(usdc.balanceOf(holders[0]), 100);
        assertEq(usdc.balanceOf(holders[1]), 200);
        assertEq(usdc.balanceOf(holders[2]), 300);
    }
}
