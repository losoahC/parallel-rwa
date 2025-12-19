// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWA20.sol";
import "../src/Compliance.sol";
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

contract BenchmarkTest is Test {
    Compliance comp;
    RWA20 token;
    MockUSDC usdc;
    CouponDistributor dist;

    function setUp() public {
        comp = new Compliance(address(this));
        token = new RWA20("ParallelRWA", "PRWA", address(this), address(comp));

        usdc = new MockUSDC();
        dist = new CouponDistributor(address(this), address(usdc));
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

    function _whitelistAll(address[] memory a) internal {
        for (uint256 i = 0; i < a.length; i++) {
            comp.setWhitelisted(a[i], true);
        }
    }

    function test_benchmark_batchMint_sizes() public {
        uint256[4] memory sizes = [uint256(10), 50, 100, 300];

        for (uint256 k = 0; k < sizes.length; k++) {
            uint256 n = sizes[k];
            address[] memory inv = _makeAddrs(n);
            _whitelistAll(inv);

            (uint256[] memory amt,) = _makeAmts(n, 1e18);

            uint256 g0 = gasleft();
            token.batchMint(inv, amt);
            uint256 used = g0 - gasleft();

            emit log_named_uint(string(abi.encodePacked("gas.batchMint(", vm.toString(n), ")")), used);
        }
    }

    function test_benchmark_batchDistribute_sizes() public {
        uint256[4] memory sizes = [uint256(10), 50, 100, 300];

        for (uint256 k = 0; k < sizes.length; k++) {
            uint256 n = sizes[k];
            address[] memory holders = _makeAddrs(n);

            (uint256[] memory coupons, uint256 sum) = _makeAmts(n, 1_000); // 1000.. coupon units (6 decimals not enforced here)

            // fund distributor
            usdc.mint(address(this), sum);
            usdc.transfer(address(dist), sum);

            uint256 g0 = gasleft();
            dist.batchDistribute(holders, coupons);
            uint256 used = g0 - gasleft();

            emit log_named_uint(string(abi.encodePacked("gas.batchDistribute(", vm.toString(n), ")")), used);
        }
    }
}
