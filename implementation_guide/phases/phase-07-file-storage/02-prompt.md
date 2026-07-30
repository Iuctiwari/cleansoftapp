````text
# Implementation Prompt 07 — File Storage Module (`src/files/`)

Implement a standalone File Storage module for the Nexoraa CleanSoft NestJS/MongoDB backend, consumed internally by all other modules (Orders, Payments, Deliveries, Expenses, Customers, Reports, Settings, and any future modules) — never exposing storage URLs to clients or domain records.

CORE PRINCIPLE

Domain documents (orders.items.itemImage, deliveries.proofImage, expenses.attachment, payments.receipts.pdfUrl, tenantSettings.logoUrl, and similar fields across all modules) store ONLY a `fileId` (ObjectId reference to the `files` collection), never a raw URL, object key, signed URL, or storage credential.

Every file read must go through an authenticated, authorized, purpose-bound, short-lived signed access URL generated on demand by the File Storage module.

The storage backend must be fully abstracted behind a `StorageProvider` interface so that storage providers can be replaced without changing any business module.

Business modules must never communicate directly with storage providers. Only the File Storage module (through FileService) is responsible for storage interactions and secure access resolution.

---

## 1. SCHEMA — Collection: `files`

Create a `files` collection containing:

- `_id`
- `tenantId` (required)
- `branchId` (nullable)
- `ownerUserId`
- `purpose` (Logo, ItemImage, ProofOfDelivery, ExpenseAttachment, Receipt, Other)
- `objectKey`
  - Format:
    `{environment}/{tenantId}/{purpose}/{uuid}.{extension}`
  - Generated only by the server.
  - Immutable.
  - Never accepted from the client.
- `originalName` (sanitized)
- `mimeType`
- `detectedMimeType`
- `extension`
- `sizeBytes`
- `checksumSha256`
- `scanStatus`
  - Pending
  - Clean
  - Infected
  - Failed
- `status`
  - PendingUpload
  - Uploaded
  - Scanning
  - Active
  - Quarantined
  - Deleted
- `retentionPolicy`
- `legalHold`
- `linkedTo`
  - module
  - recordId
- `createdBy`
- `createdAt`
- `updatedAt`
- `version` (optimistic concurrency)

Indexes:

- `{ tenantId, status }`
- `{ objectKey }` (unique)
- `{ scanStatus }`
- `{ legalHold }`

---

## 2. STORAGE ABSTRACTION (Provider Agnostic)

Create a `StorageProvider` interface exposing:

- generateUploadUrl()
- generateDownloadUrl()
- deleteObject()
- headObject()

For this phase:

- Implement ONLY a `LocalStorageProvider` or `MockStorageProvider`.
- Do NOT integrate AWS S3, Azure Blob, Google Cloud Storage, Cloudflare R2, MinIO, or any cloud provider.

The architecture must allow future providers to be plugged in simply by implementing the `StorageProvider` interface.

No business module should ever import or depend on any storage provider.

---

## 3. API ENDPOINTS

All endpoints require:

- JWT Authentication
- RBAC Authorization
- Tenant Isolation
- Branch Isolation
- Existing Validation Pipeline
- Existing Exception Handling

### POST `/files/upload-authorizations`

Responsibilities:

- Validate purpose
- Validate MIME type
- Validate extension
- Validate file size
- Generate objectKey
- Create metadata document with `PendingUpload`
- Return

```json
{
  "fileId": "...",
  "uploadUrl": "...",
  "expiresAt": "..."
}
```

Generate upload URLs only through the `StorageProvider`.

Create Audit Log:

- UploadAuthorized

---

### POST `/files/:fileId/complete`

Responsibilities:

- Verify uploaded object
- Verify checksum
- Verify detected MIME
- Verify file size
- Reject mismatches
- Move lifecycle to Scanning
- Trigger mock scan job

Create Audit Log:

- UploadCompleted

---

### GET `/files/:fileId/access`

Responsibilities:

- Re-authorize caller
- Validate tenant ownership
- Validate branch
- Validate linked record
- Ensure file is
  - Active
  - ScanStatus = Clean
- Generate temporary signed access URL
- Never expose
  - objectKey
  - storage path
  - storage credentials

TTL:

- 60–300 seconds

Audit:

- AccessGranted
- AccessDenied

---

### DELETE `/files/:fileId`

Responsibilities:

- Soft Delete
- Reject if
  - Legal Hold
  - Retention not expired

Audit:

- Deleted

---

## 4. INTERNAL SERVICE INTERFACES

### SVC-FILE-001

attachFile()

Responsibilities

- Validate tenant
- Validate file ownership
- Validate status
- Validate purpose
- Attach fileId to business record

Audit

- FileAttached

---

### SVC-FILE-002

resolveAccessUrl()

Used internally for

- Reports
- Receipts
- PDF Generation
- Background jobs

Returns

Temporary signed URL through the StorageProvider.

---

### EVT-FILE-STATUS-001

Emit events whenever

