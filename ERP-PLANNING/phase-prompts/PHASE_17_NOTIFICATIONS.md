# PHASE 17 — NOTIFICATION MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 17.
- Phase Name: Notification Management.
- Module: Notification Management.
- Scope: ERP user and customer communications.
- Status: Implementation prompt.

## Role

- Implement the Nexoraa CleanSoft Notification Management module.
- Use only the requirements defined in this prompt.
- Preserve existing Authentication functionality.
- Preserve existing Multi-Tenancy functionality.
- Preserve existing Branch Management functionality.
- Preserve existing User Management functionality.
- Preserve existing Customer Management functionality.
- Preserve existing Service Management functionality.
- Preserve existing Order Management functionality.
- Preserve existing Payment Management functionality.
- Do not implement unrelated modules.
- Stop after completing Notification Management.

## Overall Purpose

- Deliver timely notifications.
- Deliver reliable notifications.
- Deliver configurable notifications.
- Deliver notifications to users.
- Deliver notifications to customers.
- Centralize all communication channels.
- Convert business events into notifications.
- Maintain tenant isolation.
- Maintain branch awareness.
- Respect user notification preferences.
- Respect customer notification preferences.
- Support Email.
- Support SMS.
- Support WhatsApp.
- Support Push Notifications.
- Support In-App Notifications.
- Act as the ERP communication hub.

## Notification Management Position

- Authentication identifies who initiated the action.
- Multi-Tenancy identifies which business owns the communication.
- Branch Management identifies which location generated the event.
- User Management controls who can send or receive notifications.
- Customer Management identifies customer recipients.
- Order Management provides order lifecycle events.
- Payment Management provides payment events.
- Notification Management converts events into communications.
- Reports consume notification data.
- Dashboards consume notification data.
- Search uses notification records.
- Audit Service records notification changes.

## Core Responsibilities

- Notification Generation.
- Notification Delivery.
- Notification Template Management.
- Notification Channel Management.
- Notification Preferences.
- Customer Notifications.
- Employee Notifications.
- In-App Notifications.
- Email Notifications.
- SMS Notifications.
- WhatsApp Notifications.
- Push Notifications.
- Scheduled Notifications.
- Notification History.
- Notification Retry Management.
- Notification Audit Management.

## Responsibility Boundaries

- Manage notification records only.
- Manage notification templates only.
- Manage notification preferences only.
- Manage notification delivery logs only.
- Receive events from ERP modules.
- Select configured delivery channels.
- Use external delivery providers.
- Preserve notification history.
- Preserve delivery status.
- Preserve retry information.
- Do not replace source business modules.
- Do not replace Email Provider.
- Do not replace SMS Gateway.
- Do not replace WhatsApp Business API.
- Do not replace Push Notification Service.

## Functional Areas

### 1. Notification Generation

- Receive a business event.
- Evaluate notification rules.
- Select a notification type.
- Select an appropriate template.
- Select a recipient.
- Select a delivery channel.
- Generate message content.
- Validate required variables.
- Create a notification record.
- Queue the notification.

### 2. Notification Template Management

- Store reusable templates.
- Maintain template name.
- Maintain template code.
- Maintain notification type.
- Maintain channel.
- Maintain subject template.
- Maintain body template.
- Maintain required variables.
- Maintain template status.
- Update templates through the listed API.
- Secure template management.

### 3. Notification Channel Management

- Support Email delivery.
- Support SMS delivery.
- Support WhatsApp delivery.
- Support Push Notification delivery.
- Support In-App Notification delivery.
- Validate the selected channel.
- Select a channel using preferences.
- Track delivery by channel.
- Store channel in notification history.

### 4. Customer Notifications

- Send notifications to customers.
- Validate customer recipient.
- Validate customer tenant ownership.
- Apply customer communication preferences.
- Support order-related notifications.
- Support payment-related notifications.
- Preserve customer notification history.

### 5. Employee Notifications

- Send notifications to employees.
- Validate user recipient.
- Validate user tenant ownership.
- Apply user notification preferences.
- Support business-event notifications.
- Preserve employee notification history.

### 6. Notification Preferences

