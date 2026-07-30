# PHASE 12 — NOTIFICATION MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 17.
- Phase Name: Notification Management.
- Module: Notification Management.
- Scope: ERP user and customer communications.
- Status: Implementation prompt.

## Role, Purpose, and Boundaries

- Implement the Nexoraa CleanSoft Notification Management module using only this prompt.
- Deliver timely, reliable, configurable notifications to ERP users and customers.
- Centralize Email, SMS, WhatsApp, Push, and In-App communication.
- Convert business events into messages while respecting tenant isolation, branch awareness, recipient preferences, language, and quiet hours.
- Manage notification records, templates, preferences, delivery logs, status, scheduling, retries, history, and audit information.
- Receive events from ERP modules, select configured channels, and use external delivery providers.
- Preserve existing Authentication, Multi-Tenancy, Branch, User, Customer, Service, Order, and Payment functionality.
- Do not replace source business modules, Email Provider, SMS Gateway, WhatsApp Business API, or Push Notification Service.
- Do not implement unrelated modules or APIs.
- Stop after completing Notification Management.

## Notification Management Position

- Authentication identifies the acting user.
- Multi-Tenancy identifies the business that owns the communication.
- Branch Management supplies branch context for branch-specific events.
- User and Customer Management identify recipients and their preferences.
- Service, Order, and Payment Management publish business events.
- Notification Management converts those events into communications.
- Reports, Dashboard, and Search consume notification data.
- Audit Service records notification and delivery changes.

## Functional Areas

### 1. Notification Generation and Delivery

- Receive a business event.
- Evaluate notification rules.
- Select the notification type.
- Select a valid recipient.
- Select a configured channel using preferences.
- Select an active template when applicable.
- Validate all required variables.
- Render the subject and message content.
- Create the notification record.
- Queue immediate or scheduled delivery.
- Deliver through the selected provider.
- Track notification and delivery status.
- Prevent duplicate delivery.

### 2. Notification Template Management

- Store reusable tenant-scoped, channel-specific templates.
- Maintain template name and code.
- Maintain notification type and channel.
- Maintain subject and body templates.
- Maintain required variables and template status.
- Retrieve and update templates through the listed APIs.
- Secure and audit template changes.

### 3. Notification Channel Management

- Support Email delivery.
- Support SMS delivery.
- Support WhatsApp delivery.
- Support Push delivery.
- Support In-App delivery.
- Validate that the selected channel is supported and enabled.
- Select channels using recipient preferences.
- Track status and delivery attempts by channel.

### 4. Customer Notifications

- Validate the customer recipient.
- Validate customer tenant ownership.
- Send authorized customer notifications.
- Apply customer communication preferences.
- Support order-related and payment-related messages.
- Retain authorized customer notification history.

### 5. Employee Notifications

- Validate the employee recipient.
- Validate employee tenant ownership.
- Send authorized employee notifications.
- Apply user communication preferences.
- Support business-event messages.
- Retain authorized employee notification history.

### 6. Notification Preferences

- Store preferences for users and customers.
- Maintain Email Enabled.
- Maintain SMS Enabled.
- Maintain WhatsApp Enabled.
- Maintain Push Enabled.
- Maintain In-App Enabled.
- Maintain preferred language.
- Maintain quiet hours.
- Validate preferences.
- Apply preferences during channel selection.

### 7. Scheduled Notifications

- Store and validate scheduled delivery time.
- Queue scheduled notifications.
- Deliver notifications at the scheduled time.
- Track scheduled status and history.

### 8. History, Status, and Retry

- Store every notification and delivery attempt.
- Track queued notifications.
- Track sent notifications.
- Track delivered notifications.
- Track failed notifications.
- Track retried notifications.
- Store channel, provider error, retry count, sent time, and delivered time.
- Retry eligible failed deliveries and retain all attempts.
- Make history available only to authorized users.

## Business Workflow

