# ParallelRWA

A modular RWA tokenization framework modeling institutional workflows:
- **Batch issuance** and **batch redemption** (ownership registry)
- **Batch coupon distribution** using stablecoins (cashflow settlement)
- **Compliance gating** with whitelist/freeze and reason codes (ERC-1404 style)

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