- Store preferences for users.
- Store preferences for customers.
- Store Email Enabled.
- Store SMS Enabled.
- Store WhatsApp Enabled.
- Store Push Enabled.
- Store In-App Enabled.
- Store preferred language.
- Store quiet hours.
- Validate preferences.
- Respect preferences during channel selection.

### 7. Scheduled Notifications

- Store scheduled delivery time.
- Validate scheduled time.
- Queue scheduled notifications.
- Deliver notifications at scheduled time.
- Track scheduled notification status.
- Preserve scheduled notification history.

### 8. Notification History

- Store every notification.
- Store every delivery attempt.
- Store delivery channel.
- Store delivery status.
- Store error message.
- Store retry count.
- Store sent time.
- Store delivered time.
- Preserve notification history.
- Make history available to authorized users.

### 9. Notification Status Management

- Maintain notification status.
- Maintain delivery status.
- Validate status values.
- Track queued notifications.
- Track sent notifications.
- Track delivered notifications.
- Track failed notifications.
- Track retried notifications.
- Preserve status changes.

### 10. MongoDB Collections

- Implement the `notifications` collection.
- Implement the `notificationTemplates` collection.
- Implement the `notificationPreferences` collection.
- Implement the `notificationLogs` collection.
- Link every log to the correct notification.
- Keep records isolated by tenant.
- Keep branch-specific records branch-aware.
- Preserve notification history.

### 11. REST APIs

- Implement notification creation.
- Implement notification retrieval.
- Implement notification listing.
- Implement notification sending.
- Implement notification retry.
- Implement template retrieval.
- Implement template updates.
- Implement preference updates.
- Do not add APIs outside the listed scope.

### 12. Validation Rules

- Validate recipient existence.
- Validate template existence.
- Validate delivery channel support.
- Validate required template variables.
- Validate notification type.
- Validate scheduled delivery time.
- Validate priority.
- Validate recipient tenant ownership.
- Validate branch-specific ownership.

### 13. Security

- Enforce tenant-level isolation.
- Enforce branch-level notification access.
- Apply RBAC.
- Secure template management.
- Audit notification changes.
- Prevent unauthorized message sending.
- Protect recipient information.
- Prevent duplicate delivery.

### 14. Background Jobs

- Process notification queue.
- Deliver scheduled notifications.
- Retry failed notifications.
- Clean up notifications.
- Synchronize delivery status.
- Synchronize templates.
- Generate daily notification summary.
- Process audit logs.

### 15. Integrations

- Integrate with Authentication.
- Integrate with Multi-Tenancy.
- Integrate with Branch Management.
- Integrate with User Management.
- Integrate with Customer Management.
- Integrate with Service Management.
- Integrate with Order Management.
- Integrate with Payment Management.
- Integrate with Reports.
- Integrate with Dashboard.
- Integrate with Search.
- Integrate with Audit Service.
- Integrate with Settings.
- Integrate with Email Provider.
- Integrate with SMS Gateway.
- Integrate with WhatsApp Business API.
- Integrate with Push Notification Service.

### 16. Testing

- Implement notification unit tests.
- Implement notification integration tests.
- Implement notification security tests.
- Implement notification performance tests.
- Test notification creation.
- Test template rendering.
- Test channel selection.
- Test preference validation.
- Test retry logic.
- Test scheduling.

### 17. Acceptance Criteria

- Verify notification generation.
- Verify multiple delivery channels.
- Verify templates.
- Verify user preferences.
- Verify customer preferences.
- Verify scheduled delivery.
- Verify automatic retry.
- Verify notification history.
- Verify delivery tracking.
- Verify tenant isolation.
- Verify branch isolation.
- Verify listed integrations.
- Verify all required tests.

## Business Workflow

1. Receive a business event.
2. Receive the published event.
3. Process the event in Notification Management.
4. Evaluate notification rules.
5. Select the appropriate template.
6. Determine the delivery channel.
7. Generate the message content.
8. Queue the notification.
9. Deliver the notification.
10. Track delivery status.
11. Retry failed delivery.
12. Store notification history for auditing.

## Workflow Requirements

