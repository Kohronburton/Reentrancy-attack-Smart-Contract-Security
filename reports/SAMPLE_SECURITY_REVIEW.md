# Sample Smart Contract Security Review

**Assessment type:** Focused manual review + automated analysis + remediation retest  
**Environment:** Local Hardhat simulation  
**Status:** Demonstration report for portfolio use

## Executive summary

The reviewed demonstration system intentionally contains several common smart-contract security defects. The assessment reproduced each material issue, documented the underlying trust failure, implemented a secure counterpart, and added regression coverage.

This sample shows the reporting format used for a focused pre-audit or remediation engagement. It is not a certification and should not be represented as a third-party audit of a live protocol.

## Severity model

- **Critical:** direct, practical loss or irreversible control compromise at protocol scale.
- **High:** material loss or privilege compromise with realistic preconditions.
- **Medium:** meaningful security or accounting impact requiring additional conditions.
- **Low:** limited impact, hardening gap, or defense-in-depth weakness.
- **Informational:** maintainability, clarity, or best-practice observation.

## Findings register

| ID | Severity | Finding | Demonstrated remediation |
| --- | --- | --- | --- |
| LAB-01 | High | Reentrancy in native-asset withdrawal | CEI + `ReentrancyGuard` |
| LAB-02 | High | Missing authorization on treasury sweep | Owner-gated privileged function |
| LAB-03 | High | `tx.origin` used for authorization | `msg.sender`-based ownership |
| LAB-04 | High | Signed authorization can be replayed | Contract/chain domain + nonce |
| LAB-05 | Medium | Low-level call result ignored | Revert on failed call before state success |

## LAB-01 — Reentrancy in withdrawal

**Impact:** An attacker contract can recursively withdraw before the victim contract clears the attacker’s recorded balance, draining funds belonging to other depositors.

**Evidence:** `VulnerableBank.withdraw()` performs the external value transfer before setting `balanceOf[msg.sender]` to zero. `ReentrancyAttacker.receive()` re-enters while sufficient victim balance remains.

**Remediation:** Clear internal accounting before transferring control and protect the withdrawal path with OpenZeppelin `ReentrancyGuard`.

**Retest:** The exploit drains `VulnerableBank`; the same exploit reverts against `SecureBank`, and victim funds remain in the contract.

## LAB-02 — Missing access control

**Impact:** Any address can invoke the treasury sweep function and redirect the entire balance.

**Remediation:** Restrict the sweep operation to an explicitly administered owner/role and validate the recipient.

## LAB-03 — `tx.origin` authorization

**Impact:** The legitimate owner can be induced to call an attacker-controlled intermediary that passes the `tx.origin` check and receives the vault balance.

**Remediation:** Authenticate the immediate caller (`msg.sender`) through an ownership or role model.

## LAB-04 — Signature replay

**Impact:** A valid signed claim can be submitted repeatedly because the authorization is neither scoped to a specific contract/chain nor consumed by a nonce.

**Remediation:** Bind the digest to contract address and chain ID, include a nonce, and mark that nonce consumed before value transfer.

## LAB-05 — Unchecked low-level call

**Impact:** Business state records a payment as successful even when the recipient rejected the transfer.

**Remediation:** Check the boolean return value and revert the transaction when the transfer fails so state and value movement remain atomic.

## Recommended production review extensions

A live engagement should extend beyond these demonstrations to include upgradeability, token-standard edge cases, oracle design, economic manipulation, privileged-key architecture, initialization, MEV assumptions, denial of service, precision/rounding, storage layout, chain-specific behavior, dependency provenance, deployment scripts, and operational controls.
