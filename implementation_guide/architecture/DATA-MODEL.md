# Data Model

## Status and scope

This is the logical MongoDB model migrated from Phase 2 and detailed module prompts. Collection names and fields from those prompts are preserved. Missing physical details are explicit blockers, not silent defaults. Loyalty structures found in the customer prompt are preserved as deferred source material because loyalty is future scope.

## Global conventions

- `_id`: MongoDB object identifier or approved opaque identifier.
- `tenantId`: required and immutable on tenant-owned records.
- `branchId`: required and immutable on branch-owned records.
- `createdAt`, `updatedAt`: UTC timestamps; `createdBy`, `updatedBy` where business changes require actor evidence.
- `version`: optimistic concurrency integer on editable aggregates.
- Lifecycle records use `status`; referenced business history is deactivated/archived, not destructively deleted.
- Money uses `{ amountMinor: integer, currency: string }`.
- Every common tenant query has a compound index beginning with `tenantId`; branch queries continue with `branchId`.
- Sensitive token/OTP values are stored only as cryptographic hashes.
- Cross-owner identifiers are references, not permission or referential-integrity proof.

## Authentication owner

### `refreshTokens`

- **Fields:** `_id`, `tenantId`, `branchId?`, `userId`, `tokenHash`, `sessionFamilyId`, `deviceId`, `deviceName`, `ipAddress`, `userAgent`, `expiresAt`, `revoked`, `revokedAt?`, `revokedBy?`, `replacedBy?`, `createdAt`, `updatedAt`.
- **Indexes:** unique `tokenHash`; `{ userId, revoked, expiresAt }`; `{ sessionFamilyId, revoked }`; TTL on `expiresAt`.
- **Consistency:** Rotation atomically revokes old and creates replacement; reuse revokes family.
- **Deletion:** Expired/revoked tokens may expire by retention policy; security audit evidence remains separate.

### `passwordResetTokens`

- **Fields:** `_id`, `tenantId`, `userId`, `otpHash`, `expiresAt`, `attempts`, `verified`, `consumed`, `createdAt`.
- **Indexes:** `{ tenantId, userId, consumed, expiresAt }`; TTL on `expiresAt`.
- **Consistency:** Verify/consume is atomic and single-use.

## Tenant owner

### `tenants`

- **Fields preserved from source:** `_id`, `businessName`, `businessType`, `ownerName`, `ownerEmail`, `ownerPhone`, `currency`, `timezone`, `locale`, `branding`, `billingContact`, `subscriptionPlanId`, `subscriptionStatus`, `entitlements`, `policies`, `status`, `createdBy`, `updatedBy`, `deletedBy?`, `createdAt`, `updatedAt`, `deletedAt?`, `isDeleted`, `version`.
- **Indexes:** normalized business lookup as approved; `{ status, subscriptionStatus }`; owner contact indexes must not imply global uniqueness without `OQ-2`.
- **Consistency:** Coordinated onboarding spans tenant, first branch, Owner membership, defaults, counter/outbox. Active status is last.
- **Deletion:** Suspend/deactivate/archive; physical deletion and retention blocked by `OQ-12`.

### `tenantSettings`

- **Fields:** `_id`, `tenantId`, `schemaVersion`, `locale`, `timezone`, `currency`, `taxPolicy`, `paymentMethods`, `numbering`, `receiptPolicy`, `deliveryPolicy`, `overpaymentPolicy`, `terminology`, `notificationPolicy`, `updatedBy`, `updatedAt`, `version`.
- **Indexes:** unique `{ tenantId }`.
- **Consistency:** Allowlisted/versioned changes emit `EVT-SETTINGS-CHANGED-001`; financial policy fields are blocked by `OQ-4`–`OQ-10`.

## Branch owner

### `branches`