- Keep every notification linked to its tenant.
- Keep branch-specific notifications linked to the correct branch.
- Keep every notification linked to a recipient.
- Keep every notification linked to a template when used.
- Keep every delivery attempt linked to a notification.
- Apply notification preferences.
- Validate the delivery channel.
- Validate required template variables.
- Preserve all delivery attempts.
- Prevent duplicate delivery.

## Supported Channels

### Email

- Support Email notifications.
- Use Email Provider integration.
- Respect Email Enabled preference.
- Store Email delivery status.
- Store Email delivery logs.

### SMS

- Support SMS notifications.
- Use SMS Gateway integration.
- Respect SMS Enabled preference.
- Store SMS delivery status.
- Store SMS delivery logs.

### WhatsApp

- Support WhatsApp notifications.
- Use WhatsApp Business API integration.
- Respect WhatsApp Enabled preference.
- Store WhatsApp delivery status.
- Store WhatsApp delivery logs.

### Push

- Support Push Notifications.
- Use Push Notification Service integration.
- Respect Push Enabled preference.
- Store Push delivery status.
- Store Push delivery logs.

### In-App

- Support In-App Notifications.
- Respect In-App Enabled preference.
- Store In-App status.
- Store In-App notification history.

## Database Collections

### `notifications`

#### Purpose

- Store the master notification record.
- Keep notifications tenant-scoped.
- Keep branch-specific notifications branch-aware.
- Track notification and delivery status.

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

- Require tenant ownership.
- Validate branch ownership when provided.
- Require valid recipient.
- Require valid recipient type.
- Require valid notification type.
- Require supported channel.
- Validate priority.
- Validate scheduled time.
- Maintain status.
- Maintain delivery status.
- Preserve audit information.

### `notificationTemplates`

#### Purpose

- Store reusable notification templates.
- Support notification content generation.
- Support channel-specific templates.
- Keep templates tenant-scoped.

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

- Require tenant ownership.
- Maintain template name.
- Maintain template code.
- Validate notification type.
- Validate delivery channel.
- Maintain subject template.
- Maintain body template.
- Maintain required variables.
- Validate template status.
- Protect template updates.

### `notificationPreferences`

#### Purpose

- Store user preferences.
- Store customer preferences.
- Control channel selection.
- Control language and quiet hours.

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

- Require tenant ownership.
- Require user or customer identity.
- Validate enabled channels.
- Validate language.
- Validate quiet hours.
- Apply preferences during notification generation.
- Preserve preference updates.

### `notificationLogs`

#### Purpose

- Store delivery history.
- Store every delivery attempt.
- Track errors and retries.
- Track sent and delivered times.

#### Fields

- Notification ID.
- Delivery Channel.
- Delivery Status.
- Error Message.
- Retry Count.
- Sent At.
- Delivered At.

#### Requirements

- Require valid notification.
- Store delivery channel.
- Store delivery status.
- Store error message when applicable.
- Store retry count.
- Store sent time.
- Store delivered time.
- Preserve delivery history.

## Collection Relationships

- Link every notification to one tenant.
- Link branch-specific notifications to one branch.
- Link every notification to one recipient.
- Link every notification to its channel.
- Link every delivery log to one notification.
- Link preferences to one user or customer.
- Keep templates within tenant scope.
- Preserve notification and delivery history.

## REST APIs

### Create Notification

- Method: `POST`.
- Path: `/notifications`.
- Purpose: Create a notification request.
- Validate tenant.
- Validate branch when applicable.
- Validate recipient.
- Validate notification type.
- Validate channel.
- Validate template and variables when used.
- Validate priority and schedule.

### Get Notification

- Method: `GET`.
- Path: `/notifications/:notificationId`.
- Purpose: Return notification details.
- Validate notification identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Return delivery status.
- Return authorized delivery history.

### List Notifications

- Method: `GET`.
- Path: `/notifications`.
- Purpose: Return paginated notification records.
- Support pagination.
- Support filtering.
- Support sorting.
- Support searching.
- Support status filters.
- Support channel filters.
- Enforce tenant isolation.
- Enforce branch access.

### Send Notification

- Method: `POST`.
- Path: `/notifications/send`.
- Purpose: Queue or send a notification.
- Validate notification request.
- Validate recipient and tenant.
- Validate template and variables.
- Validate channel.
- Apply preferences.
- Prevent duplicate delivery.
- Queue the notification.

