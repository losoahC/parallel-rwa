// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title RWA20 (MVP)
/// @notice Minimal RWA Tokenization workflow
/// @author Haolun Wu

interface ICompliance {
    function canTransfer(address from, address to, uint256 amt) external view returns (bool allowed, uint8 reason);
}

contract RWA20 {
    // Event
    event Transfer(address indexed from, address indexed to, uint256 amt);
    event IssuerChanged(address indexed from, address indexed to);

    // Error
    error ComplianceFailed(uint8 reason);

    // State
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    ICompliance public compliance;

    // ERC20 State
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // Issuer
    address public issuer;

    // Modifier
    modifier onlyIssuer() {
        require(msg.sender == issuer, "NOT_ISSUER");
        _;
    }

    // Constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address _issuer,
        address _compliance // decoupling
    ) {
        require(_issuer != address(0), "ZERO_ISSUER");
        name = _name;
        symbol = _symbol;
        issuer = _issuer;
        compliance = ICompliance(_compliance);
        emit IssuerChanged(address(0), _issuer);
    }

    // Setter
    function setIssuer(address newIssuer) external onlyIssuer {
        require(newIssuer != address(0), "ZERO_ISSUER");
        issuer = newIssuer;
        emit IssuerChanged(issuer, newIssuer);
    }

    // Transfer
    function tansfer(address from, address to, uint256 amt) external returns (bool) {
        _transfer(from, to, amt);
        return true;
    }

    function _transfer(address from, address to, uint256 amt) internal {
        require(to != address(0), "ZERO_TO");

        _checkCompliance(from, to, amt);

        uint256 bal = balanceOf[from];
        require(bal >= amt, "INSUFFICIENT_BAL");
        unchecked {
            balanceOf[from] -= amt;
            balanceOf[to] += amt;
        }
        emit Transfer(from, to, amt);
    }

    /// @notice Institutional batch issuance
    function batchMint(address[] calldata to, uint256[] calldata amt) external onlyIssuer {
        uint256 n = to.length;
        require(n == amt.length, "LEN_MISMATCH");

        uint256 sum = 0;
        for (uint256 i = 0; i < n; i++) {
            address receiver = to[i];
            require(receiver != address(0), "ZERO_TO");
            uint256 amount = amt[i];

            _checkCompliance(address(0), receiver, amount);

            sum += amount;

            balanceOf[receiver] += amount;
            emit Transfer(address(0), receiver, amount);
        }
        // change totalSupply
        totalSupply += sum;
    }

    /// @notice Institutional batch redemption/settlement (burn)
    function batchRedeem(address[] calldata from, uint256[] calldata amt) external onlyIssuer {
        uint256 n = from.length;
        require(n == amt.length, "LEN_MISMATCH");

        uint256 sum = 0;
        for (uint256 i = 0; i < n; i++) {
            address sender = from[i];
            require(sender != address(0), "ZERO_FROM");
            uint256 amount = amt[i];

            _checkCompliance(sender, address(0), amount);

            uint256 balance = balanceOf[sender];
            require(balance >= amount, "INSUFFICIENT_BAL");

            unchecked {
                balanceOf[sender] -= amount;
            }

            sum += amount;
        }
        // change totalSupply
        totalSupply -= sum;
    }

    function _checkCompliance(address from, address to, uint256 amt) internal view {
        if (address(compliance) == address(0)) return;

        (bool ok, uint8 reason) = compliance.canTransfer(from, to, amt);
        if (!ok) {
            revert ComplianceFailed(reason);
        }
    }
}
