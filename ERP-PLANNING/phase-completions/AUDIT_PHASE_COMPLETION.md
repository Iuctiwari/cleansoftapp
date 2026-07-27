# Cross-Phase Audit Completion Report

Use this report for the independent audit selected by AUDIT_PHASE_PROMPT.md. Replace the guidance with factual evidence and retain every required heading.

## Phase Number

AUDIT — record the canonical numbered phase audited and the source revision.

## Summary

Record the audit target, evidence set, overall decision of PASS, PASS WITH CONDITIONS, or FAIL, and the highest-severity finding.

## Completed Features

List the target phase deliverables that were independently verified. Do not repeat unverified completion claims.

## Files Created

List files created by the audit itself. An evidence-only audit should normally report only this updated audit report or `None`.

## Files Modified

List files modified by the audit itself. The audited implementation must not be changed.

## Architectural Decisions

Record architecture-conformance observations and any remediation decision that requires an ADR; the audit does not approve the decision.

## Security Considerations

Record security checks, negative-test evidence, findings, residual risk, and secret-redaction confirmation without including sensitive values.

## Testing Performed

Record exact commands, environments, results, skipped/unavailable checks, and repository-relative artifact evidence.

## Known Limitations

Record limitations of audit scope or evidence and their effect on confidence. Write `None` only when the audit was complete and reproducible.

## Pending Work

List every failed criterion/finding requiring remediation, with severity, evidence, owner or required authority, and next safe action. Write `None` only for an unconditional PASS.

## Notes for Next Phase

State whether the next phase may start, conditions that must first be satisfied, evidence to recheck, and cross-phase risks to preserve.

## Acceptance Evidence Matrix

For every audited acceptance criterion, record the result, repository-relative evidence, reproduced command or inspection, and associated finding.

## Findings

For every finding, record severity, violated criterion/standard, evidence, impact, smallest safe remediation, and release/next-phase effect.
