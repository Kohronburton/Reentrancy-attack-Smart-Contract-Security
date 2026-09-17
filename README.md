# Blockchain Security Lab

A modern EVM smart-contract security lab focused on reproducing common vulnerability classes, proving impact with tests, and demonstrating practical remediation.

> **Portfolio / educational use.** The repository began as a historical reentrancy exercise. The `feat/blockchain-security-lab-v1` modernization keeps that history intact while rebuilding the project as a current security-review demonstration. This is not a claim that every historical file in git history was originally authored here.

## What this lab demonstrates

| Lab | Vulnerability | Secure pattern |
| --- | --- | --- |
| Reentrancy | External value transfer before state update | Checks-effects-interactions + `ReentrancyGuard` |
| Access control | Privileged withdrawal without authorization | `Ownable` / explicit authorization |
| `tx.origin` authorization | Phishing through an intermediate contract | Authorize with `msg.sender` / ownership |
| Signature replay | Reusing a valid signed authorization | Domain separation + nonce + replay protection |
| Unchecked external call | Treating failed low-level calls as success | Check call result and revert atomically |

## Current toolchain

- Solidity `0.8.37`
- Hardhat `3.x`
- Ethers `6.x` through the Hardhat Mocha/Ethers toolbox
- OpenZeppelin Contracts `5.7.x`
- TypeScript
- Slither static analysis in CI

The Solidity version was intentionally moved to `0.8.37`, which includes important compiler bug fixes released in September 2026.

## Quick start

Prerequisite: Node.js `22.13.0+`.

```bash
npm install
npm run compile
npm test
```

Static analysis:

```bash
python -m pip install slither-analyzer solc-select
solc-select install 0.8.37
solc-select use 0.8.37
npm run slither
```

## Security-review workflow represented here

1. Establish scope and trust boundaries.
2. Identify privileged roles and value-transfer paths.
3. Run static analysis.
4. Perform manual review of authorization, state changes, signatures, external calls, and economic assumptions.
5. Reproduce material findings with a deterministic proof of concept.
6. Patch the issue using a documented secure pattern.
7. Add regression tests proving the exploit no longer succeeds.
8. Produce a severity-ranked finding with remediation and retest status.

See [`reports/SAMPLE_SECURITY_REVIEW.md`](reports/SAMPLE_SECURITY_REVIEW.md) for the client-facing reporting format and [`SECURITY.md`](SECURITY.md) for the review checklist.

## Repository layout

```text
contracts/
  access-control/
  authorization/
  external-calls/
  reentrancy/
  signatures/
test/
  security-lab.ts
reports/
  SAMPLE_SECURITY_REVIEW.md
.github/workflows/
  security-lab-ci.yml
```

## What this is — and is not

This lab is suitable as evidence of a repeatable smart-contract review process: reproduce, explain, remediate, and retest. It is not a substitute for a full production audit of a live protocol, and no repository should be deployed with real funds solely because its tests pass.

## Suggested consulting deliverables

A focused engagement built around this workflow can include:

- manual Solidity review;
- automated static analysis;
- proof-of-concept tests for confirmed findings;
- severity-ranked findings register;
- remediation patches;
- regression tests; and
- final retest / closure report.