- Pending
- Clean
- Infected
- Deleted
- Quarantined
- Failed

Allow Notifications, Audit, and other modules to react.

---

## 5. SCANNING (Mock)

Implement a mock scanning service.

The scanner should simulate

Pending

↓

Scanning

↓

Clean / Infected / Failed

without integrating any real malware scanner.

Future scanners (ClamAV or others) must plug into the same interface without changing

- APIs
- Schema
- Business modules

---

## 6. RULES TO ENFORCE

- Validate at Upload Authorization and again at Access.
- Never trust previous authorization.
- Validate MIME.
- Validate Extension.
- Validate Size.
- Validate Checksum.
- Mismatches become Quarantined.
- Files never become Active until ScanStatus = Clean.
- Generate signed URLs only through StorageProvider.
- Never log signed URLs.
- Never persist signed URLs.
- Generate objectKey only on the server.
- Cleanup jobs must be idempotent.
- Skip Legal Hold files.
- Skip linked files.
- Audit every important action.
- Never leak cross-tenant information.
- Every business module stores only fileId.
- Never store storage URLs.
- Never store objectKeys.
- Never store signed URLs.
- Never store storage credentials.

---

## 7. BUILD ORDER

1. Create Schema.
2. Create StorageProvider Interface.
3. Implement LocalStorageProvider / MockStorageProvider.
4. Implement Upload Authorization.
5. Implement Upload Completion.
6. Implement Access Endpoint.
7. Implement Mock Scan Lifecycle.
8. Emit File Events.
9. Implement Delete.
10. Implement Cleanup Cron.
11. Wire SVC-FILE-001 into one module (Deliveries).
12. Document integration for all remaining modules.
13. Ensure future storage providers (AWS S3, Azure Blob, MinIO, Cloudflare R2, Google Cloud Storage, etc.) can be added by implementing only the StorageProvider interface without modifying business modules.

---

## 8. TESTING

Implement

- Unit Tests
- Integration Tests
- Security Tests
- Tenant Isolation Tests
- RBAC Tests
- Upload Authorization Tests
- Upload Completion Tests
- MIME Validation Tests
- Checksum Validation Tests
- Signed URL Tests
- Lifecycle State Machine Tests
- Event Emission Tests
- Audit Logging Tests
- Cleanup Job Tests
- Idempotency Tests

---

## 9. OUT OF SCOPE

Do NOT implement

- AWS S3 integration
- Azure Blob integration
- Google Cloud Storage integration
- Cloudflare R2 integration
- MinIO integration
- Any real malware scanner
- Public file URLs
- Business logic outside the File module
- Client-specific retention policies not yet defined

---

## 10. ARCHITECTURE GUARANTEES

- Fully provider-agnostic architecture.
- Business modules store only fileId references.
- Business modules never communicate with storage providers.
- Storage providers can be replaced without changing any business module.
- All file access flows through FileService.
- Follow SOLID principles.
- Follow Clean Architecture.
- Follow existing NestJS project conventions.
- Integrate with existing JWT authentication, RBAC, Audit Logging, Validation, Exception Filters, and Response Interceptors.
- Compile successfully without TypeScript errors.
- Integrate without breaking existing functionality.

---

## 11. ACCEPTANCE CRITERIA

The implementation is considered complete only when all of the following conditions are satisfied:

- The File Storage module integrates seamlessly into the existing NestJS application without modifying or breaking existing business logic.
- The project builds and compiles successfully with zero TypeScript compilation errors or runtime startup errors.
- All APIs follow the existing project standards for authentication, authorization, validation, exception handling, response formatting, logging, and error handling.
- Every database operation enforces strict tenant isolation and branch isolation.
- All business modules (Orders, Deliveries, Payments, Expenses, Customers, Reports, Settings, and future modules) store only `fileId` references and never store storage URLs, object keys, signed URLs, or storage credentials.
- All upload, download, delete, and internal access operations pass through the File Storage module and never communicate directly with storage providers.
- The StorageProvider abstraction allows any future storage provider (AWS S3, Azure Blob, Google Cloud Storage, Cloudflare R2, MinIO, etc.) to be integrated without modifying the File Storage module or any business module.
- Mock scanning correctly simulates the complete lifecycle (Pending → Scanning → Clean/Infected/Failed) and can later be replaced by a real malware scanner without changing APIs or schemas.
- Audit logs are created for every required action, including upload authorization, upload completion, file attachment, access granted, access denied, quarantine, scan status changes, delete, and restore (if implemented).
- Cleanup jobs are idempotent and correctly respect legal holds, retention policies, and active file references.
- All required events are emitted correctly for downstream modules.
- All required unit, integration, security, RBAC, tenant isolation, lifecycle, validation, audit logging, cleanup, and idempotency tests pass successfully.
- The implementation follows SOLID principles, Clean Architecture, existing NestJS coding conventions, and production-ready development practices.
- The module is secure, scalable, maintainable, extensible, and ready for future provider integrations without requiring architectural changes.
````