- **Fields:** `_id`, `tenantId`, `code`, `name`, `status`, `isDefault`, `address`, `contact`, `workingHours`, `timezone`, `managerUserId?`, `createdBy`, `updatedBy`, `createdAt`, `updatedAt`, `version`.
- **Indexes:** unique `{ tenantId, code }`; `{ tenantId, status, name }`; at most one default active branch per tenant enforced transactionally/partial unique strategy.
- **Consistency:** Default switch and lifecycle transition are atomic with outbox.
- **Deletion:** No physical deletion when referenced; inactive history remains queryable.

### `branchConfigurations`

- **Fields:** `_id`, `tenantId`, `branchId`, `overrides`, `schemaVersion`, `createdAt`, `updatedAt`, `updatedBy`, `version`.
- **Indexes:** unique `{ tenantId, branchId }`.
- **Rule:** Keys are allowlisted; effective values inherit tenant settings.

## User owner

### `users`

- **Fields:** `_id`, `tenantId`, `email`, `mobile`, `normalizedEmail`, `normalizedMobile`, `displayName`, `employeeCode`, `status`, `roleId`, `branchIds`, `primaryBranchId?`, `department?`, `designation?`, `profile`, `accessVersion`, `createdBy`, `updatedBy`, `createdAt`, `updatedAt`, `version`.
- **Indexes:** tenant-scoped unique normalized identity/employee constraints; `{ tenantId, branchIds, status }`; tenant-scoped search fields.
- **Rules:** Final active Owner invariant; tenant identity immutable; no credential hash is exposed through user contracts.

### `userPermissions`

- **Fields:** `_id`, `tenantId`, `userId`, `rolePermissions`, `allowOverrides`, `denyOverrides`, `effectiveVersion`, `updatedBy`, `updatedAt`, `version`.
- **Indexes:** unique `{ tenantId, userId }`.
- **Rules:** Deny default; grant ceiling enforced; changes increment access version and invalidate sessions/caches.

### `userInvitations`

- **Fields:** `_id`, `tenantId`, `userId`, `branchIds`, `roleId`, `recipient`, `tokenHash`, `status`, `expiresAt`, `attempts`, `createdBy`, `createdAt`, `acceptedAt?`, `cancelledAt?`, `version`.
- **Indexes:** unique active invitation as approved per recipient/user; TTL/cleanup index on `expiresAt`; `{ tenantId, userId, status }`.
- **Rules:** Seven-day expiry is provisional under `OQ-17`; token single-use; resend rotates token.

## Customer owner

### `customers`

- **Fields preserved:** `_id`, `tenantId`, `customerCode`, `name`, `mobile`, `email?`, `classification?`, `status`, `communicationPreferences`, `defaultAddressId?`, `outstandingBalanceProjection`, `createdBranchId`, `createdBy`, `updatedBy`, `createdAt`, `updatedAt`, `archivedAt?`, `version`.
- **Indexes:** unique `{ tenantId, customerCode }`; tenant-scoped normalized mobile/email; `{ tenantId, status, name }`; search indexes remain tenant-scoped.
- **Rules:** Shared family numbers are allowed by existing audit guidance; contact identifiers therefore cannot be blindly unique.

### `customerAddresses`