1. Receive a published business event or an authorized API request.
2. Evaluate rules and select the recipient, template, and preferred supported channel.
3. Render validated content and create the notification.
4. Queue it for immediate or scheduled delivery.
5. Deliver through the configured provider.
6. Track provider status and retry eligible failures.
7. Store delivery history and audit evidence.

## Supported Channels

### Email

- Use Email Provider integration when Email is enabled.
- Store Email delivery status and logs.

### SMS

- Use SMS Gateway integration when SMS is enabled.
- Store SMS delivery status and logs.

### WhatsApp

- Use WhatsApp Business API integration when WhatsApp is enabled.
- Store WhatsApp delivery status and logs.

### Push

- Use Push Notification Service integration when Push is enabled.
- Store Push delivery status and logs.

### In-App

- Create In-App Notifications when In-App is enabled.
- Store In-App status and notification history.

## Database Collections

### `notifications`

#### Purpose

- Store the tenant-scoped master notification and its branch-aware delivery state.

#### Fields

- Tenant ID.
- Branch ID.
- Notification ID.
- Notification Type.
- Notification Channel.
- Recipient ID.
- Recipient Type.
- Subject.
- Message.
- Status.
- Priority.
- Scheduled Time.
- Sent Time.
- Delivery Status.
- CreatedBy.
- UpdatedBy.
- CreatedAt.
- UpdatedAt.

#### Requirements

- Require a valid recipient and recipient type.
- Require a valid notification type and supported channel.
- Validate branch ownership when Branch ID is present.
- Validate priority and scheduled time.
- Maintain notification status.
- Maintain delivery status.
- Maintain audit information.

### `notificationTemplates`

#### Purpose

- Store reusable tenant-scoped, channel-specific content templates.

#### Fields

- Tenant ID.
- Template Name.
- Template Code.
- Notification Type.
- Channel.
- Subject Template.
- Body Template.
- Variables.
- Status.

#### Requirements

- Validate template identity and status.
- Validate notification type and delivery channel.
- Validate subject and body templates.
- Validate every required variable.
- Protect template updates.

### `notificationPreferences`

#### Purpose

- Store user/customer channel, language, and quiet-hours preferences.

#### Fields

- Tenant ID.
- User ID or Customer ID.
- Email Enabled.
- SMS Enabled.
- WhatsApp Enabled.
- Push Enabled.
- In-App Enabled.
- Language.
- Quiet Hours.

#### Requirements

- Require exactly the applicable user or customer identity.
- Validate enabled channels.
- Validate language.
- Validate quiet hours.
- Apply preferences during notification generation and retain preference changes.

### `notificationLogs`

#### Purpose

- Store each delivery attempt, its outcome, timing, error, and retry data.

#### Fields

- Notification ID.
- Delivery Channel.
- Delivery Status.
- Error Message.
- Retry Count.
- Sent At.
- Delivered At.

#### Requirements

- Link each log to a valid notification.
- Record delivery channel and status.
- Record provider error when applicable.
- Record retry count.
- Record sent and delivered times.

## Collection Relationships

- Each notification belongs to one tenant, optional branch, recipient, and channel.
- A notification references its template when one is used.
- Every delivery log belongs to one notification.
- Preferences belong to one user or customer.
- Templates remain within tenant scope.

## REST APIs

### Create Notification

- Method: `POST`.
- Path: `/notifications`.
- Purpose: Create a notification request.
- Validate tenant, optional branch, recipient, type, channel, optional template/variables, priority, and schedule.

### Get Notification

- Method: `GET`.
- Path: `/notifications/:notificationId`.
- Purpose: Return an authorized notification with delivery status and history.
- Enforce notification identity, tenant, branch, and RBAC access.

### List Notifications

- Method: `GET`.
- Path: `/notifications`.
- Purpose: Return tenant/branch-authorized notification records.
- Support pagination, filtering, sorting, search, status filters, and channel filters.

