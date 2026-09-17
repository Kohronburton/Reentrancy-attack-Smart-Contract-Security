# Security Review Checklist

This checklist is the repeatable review method used by the lab.

## 1. Scope and architecture
- Inventory contracts, inherited code, proxies, libraries, off-chain signers, oracles, bridges, and privileged roles.
- Identify assets at risk and every entry/exit path for value.
- Record deployment assumptions and supported chains.

## 2. Authorization
- Review ownership and role administration.
- Verify every privileged state change.
- Reject `tx.origin` as an authorization primitive.
- Check initialization and upgrade authorization.

## 3. External interactions
- Apply checks-effects-interactions where appropriate.
- Evaluate reentrancy across functions and contracts.
- Check all low-level call return values.
- Treat token callbacks and fallback functions as untrusted control flow.

## 4. Signatures and replay
- Bind signatures to the intended contract and chain.
- Include nonce / expiry when authorization is single-use or time-bounded.
- Verify signer recovery and malleability handling with a maintained library.

## 5. Arithmetic and accounting
- Verify units, rounding, share conversions, fee paths, and boundary conditions.
- Compare internal accounting with actual token/native balances.

## 6. Economic assumptions
- Identify manipulable spot prices and thin-liquidity dependencies.
- Review flash-loan sensitivity and atomic state transitions.
- Validate slippage, deadlines, and minimum-out protections.

## 7. Testing and evidence
- Add a deterministic proof of concept for confirmed material findings.
- Add a regression test for every remediation.
- Run static analysis, but do not treat tool output as a substitute for manual review.

## 8. Reporting
Each finding should include severity, affected component, impact, likelihood, evidence, remediation, and retest status.
