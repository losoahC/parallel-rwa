/*

0 = SUCCESS
1 = SENDER_NOT_WHITELISTED
2 = RECEIVER_NOT_WHITELISTED
3 = SENDER_FROZEN
4 = RECEIVER_FROZEN

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Compliance
/// @notice Minimal compliance layer inspired by ERC-1404
/// @dev Only checks whitelist and freeze status

contract Compliance {
    address public admin;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public frozen;

    event Whitelisted(address indexed account, bool allowed);
    event Frozen(address indexed account, bool frozen);

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT_ADMIN");
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "ZERO_ADMIN");
        admin = _admin;
    }

    function setWhitelisted(address account, bool allowed) external onlyAdmin {
        whitelisted[account] = allowed;
        emit Whitelisted(account, allowed);
    }

    function setFrozen(address account, bool isFrozen) external onlyAdmin {
        frozen[account] = isFrozen;
        emit Frozen(account, isFrozen);
    }

    /// @notice Pre-transfer compliance check
    function canTransfer(
        address from,
        address to,
        uint256 /*amt*/
    )
        external
        view
        returns (bool allowed, uint8 reason)
    {
        if (!whitelisted[from]) {
            return (false, 1);
        }
        if (!whitelisted[to]) {
            return (false, 2);
        }
        if (frozen[from]) {
            return (false, 3);
        }
        if (frozen[to]) {
            return (false, 4);
        }
        return (true, 0);
    }
}