### Send Notification

- Method: `POST`.
- Path: `/notifications/send`.
- Purpose: Queue or send a validated notification request.
- Validate recipient, tenant, template variables, and channel; apply preferences and duplicate prevention.

### Retry Notification

- Method: `POST`.
- Path: `/notifications/:notificationId/retry`.
- Purpose: Retry an authorized notification in failed delivery state.
- Increment the retry count and create delivery history.

### Get Templates

- Method: `GET`.
- Path: `/notifications/templates`.
- Purpose: Return authorized tenant templates by available notification type and channel.

### Update Template

- Method: `PUT`.
- Path: `/notifications/templates/:templateId`.
- Purpose: Update an authorized template.
- Validate type, channel, subject, body, and required variables; audit the change.

### Update Preferences

- Method: `PUT`.
- Path: `/notifications/preferences`.
- Purpose: Update authorized user or customer preferences.
- Validate recipient, channel flags, language, and quiet hours; retain the change.

## API Limit

- Implement only the eight listed Notification APIs.
- Do not add template creation/deletion, log, channel, or separate scheduling APIs.
- Keep unlisted work within the listed API scope.

## Validation Rules

- Require an existing recipient with a valid recipient type.
- Require the recipient to belong to the authenticated tenant.
- Require branch-specific notifications to use the correct tenant branch.
- Require an existing active template when a template is used.
- Require a supported delivery channel.
- Require every variable declared by the selected template.
- Require valid notification type, priority, and scheduled delivery time.
- Validate template status, channel, subject, body, and variables during template updates.
- Validate channel preferences, preferred language, and quiet hours.
- Apply recipient preferences before delivery.
- Reject duplicate notification delivery.

## Security Requirements

- Enforce tenant isolation for notifications, templates, preferences, lists, and search.
- Enforce branch ownership and branch-level access.
- Apply RBAC to create, view, send, retry, template, and preference operations.
- Prevent unauthorized sending and secure every template/preference update.
- Protect recipient identity, contact details, and message information.
- Audit notification, template, preference, send, retry, status, and delivery changes.

## Integration Requirements

- Authentication: supply authenticated user, tenant, and acting-user context.
- Multi-Tenancy: enforce ownership and isolation.
- Branch Management: validate branch ownership and awareness.
- User Management: validate employee recipients, preferences, and sending permissions.
- Customer Management: validate customer recipients and preferences.
- Service Management: publish listed service-related events.
- Order Management: publish order lifecycle events.
- Payment Management: publish payment-related events.
- Reports: consume notification data for listed reports.
- Dashboard: consume notification data for listed dashboards.
- Search: support notification search and listed synchronization.
- Audit Service: audit notification and delivery changes.
- Settings: provide channel and notification settings.
- Email Provider: deliver Email notifications.
- SMS Gateway: deliver SMS notifications.
- WhatsApp Business API: deliver WhatsApp notifications.
- Push Notification Service: deliver Push Notifications.

## Background Jobs

- Queue processing: process queued notifications.
- Scheduled delivery: send notifications at valid scheduled times.
- Failed retry: retry eligible failures and record every attempt.
- Notification cleanup: clean notification data through the listed process.
- Delivery synchronization: synchronize provider delivery status.
- Template synchronization: synchronize notification templates.
- Daily summary: prepare daily notification information.
- Audit processing: record notification changes and delivery history.

## Testing Requirements

### Unit Tests

- Test notification creation.
- Test recipient validation.
- Test template rendering.
- Test required template variables.
- Test supported-channel selection.
- Test preference validation.
- Test retry logic.
- Test duplicate prevention.
- Test scheduling validation.
- Test priority validation.

### Integration Tests

- Test Order Management integration.
- Test Payment Management integration.
- Test Customer Management integration.
- Test User Management integration.
- Test Email Provider integration.
- Test SMS Gateway integration.
- Test WhatsApp Business API integration.
- Test Push Notification Service integration.
- Test Audit Service integration.

