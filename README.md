# ParallelRWA — Modular RWA Tokenization Framework

ParallelRWA is a *compliance-aware* real-world asset (RWA) tokenization system built in Solidity using the Foundry framework. This project models a high-level institutional workflow:

- Institutional issuance and redemption in batch
- Stablecoin-backed coupon/cashflow distribution
- Compliance gating with rule reason codes
- Modular separation of concerns for auditability and upgradeability

It is designed to also serve as a benchmarkable workload for high-performance EVMs (e.g., parallel execution chains).

A modular RWA tokenization framework modeling institutional workflows:
- **Batch issuance** and **batch redemption** (ownership registry)
- **Batch coupon distribution** using stablecoins (cashflow settlement)
- **Compliance gating** with whitelist/freeze and reason codes (ERC-1404 style)

## Features
✔️ Batch issuance and redemption (RWA20)  
✔️ Compliance gating with whitelist/freeze + reason codes (ERC-1404 style)  
✔️ Stablecoin coupon distribution contract  
✔️ Modular design with separation of concerns  
✔️ Foundry tests (positive/negative) and CI integration  
✔️ Benchmark suite for evaluating gas cost by batch size

## Background
Tokenizing real-world assets (RWAs) is a critical step toward institutional-grade blockchain finance, enabling fractional ownership, liquidity, and automated settlement while respecting compliance and audit needs. Unlike simple ERC-20 demos, this framework incorporates compliance checks and cashflow payouts, mirroring real-world financial systems.

## Why this project
Institutional RWA operations are batch-heavy (allocations, redemptions, periodic coupons). ParallelRWA is designed as a clean workload to study how high-throughput EVMs can benefit from batch patterns with mostly disjoint state writes.

## Contracts
- `RWA20.sol`: ownership registry + `batchMint` / `batchRedeem` + compliance checks
- `CouponDistributor.sol`: stablecoin deposit + `batchDistribute`
- `Compliance.sol`: whitelist/freeze policy engine + `canTransfer` reason codes

## Run tests (Foundry)
```bash
forge fmt
forge test -vv
forge test -vv --match-path test/benchmark.t.sol