- **Fields:** `_id`, `tenantId`, `customerId`, `label`, address lines, locality/city/state/postal/country, geo?`, `isDefault`, audit timestamps/version.
- **Indexes:** `{ tenantId, customerId, isDefault }`.

### `customerNotes`

- **Fields:** `_id`, `tenantId`, `customerId`, `branchId?`, `note`, `visibility`, `attachmentIds`, `createdBy`, `createdAt`, `updatedAt?`, `version`.
- **Indexes:** `{ tenantId, customerId, createdAt }`.
- **Privacy:** Notes/files require purpose, authorization, minimization, retention (`OQ-11`, `OQ-12`).

### `customerLoyalty` — deferred

- Preserved from the legacy customer prompt but not an MVP collection because loyalty/promotions are future scope.
- No implementation phase or stable contract may consume it unless a new product decision moves it into scope.

## Catalog owner

### `serviceCategories`

- **Fields:** `_id`, `tenantId`, `code`, `name`, `description?`, `status`, `sortOrder`, `createdBy`, `updatedBy`, timestamps/version.
- **Indexes:** unique `{ tenantId, code }`; `{ tenantId, status, sortOrder }`.

### `services`

- **Fields:** `_id`, `tenantId`, `categoryId`, `code`, `name`, `description?`, `processingDuration`, `status`, `branchIds/allBranches`, `taxClass?`, `createdBy`, `updatedBy`, timestamps/version.
- **Indexes:** unique `{ tenantId, code }`; `{ tenantId, status, categoryId }`; `{ tenantId, branchIds, status }`.

### `servicePricing`

- **Fields:** `_id`, `tenantId`, `serviceId`, `branchId?`, `pricingType`, `unit`, `amountMinor`, `currency`, `taxRate?`, `discountPolicy?`, `effectiveFrom`, `effectiveTo?`, `status`, audit timestamps/version.
- **Indexes:** `{ tenantId, serviceId, branchId, status, effectiveFrom }`; overlap prevention is a domain invariant.
- **Rules:** `OQ-4` and `OQ-5` block final tax/discount calculation rules.

### `itemCategories`

- **Fields:** `_id`, `tenantId`, `code`, `name`, `status`, `attributes?`, audit timestamps/version.
- **Indexes:** unique `{ tenantId, code }`; `{ tenantId, status, name }`.
- **Source note:** Required by MVP/System Plan although omitted from the legacy service prompt's explicit collection list.

## Order owner

### `orders`

- **Fields preserved:** `_id`, `tenantId`, `branchId`, `orderNumber`, `customerId?`, `customerSnapshot`, `status`, `currency`, `subtotalMinor`, `discountMinor`, `taxMinor`, `totalMinor`, `paidMinorProjection`, `outstandingMinorProjection`, `expectedCompletionAt?`, `assignedUserIds`, `specialInstructions?`, `delivery`, `cancellation?`, `createdBy`, `updatedBy`, timestamps/version.
- **Indexes:** unique `{ tenantId, branchId, orderNumber }`; `{ tenantId, branchId, status, createdAt }`; `{ tenantId, customerId, createdAt }`; assignment/expected-completion indexes.
- **Consistency:** Order, items, initial history, counter, and outbox commit together.
- **Immutability:** Financial/customer/catalog snapshots cannot be silently rewritten after creation/finalization.

### `orderItems`

- **Fields:** `_id`, `tenantId`, `branchId`, `orderId`, `itemCategorySnapshot`, `serviceSnapshot`, `quantityFixed`, `unitPriceMinor`, `discountMinor`, `taxMinor`, `lineTotalMinor`, `notes?`, `status?`, timestamps/version.
- **Indexes:** `{ tenantId, orderId }`; `{ tenantId, branchId, serviceSnapshot.serviceId, createdAt }`.

### `orderStatusHistory`

- **Fields:** `_id`, `tenantId`, `branchId`, `orderId`, `fromStatus`, `toStatus`, `actorId`, `notes?`, `reason?`, `occurredAt`, `orderVersion`.
- **Indexes:** `{ tenantId, orderId, occurredAt }`.
- **Deletion:** Append-only.

### `orderAttachments`

- **Fields:** `_id`, `tenantId`, `branchId`, `orderId`, `fileId`, `purpose`, `status`, `createdBy`, `createdAt`.
- **Indexes:** `{ tenantId, orderId, purpose }`.
- **Rule:** Binary content is File-owned private object storage; this is a domain reference only.

### `counters`

- **Fields:** `_id`, `tenantId`, `branchId?`, `counterType`, `businessPeriod?`, `nextValue`, `version`.
- **Indexes:** unique `{ tenantId, branchId, counterType, businessPeriod }`.
- **Consistency:** Atomic increment; scope/format policy finalized with settings.

## Payment owner

### `payments`

- **Fields:** `_id`, `tenantId`, `branchId`, `orderId`, `customerId?`, `paymentNumber`, `method`, `amountMinor`, `currency`, `status`, `providerReference?`, `idempotencyKey`, `recordedBy`, `recordedAt`, `verifiedAt?`, timestamps/version.
- **Indexes:** unique scoped payment number; unique provider reference when present; unique `{ tenantId, idempotencyKey, operation }`; `{ tenantId, branchId, orderId, status }`.
- **Deletion:** Successful/finalized payment immutable.

### `paymentTransactions`

- **Fields:** `_id`, `tenantId`, `branchId`, `paymentId`, `type`, `amountMinor`, `currency`, `providerReference?`, `status`, `requestSafeSummary`, `responseSafeSummary`, `occurredAt`.
- **Indexes:** `{ tenantId, paymentId, occurredAt }`; provider reference uniqueness as applicable.

### `paymentReceipts`

- **Fields:** `_id`, `tenantId`, `branchId`, `paymentId`, `orderId`, `receiptNumber`, `snapshot`, `issuedAt`, `issuedBy`, `fileId?`, `version`.
- **Indexes:** unique `{ tenantId, branchId, receiptNumber }`; `{ tenantId, paymentId }`.
- **Deletion:** Immutable; corrected/reissued evidence links rather than overwrites.

### `refunds`

- **Fields:** `_id`, `tenantId`, `branchId`, `paymentId`, `orderId`, `refundNumber`, `amountMinor`, `currency`, `reason`, `approval`, `status`, `idempotencyKey`, `createdBy`, timestamps/version.
- **Indexes:** unique scoped refund number; unique idempotency operation; `{ tenantId, paymentId, status }`.
- **Blockers:** eligibility, threshold, tax, overpayment behavior `OQ-6`–`OQ-8`.

## Expense owner

### `expenseCategories`

- **Fields:** `_id`, `tenantId`, `code`, `name`, `status`, `requiresEvidence`, audit timestamps/version.
- **Indexes:** unique `{ tenantId, code }`; `{ tenantId, status }`.

### `expenses`

- **Fields:** `_id`, `tenantId`, `branchId`, `expenseNumber`, `categoryId`, `businessDate`, `amountMinor`, `currency`, `paymentSource`, `description`, `evidenceFileIds`, `status`, `correctionOf?`, `createdBy`, timestamps/version.
- **Indexes:** unique scoped number; `{ tenantId, branchId, businessDate, status }`; `{ tenantId, categoryId, businessDate }`.
- **Deletion:** Finalized expense corrected additively; policy tied to `OQ-9`, `OQ-10`.

### `cashRegisters`

- **Fields:** `_id`, `tenantId`, `branchId`, `businessDate`, `status`, `openedBy`, `openedAt`, `openingCashMinor`, `expectedCashMinor`, `actualCashMinor?`, `varianceMinor?`, `varianceReason?`, `closedBy?`, `closedAt?`, `reopenHistory`, timestamps/version.
- **Indexes:** unique `{ tenantId, branchId, businessDate }`; `{ tenantId, branchId, status }`.
- **Consistency:** Close reads authoritative scoped movements and commits immutable close snapshot/outbox; non-zero variance requires reason.

### `cashMovements`

- **Fields:** `_id`, `tenantId`, `branchId`, `registerId`, `businessDate`, `type`, `sourceType`, `sourceId`, `amountMinor`, `currency`, `reason?`, `createdBy`, `createdAt`.
- **Indexes:** unique source effect where applicable; `{ tenantId, registerId, createdAt }`.
- **Deletion:** Append-only or additive reversal.

## Notification owner

### `notifications`

- **Fields:** `_id`, `tenantId`, `branchId?`, `recipientType`, `recipientId`, `type`, `templateId?`, `channel`, `locale`, `payloadSafe`, `status`, `scheduledAt?`, `sentAt?`, `readAt?`, `sourceEventId`, timestamps/version.
- **Indexes:** unique consumer/source/channel identity; `{ tenantId, recipientId, status, createdAt }`; scheduled status index.

### `notificationTemplates`

- **Fields:** `_id`, `tenantId?`, `key`, `channel`, `locale`, `providerTemplateRef?`, `subject?`, `body`, `variables`, `status`, `protected`, audit timestamps/version.
- **Indexes:** unique `{ tenantId, key, channel, locale }`.

### `notificationPreferences`

- **Fields:** `_id`, `tenantId`, `recipientType`, `recipientId`, `eventPreferences`, `channelPreferences`, `consentVersion?`, timestamps/version.
- **Indexes:** unique recipient scope.
- **Blocker:** `OQ-11`, `OQ-19`.

### `notificationLogs`

- **Fields:** `_id`, `tenantId`, `notificationId`, `channel`, `providerSafeReference`, `attempt`, `status`, `errorCategory?`, `occurredAt`.
- **Indexes:** `{ tenantId, notificationId, attempt }`; provider-safe reference where required.
- **Deletion:** Retention pending `OQ-12`; secrets/provider credentials never stored.

## Cross-cutting owners

### `outboxEvents`

- **Fields:** event envelope plus payload, aggregate ID/version, publish status, attempts, nextAttemptAt, publishedAt?, createdAt.
- **Indexes:** unique `eventId`; `{ publishStatus, nextAttemptAt }`; `{ tenantId, aggregateId, aggregateVersion }`.
- **Consistency:** Written with owner transaction; never used as business truth.

### `consumerReceipts`

- **Fields:** consumer, eventId, processedAt, result/checkpoint.
- **Indexes:** unique `{ consumer, eventId }`.
- **Purpose:** Idempotent at-least-once consumption.

### `auditRecords`

- **Fields:** `_id`, tenant/platform scope, `branchId?`, `actor`, `module`, `action`, `target`, `occurredAt`, `correlationId`, `result`, `oldSummary?`, `newSummary?`, classification/retention tags, source event/operation ID.
- **Indexes:** scope + time; target + time; actor + time; action/category + time; unique source obligation.
- **Deletion:** Append-only; retention/legal hold blocked by `OQ-12`; tenant/platform authorization separate.

### `searchDocuments`

- **Fields:** tenant/branch scope, domain/type, source ID/version, approved searchable fields/tokens, authorization facets, updatedAt, checkpoint.
- **Indexes:** tenant-first search index and source uniqueness.
- **Deletion:** Derived/rebuildable; remove when source event/lifecycle requires.

### `reportFacts` / `reportRollups`

- **Fields:** source event/record identity/version, tenant/branch, business date/timezone, immutable financial snapshot fields, dimensions, metrics, projection checkpoint.
- **Indexes:** tenant/branch/date/report dimensions; source uniqueness.
- **Deletion:** Derived/rebuildable but retention must remain compatible with source and `OQ-12`.

### `jobs`

- **Fields:** typed job ID/version, owner, tenant/branch scope, payload reference/minimal safe payload, idempotency identity, status, attempts, schedule/retry/dead-letter metadata, correlation/causation, timestamps.
- **Indexes:** queue/status/schedule; owner/idempotency; tenant status where operationally queried.
- **Rule:** BullMQ is execution state; authoritative business state remains domain-owned.

## Transaction boundaries

| Operation | Required local atomic boundary |
|---|---|
| Tenant onboarding | tenant + first branch + Owner membership + defaults + outbox |
| Branch default change | previous/new default + outbox |
| Invitation acceptance | invitation consumed + user/membership activation + outbox; credential contract coordinated safely |
| Order creation | order + items + initial history + counter + outbox |
| Order transition | order version + history + outbox |
| Payment record/refund | financial record(s) + idempotency receipt + outbox |
| Register close | register close snapshot + required movements/correction links + outbox |
| Settings change | versioned settings + outbox |

Cross-owner updates are never one database transaction; they use `ADR-006`.

## Unresolved physical-model blockers

- Financial calculation fields/policies: `OQ-4`–`OQ-10`.
- Consent, retention, deletion, residency: `OQ-11`, `OQ-12`.
- API/event idempotency/retention: `OQ-22`, `OQ-25`.
- Audit critical consistency: `OQ-26`.
- Capacity/index validation: `OQ-28`.
- Production provider/topology: `OQ-31`.