### Retry Notification

- Method: `POST`.
- Path: `/notifications/:notificationId/retry`.
- Purpose: Retry a failed notification.
- Validate notification identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Require failed delivery state.
- Increment retry count.
- Preserve retry history.

### Get Templates

- Method: `GET`.
- Path: `/notifications/templates`.
- Purpose: Return available templates.
- Validate tenant ownership.
- Apply RBAC.
- Support available notification types.
- Support available channels.

### Update Template

- Method: `PUT`.
- Path: `/notifications/templates/:templateId`.
- Purpose: Update a notification template.
- Validate template identity.
- Validate tenant ownership.
- Apply RBAC.
- Validate type and channel.
- Validate subject and body template.
- Validate required variables.
- Audit template changes.

### Update Preferences

- Method: `PUT`.
- Path: `/notifications/preferences`.
- Purpose: Update user or customer preferences.
- Validate tenant ownership.
- Validate user or customer.
- Validate channel preferences.
- Validate language.
- Validate quiet hours.
- Preserve preference changes.

## API Limit

- Implement only the eight listed Notification APIs.
- Do not add template creation APIs.
- Do not add template deletion APIs.
- Do not add log APIs.
- Do not add channel APIs.
- Do not add separate scheduling APIs.
- Keep unlisted work within the listed API scope.

## Validation Rules

- Require an existing recipient.
- Require an existing template when used.
- Require a supported delivery channel.
- Require all template variables.
- Require valid notification type.
- Require valid scheduled delivery time.
- Require valid priority.
- Require recipient to belong to authenticated tenant.
- Require branch-specific notifications to use the correct branch.

## Validation Checklist

- Validate tenant ownership.
- Validate branch ownership.
- Validate recipient identity.
- Validate recipient type.
- Validate template identity.
- Validate template status.
- Validate notification type.
- Validate delivery channel.
- Validate required variables.
- Validate scheduled time.
- Validate priority.
- Validate preferences.

## Security Requirements

- Enforce tenant isolation for notifications, templates, preferences, lists, and search.
- Enforce branch ownership and branch-level notification access.
- Apply RBAC to create, view, send, retry, template, and preference operations.
- Secure every template update.
- Audit notification, template, preference, send, and retry changes.
- Prevent unauthorized message sending.
- Protect recipient identity, contact details, and message information.
- Prevent duplicate notification delivery.

## Integration Requirements

- Authentication: use authenticated user, tenant, and acting-user context.
- Multi-Tenancy: validate tenant ownership and isolation.
- Branch Management: validate branch ownership and branch awareness.
- User Management: validate employee recipients and sending permissions.
- Customer Management: validate customer recipients and preferences.
- Service Management: receive listed service-related events.
- Order Management: receive order lifecycle events.
- Payment Management: receive payment-related events.
- Reports: provide notification data for listed reports.
- Dashboard: provide notification data for listed dashboards.
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
- Failed retry: retry failed notifications and preserve retry history.
- Notification cleanup: clean notification data through the listed process.
- Delivery synchronization: update delivery status from providers.
- Template synchronization: synchronize notification templates.
- Daily summary: prepare daily notification information.
- Audit processing: preserve notification changes and delivery history.

## Testing Requirements

### Unit Tests

- Test notification creation.
- Test recipient validation.
- Test template rendering.
- Test required variables.
- Test channel selection.
- Test preference validation.
- Test retry logic.
- Test scheduling validation.
- Test priority validation.
- Test duplicate prevention.

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
- Test recipient information protection.

### Performance Tests

- Test notification queue processing.
- Test bulk notification delivery.
- Test template retrieval.
- Test notification search.
- Test high-volume concurrent processing.
- Test delivery tracking performance.
- Verify pagination performance.
- Verify retry processing.

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

### Notification Features

- Notification Generation.
- Notification Delivery.
- Notification Template Management.
- Notification Channel Management.
- Notification Preferences.
- Customer Notifications.
- Employee Notifications.
- In-App Notifications.
- Email Notifications.
- SMS Notifications.
- WhatsApp Notifications.
- Push Notifications.
- Scheduled Notifications.
- Notification History.
- Notification Retry Management.
- Notification Audit Management.

