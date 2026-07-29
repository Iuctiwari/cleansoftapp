# Phase 07 Build Brief — File Storage

## Schema

Implement private file metadata with tenant/branch, owner/purpose, object key, safe name/type/size/checksum, scan status, lifecycle, retention/legal-hold tags, created actor/time/version. Object key must contain environment and immutable tenant scope.

## Routes/interfaces

Implement `/files/upload-authorizations`, `/:fileId/complete`, `/:fileId/access`, delete; implement `SVC-FILE-001`, `SVC-FILE-002`, `EVT-FILE-STATUS-001`.

## Rules

- Authorize before upload and again before read/delete.
- Validate claimed/actual MIME, extension, size, checksum, metadata; quarantine until approved scan.
- Signed access shortest practical lifetime and purpose-bound.
- Domain records store file ID, never storage credentials/public URL.
- Cleanup is idempotent job and cannot delete held/referenced content.
- All access failures are tenant-safe.

## What not to build

No scanner/storage vendor selection before `OQ-20`/`OQ-31`, no customer/order/expense logic, no public files, no unsupported retention deletion.

