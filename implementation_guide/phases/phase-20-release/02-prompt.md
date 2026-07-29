# Phase 20 Build Brief — Controlled Release

## Objective

Release only verified implemented scope. Preserve the existing release-governance and completion-report methodology.

## Required release packet

- Approved scope/version and FR/contract coverage.
- Phase status/audit index and defect/risk/open-question disposition.
- Migration/rollback and recovery results.
- Security/isolation/financial/performance/accessibility evidence.
- API/mobile compatibility and store rollout plan.
- Artifact checksums/provenance, configuration version, release notes.
- Owners for support, alerts, providers, rollback, communications.

## Execution

1. Verify evidence against repository/runtime, not completion claims alone.
2. Block on missing/failed required evidence.
3. Deploy staged cohort/environment using Phase 19 process.
4. Run smoke, contract, tenant-isolation, payment, queue/projection, mobile compatibility checks.
5. Observe approved window/thresholds.
6. Expand, pause, or roll back according to explicit authority.
7. Record factual outcome and limitations append-only.

## What not to build

No new feature, emergency policy invention, acceptance by silence, hidden failed check, history rewrite, or unapproved production expansion.

