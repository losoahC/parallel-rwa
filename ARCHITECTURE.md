# ParallelRWA Architecture

## Overview
ParallelRWA is a modular smart-contract framework modeling an institutional RWA lifecycle:
- **Ownership registry** (tokenized asset units)
- **Cashflow distribution** (coupon/interest settlement)
- **Compliance gate** (eligibility & transfer restrictions)

Design goal: keep modules **decoupled** so each concern is auditable, replaceable, and testable—aligned with how real financial market infrastructure separates **asset records** and **settlement/rules**.

---

## Modules and Responsibilities

### 1) RWA20 (Ownership Registry)
**Responsibilities**
- Tracks ownership via `balanceOf` and `totalSupply`
- Institutional workflows:
  - `batchMint()` for issuance/allocation
  - `batchRedeem()` for redemption/settlement (burn)

**Non-goals**
- Does not implement cashflow logic (interest payments)
- Does not embed compliance rules; it only calls a compliance interface

### 2) CouponDistributor (Cashflow / Settlement)
**Responsibilities**
- Holds stablecoin liquidity (e.g., USDC-like ERC20)
- Distributes coupons/interest in batch:
  - `deposit()` loads settlement liquidity
  - `batchDistribute()` performs batch payouts

**Why separate from token?**
- Cashflow rules change frequently (rate model, frequency, currency).
- Separating settlement from ownership improves auditability and allows upgrades without migrating the core asset registry.

### 3) Compliance (Rules Engine)
**Responsibilities**
- Encodes minimal eligibility restrictions:
  - whitelist (KYC/eligibility)
  - freeze (risk controls / disputes / sanctions)
- Provides ERC-1404-style pre-check:
  - `canTransfer(from, to, amount) -> (allowed, reasonCode)`

**Why reason codes?**
In institutional systems, “rejected transaction” is not a system failure; it must be explainable for ops, compliance, and audit.

---

## Integration Flow (Pre-Trade / Pre-Settlement Checks)

RWA20 enforces compliance by calling the compliance module before state changes:

- **Mint / issuance:** `from = address(0)`  
  Only checks recipient eligibility (receiver whitelist/freeze).
- **Redeem / burn:** `to = address(0)`  
  Only checks holder eligibility (sender whitelist/freeze).
- **Transfer:** checks both sender and receiver.

This mirrors real workflows where issuance/redemption are gated by investor eligibility and risk controls.

---

## Parallel-Friendly Batch Design (Why high-throughput EVMs matter)
Institutional workflows (allocations, redemptions, coupon payouts) are inherently **batch-heavy**. The batch functions update balances for many distinct addresses:

- Writes are largely to independent storage slots (`balanceOf[addr]` per investor).
- This pattern is favorable for EVMs that can exploit parallelism when state access does not conflict.

**Ethereum mainnet executes transactions sequentially**, so batch scale is limited by per-tx gas constraints and throughput.
**High-throughput parallel EVM L1s** can benefit from workloads where each batch element touches disjoint state.

> Note: actual throughput depends on the execution engine, state access scheduling, and contention patterns. This project is designed to be a clean benchmarkable workload for such environments.

---

## Security & Audit Considerations
- Clear separation of concerns reduces audit surface area per module.
- Admin roles:
  - issuer/admin can mint/redeem, deposit/distribute coupons, and update compliance lists.
- Production hardening (out of scope for MVP):
  - Access control libraries (RBAC)
  - Pausable/emergency stops
  - Accounting invariants & event indexing
  - Rate limiting / batch size caps to avoid exceeding gas limits
  - Stablecoin `transfer` return-value checks for non-standard tokens

---

## Extensibility
- Replace `Compliance` with a stricter policy engine (e.g., jurisdiction rules, investor caps).
- Add document registry (ERC-1400-like) for off-chain legal docs.
- Add NAV / price-based redemption.
- Add operator/custodian roles (institutional custody workflows).