### Security Tests

- Test tenant isolation.
- Test branch isolation.
- Test unauthorized notification access.
- Test unauthorized message sending.
- Test template permission validation.
- Test unauthorized preference updates.
- Test duplicate notification prevention.
- Test RBAC validation.
- Test recipient-information protection.

### Performance Tests

- Test notification queue processing.
- Test bulk notification delivery.
- Test template retrieval.
- Test notification search.
- Test high-volume concurrent processing.
- Test delivery tracking performance.
- Verify pagination performance.
- Verify retry processing performance.

## Implementation Sequence

1. Confirm Phase 17 Notification Management scope.
2. Review the listed module purpose.
3. Review the listed responsibilities.
4. Review the listed functional areas.
5. Review the business workflow.
6. Implement `notifications`.
7. Implement `notificationTemplates`.
8. Implement `notificationPreferences`.
9. Implement `notificationLogs`.
10. Implement Notification Generation.
11. Implement Template Management.
12. Implement Channel Management.
13. Implement Customer Notifications.
14. Implement Employee Notifications.
15. Implement Notification Preferences.
16. Implement Scheduled Notifications.
17. Implement Notification History.
18. Implement Status Management.
19. Implement the eight listed APIs.
20. Implement the listed validation rules.
21. Implement the listed security controls.
22. Implement the listed background jobs.
23. Implement the listed integrations.
24. Implement the listed tests.
25. Verify the acceptance criteria.
26. Update Notification Management documentation.
27. Record completion evidence.
28. Stop without starting another phase.

## Deliverables

- Notification generation, delivery, templates, channels, preferences, customer/employee communication, scheduling, history, retry, status, and audit functionality.
- Email, SMS, WhatsApp, Push, and In-App delivery support.
- `notifications`, `notificationTemplates`, `notificationPreferences`, and `notificationLogs`.
- The eight listed REST APIs only.
- Notification unit, integration, security, and performance tests.
- Module, collection, API, validation, security, integration, testing, and completion documentation.

## Acceptance Criteria

### Generation and Delivery

- [ ] Valid notifications are generated, rendered, queued, sent, and tracked.
- [ ] Recipient, type, required variables, priority, and scheduled time validation works.
- [ ] Email, SMS, WhatsApp, Push, and In-App channels work; unsupported channels are rejected.
- [ ] User/customer channel preferences, language, and quiet hours are respected.

### Templates, Scheduling, Retry, and History

- [ ] Tenant/channel templates render correctly and authorized updates validate type, channel, content, and variables.
- [ ] Scheduled notifications are delivered at the valid scheduled time.
- [ ] Failed notifications are retried with accurate retry counts and complete attempt history.
- [ ] Duplicate delivery is prevented.
- [ ] Notification/delivery status, errors, sent time, delivered time, and authorized history are accurate.

### Security

- [ ] Tenant and branch isolation, RBAC, authorized sending, and secured template/preference management work.
- [ ] Recipient information is protected and all required changes are audited.

### Integrations

- [ ] Authentication, Multi-Tenancy, Branch, User, Customer, Service, Order, and Payment integrations work.
- [ ] Reports, Dashboard, Search, Audit Service, and Settings integrations work.
- [ ] Email Provider, SMS Gateway, WhatsApp Business API, and Push Notification Service integrations work.

### Testing

- [ ] Unit, integration, security, performance, validation, template, channel, and retry tests pass.
- [ ] Queue, bulk delivery, search, delivery tracking, pagination, concurrency, and retry performance meet project requirements.

## Completion Instructions

1. Run the listed tests and record outcomes, changed files, known limitations, and completion evidence.
2. Confirm all acceptance criteria pass and update the corresponding Notification Management completion report.
3. Confirm exactly four collections and eight APIs, with no unrelated module or additional endpoint implemented.
4. Stop execution.

Do not start another phase.