### Collections

- `notifications`.
- `notificationTemplates`.
- `notificationPreferences`.
- `notificationLogs`.

### APIs

- `POST /notifications`.
- `GET /notifications/:notificationId`.
- `GET /notifications`.
- `POST /notifications/send`.
- `POST /notifications/:notificationId/retry`.
- `GET /notifications/templates`.
- `PUT /notifications/templates/:templateId`.
- `PUT /notifications/preferences`.

### Tests

- Notification unit tests.
- Notification integration tests.
- Notification security tests.
- Notification performance tests.

### Documentation

- Notification module documentation.
- Collection documentation.
- API documentation.
- Validation documentation.
- Security documentation.
- Integration documentation.
- Testing documentation.
- Completion evidence.

## Acceptance Criteria

### Notification Generation

- [ ] Notifications can be generated successfully.
- [ ] Recipients are validated.
- [ ] Notification types are valid.
- [ ] Required variables are provided.
- [ ] Priorities are valid.
- [ ] Scheduled times are valid.

### Delivery Channels

- [ ] Email is supported.
- [ ] SMS is supported.
- [ ] WhatsApp is supported.
- [ ] Push Notifications are supported.
- [ ] In-App Notifications are supported.
- [ ] Unsupported channels are rejected.

### Templates

- [ ] Templates function correctly.
- [ ] Template types are validated.
- [ ] Template channels are validated.
- [ ] Template variables are validated.
- [ ] Template updates are secured.

### Preferences

- [ ] User preferences are respected.
- [ ] Customer preferences are respected.
- [ ] Email preference is respected.
- [ ] SMS preference is respected.
- [ ] WhatsApp preference is respected.
- [ ] Push preference is respected.
- [ ] In-App preference is respected.
- [ ] Language is maintained.
- [ ] Quiet hours are maintained.

### Scheduling and Retry

- [ ] Scheduled notifications are delivered.
- [ ] Failed notifications are retried.
- [ ] Retry counts are maintained.
- [ ] Retry history is preserved.
- [ ] Duplicate delivery is prevented.

### History

- [ ] Notification history is preserved.
- [ ] Delivery history is preserved.
- [ ] Error information is preserved.
- [ ] Sent time is preserved.
- [ ] Delivered time is preserved.
- [ ] Delivery status is accurate.

### Security

- [ ] Tenant isolation is enforced.
- [ ] Branch access is enforced.
- [ ] RBAC is enforced.
- [ ] Unauthorized sending is prevented.
- [ ] Template management is secured.
- [ ] Recipient information is protected.
- [ ] Notification changes are audited.

### Integrations

- [ ] Authentication integration works.
- [ ] Multi-Tenancy integration works.
- [ ] Branch Management integration works.
- [ ] User Management integration works.
- [ ] Customer Management integration works.
- [ ] Service Management integration works.
- [ ] Order Management integration works.
- [ ] Payment Management integration works.
- [ ] Reports integration works.
- [ ] Dashboard integration works.
- [ ] Search integration works.
- [ ] Audit Service integration works.
- [ ] Settings integration works.
- [ ] Email Provider integration works.
- [ ] SMS Gateway integration works.
- [ ] WhatsApp Business API integration works.
- [ ] Push Notification Service integration works.

### Testing

- [ ] Unit tests pass.
- [ ] Integration tests pass.
- [ ] Security tests pass.
- [ ] Performance tests pass.
- [ ] Validation tests pass.
- [ ] Template tests pass.
- [ ] Channel tests pass.
- [ ] Retry tests pass.

## Completion Instructions

1. Verify every listed responsibility.
2. Verify every listed functional area.
3. Verify the complete business workflow.
4. Verify all four collections.
5. Verify all eight APIs.
6. Verify every validation rule.
7. Verify every security requirement.
8. Verify every background job.
9. Verify every listed integration.
10. Run every listed test category.
11. Record test outcomes.
12. Record created files.
13. Record modified files.
14. Record known limitations.
15. Record completion evidence.
16. Confirm that no extra API was added.
17. Confirm that no extra collection was added.
18. Confirm that no unrelated module was implemented.
19. Update the corresponding Notification Management completion report.
20. Stop execution.

Do not start another phase.
