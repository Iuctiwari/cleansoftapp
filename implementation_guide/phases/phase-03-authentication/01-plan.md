# Phase 03 Plan — Authentication

## Scope

Credential verification, tenant/platform login contexts, access/refresh sessions, rotation/revocation, lockout, password recovery/change, invited credential initialization, and security events.

## Contracts

- **Consumes:** platform context/errors, `SVC-AUDIT-001`, `SVC-JOB-001`, durable `SVC-NOTIFY-001` contract.
- **Produces:** `SVC-AUTH-001`, `SVC-AUTH-002`, `SVC-AUTH-003`, `SVC-AUTH-004`, `SVC-AUTH-005`, `SVC-AUTH-006`, `EVT-AUTH-SESSION-REVOKED-001`, `EVT-AUTH-SECURITY-001`.

## Acceptance criteria

1. `FR-AUTH-01`: tenant and platform contexts are separate and login is anti-enumeration safe.
2. `FR-AUTH-02`: hashed rotating refresh families revoke on reuse.
3. `FR-AUTH-03`: provisional lockout behavior is deterministic and configurable pending `OQ-17`.
4. `FR-AUTH-04`: reset proof is hashed/single-use/attempt-limited and reset revokes sessions.
5. `FR-AUTH-05`: revocation contract supports lifecycle/access changes.
6. `FR-AUTH-06`: public failures do not reveal identity/tenant existence.

## Out

User profiles/RBAC, tenant policy, MFA before `OQ-15`, actual provider implementation, Flutter screens.
