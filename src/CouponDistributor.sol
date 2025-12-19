// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC20 interface (stablecoin-like)
interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);

    function transferFrom(address from, address to, uint256 amt) external returns (bool);
}

/// @title CouponDistributor
/// @notice Distributes batch coupon/interest payment for RWA owners
contract CouponDistributor {
    // State
    address public issuer;
    IERC20 public immutable stablecoin;

    // Event
    event Deposited(address indexed from, uint256 amt);
    event CouponPaid(address indexed to, uint256 amt);

    // Modifier
    modifier onlyIssuer() {
        require(msg.sender == issuer, "NOT_ISSUER");
        _;
    }

    constructor(address _issuer, address _stablecoin) {
        require(_issuer != address(0), "ZERO_ISSUER");
        require(_stablecoin != address(0), "ZERO_STABLECOIN");
        issuer = _issuer;
        stablecoin = IERC20(_stablecoin);
    }

    /// @notice Issuer deposits stablecoin for future coupon distribution
    function deposit(uint256 amt) external onlyIssuer {
        require(amt > 0, "ZERO_AMOUNT");
        stablecoin.transferFrom(msg.sender, address(this), amt);
        emit Deposited(msg.sender, amt);
    }

    /// @notice Batch coupon distribution
    function batchDistribute(address[] calldata holders, uint256[] calldata coupons) external onlyIssuer {
        uint256 n = holders.length;
        require(n == coupons.length, "LEN_MISMATCH");

        for (uint256 i = 0; i < n; i++) {
            address holder = holders[i];
            uint256 coupon = coupons[i];
            require(holder != address(0));
            if (coupon == 0) continue;

            stablecoin.transfer(holder, coupon);
            emit CouponPaid(holder, coupon);
        }
    }
}
