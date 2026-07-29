# PHASE 10 – MULTI-TENANCY IMPLEMENTATION PROMPT

## Phase Number

04

## Phase Name

Multi-Tenancy (Tenant Management)

---

# Role

You are a Senior Enterprise Software Architect and Lead Full Stack Engineer responsible for implementing the Multi-Tenancy module of the Nexoraa CleanSoft ERP platform.

Your responsibility in this phase is to establish the complete Software-as-a-Service (SaaS) tenant architecture that enables multiple independent businesses to operate securely on a shared application infrastructure.

Implement only the Multi-Tenancy module. Do not implement Branch Management, User Management, Customer Management, Order Management, Payment Management, Reports, Notifications, or other business modules except where minimal integration is required.

---

# Phase Dependencies

Before starting implementation, complete the following verification steps:

1. Read the previous phase completion report.
2. Verify that the Authentication module has been completed successfully.
3. Review the repository architecture and shared packages.
4. Understand the existing authentication and security flow.
5. Verify coding standards and naming conventions.
6. Maintain backward compatibility.
7. Do not overwrite completed implementations.
8. Continue only after successful verification.

---

# Objective

Implement a production-ready Multi-Tenant architecture that allows multiple businesses to securely share the same ERP platform while maintaining complete logical isolation of their data, configurations, branding, subscriptions, and business operations.

The module should establish every tenant as an independent organization with its own workspace, users, branches, customers, services, orders, reports, and settings.

---

# Business Objectives

The Multi-Tenancy module should allow new businesses to register and immediately receive an isolated ERP workspace without affecting existing tenants.

Every tenant should operate independently with its own business identity, branding, subscription plan, configuration, and feature access while sharing the common platform infrastructure.

The module must provide a scalable SaaS architecture capable of supporting thousands of independent organizations.

---

# Scope

This phase includes:

- Tenant Registration
- Tenant Creation
- Company Profile Management
- Tenant Configuration
- Business Information Management
- Subscription Initialization
- Feature Configuration
- Branding Configuration
- Tenant Status Management
- Trial Management
- Subscription Validation
- Tenant Isolation
- Default Configuration Creation
- Default Workspace Initialization
- Tenant APIs
- Tenant Documentation
- Tenant Testing

---

# Out of Scope

Do not implement:

- Branch Management
- User Management
- Customer Management
- Order Management
- Inventory
- Payment Processing
- Notification Delivery
- Reports
- Dashboard
- Expense Management
- Search

These modules belong to later implementation phases.

---

# Functional Requirements

The Multi-Tenancy module shall provide:

## Tenant Registration

The system shall support:

- Business registration.
- Company information collection.
- Business contact information.
- Business owner details.
- Tenant code generation.
- Initial subscription assignment.
- Default workspace creation.

---

## Tenant Management

The system shall allow:

- Create tenant.
- View tenant information.
- Update tenant profile.
- Activate tenant.
- Suspend tenant.
- Deactivate tenant.
- Archive tenant.
- Restore tenant.

---

## Company Profile Management

Each tenant shall maintain:

- Business name.
- Legal company name.
- Business logo.
- Contact details.
- Address.
- Tax information.
- Registration details.
- Business category.

---

## Subscription Management

Support:

- Trial plans.
- Paid subscriptions.
- Subscription upgrades.
- Subscription downgrades.
- Subscription renewal.
- Subscription expiry.
- Subscription cancellation.
- Feature limitations.

---

## Feature Management

Each tenant shall have configurable:

- Enabled modules.
- Feature flags.
- Business rules.
- Storage limits.
- User limits.
- Branch limits.
- API limits.

---

# Non-Functional Requirements

The Multi-Tenancy module must be:

- Secure.
- Highly Available.
- Scalable.
- Fault Tolerant.
- Cloud Native.
- Enterprise Grade.
- Multi-Tenant Aware.
- Production Ready.
- Maintainable.
- Extensible.

Performance requirements:

- Fast tenant lookup.
- Optimized tenant resolution.
- Efficient tenant filtering.
- Low-latency configuration loading.
- Horizontal scalability.

---

# Architecture Overview

The Multi-Tenancy module is the foundation of the SaaS architecture.

Every business registered on the platform becomes an independent tenant.

Each tenant owns its own:

- Users
- Branches
- Customers
- Services
- Orders
- Payments
- Expenses
- Reports
- Settings
- Audit Logs

No business operation should ever access another tenant's data.

Authentication identifies the user, while Multi-Tenancy identifies the organization to which the user belongs.

Every subsequent ERP module depends on the tenant context established during this phase.

---

# Repository Responsibilities

## Backend

Responsible for:

- Tenant APIs.
- Tenant services.
- Tenant repositories.
- Tenant validation.
- Subscription management.
- Feature management.
- Branding configuration.
- Tenant configuration.
- Tenant middleware.

---

## Frontend (Flutter Web)

Responsible for:

- Tenant registration screens.
- Company profile management.
- Subscription information.
- Branding management.
- Tenant settings.
- Business information management.

---

## Mobile (Flutter)

Responsible for:

- Business registration.
- Company profile viewing.
- Subscription status.
- Branding information.
- Tenant settings.
- Business information updates.

---

## Shared Packages

Should contain:

- Shared tenant models.
- Common DTO contracts.
- Configuration interfaces.
- Feature definitions.
- Subscription models.
- API contracts.
- Shared validation utilities.

---

# Module Responsibilities

The Multi-Tenancy module owns:

- Tenant lifecycle.
- Company information.
- Subscription information.
- Feature availability.
- Tenant configuration.
- Branding.
- Business identity.
- Tenant isolation.
- Default tenant initialization.

The module must not directly manage users, branches, customers, or orders, but it must provide the tenant context required by those modules.

# Collection: tenants

## Purpose

The `tenants` collection stores the master information of every business registered on the Nexoraa CleanSoft platform. Each document represents one independent organization with its own business identity, subscription, branding, configuration, and operational workspace.

---

## Fields

### _id
- Type: ObjectId
- Required
- Primary identifier of the tenant.

### businessName
- Type: String
- Required
- Stores the registered business name.

### businessType
- Type: String
- Required
- Defines the type of business such as Laundry, Salon, Tailoring, Repair Shop, Car Wash, etc.

### ownerName
- Type: String
- Required
- Stores the name of the business owner.

### ownerEmail
- Type: String
- Required
- Stores the owner's primary email address.

### ownerPhone
- Type: String
- Required
- Stores the owner's contact number.

### currency
- Type: String
- Required
- Defines the default currency used throughout the tenant.

### branding
- Type: Object
- Required
- Stores branding information for the tenant.

#### branding Fields

- logo
- favicon
- primaryColor
- secondaryColor
- theme
- companyDisplayName

### billingContact
- Type: Object
- Required
- Stores billing contact information.

#### billingContact Fields

- name
- email
- phone
- address

### subscriptionPlanId
- Type: ObjectId
- Required
- References the active subscription plan.

### status
- Type: Enum
- Required
- Represents the current tenant status.

Possible Values:

- Trial
- Active
- Suspended
- Expired
- Disabled

### createdBy
- Type: ObjectId
- Required
- References the user who created the tenant.

### updatedBy
- Type: ObjectId
- Optional
- References the last user who updated the tenant.

### deletedBy
- Type: ObjectId
- Optional
- References the user who performed the soft delete.

### createdAt
- Type: Date
- Automatically generated.

### updatedAt
- Type: Date
- Automatically updated.

### deletedAt
- Type: Date
- Optional.
- Populated during soft deletion.

### isDeleted
- Type: Boolean
- Default: false
- Indicates whether the tenant has been soft deleted.

---

## Validation Rules

- businessName is mandatory.
- businessType is mandatory.
- ownerName is mandatory.
- ownerEmail must be a valid email address.
- ownerPhone must be a valid mobile number.
- currency must contain a supported currency code.
- subscriptionPlanId must reference an existing subscription plan.
- status must contain a valid enum value.
- Soft deleted tenants cannot authenticate.
- Every tenant must have a unique business identity.

---

## Relationships

- One Tenant owns many Branches.
- One Tenant owns many Users.
- One Tenant owns many Customers.
- One Tenant owns many Services.
- One Tenant owns many Orders.
- One Tenant owns many Payments.
- One Tenant owns many Expenses.
- One Tenant owns many Cash Registers.
- One Tenant owns many Notifications.
- One Tenant owns many Audit Logs.
- One Tenant has one Configuration.
- One Tenant has one Active Subscription.

---

## Recommended Indexes

- businessName
- ownerEmail
- ownerPhone
- subscriptionPlanId
- status
- createdAt

---

## Audit Fields

- createdBy
- updatedBy
- deletedBy
- createdAt
- updatedAt
- deletedAt
- isDeleted

# Security Architecture

The Multi-Tenancy module is responsible for enforcing complete tenant isolation across the Nexoraa CleanSoft ERP. Every request processed by the platform must belong to a valid tenant, and no operation should allow one tenant to access another tenant's data. The security architecture should ensure logical isolation while allowing multiple businesses to securely share the same application infrastructure.

---

# Tenant Isolation

Tenant isolation is the core principle of the SaaS architecture.

### Requirements

- Every authenticated request must include a valid tenant context.
- Every database query must be filtered using the tenantId.
- Users must only access data belonging to their own tenant.
- Cross-tenant access must never be allowed.
- Tenant context should be propagated across all modules.
- Every new record created in the system must include tenantId.
- Tenant validation must occur before executing any business logic.

---

# Business Workspace Isolation

Each tenant should operate within its own isolated workspace.

### Workspace Components

- Company Profile
- Branches
- Users
- Customers
- Services
- Orders
- Payments
- Expenses
- Reports
- Dashboard
- Notifications
- Settings
- Audit Logs

No workspace component should be shared between tenants unless explicitly designed for platform-level administration.

---

# Subscription Management

The Multi-Tenancy module should manage the complete lifecycle of tenant subscriptions.

### Responsibilities

- Trial activation.
- Subscription activation.
- Subscription renewal.
- Subscription upgrade.
- Subscription downgrade.
- Subscription suspension.
- Subscription expiration.
- Subscription cancellation.

### Subscription Validation

- Verify active subscription before granting access.
- Validate subscription limits.
- Restrict disabled features.
- Notify tenants before subscription expiry.
- Prevent expired tenants from accessing restricted modules.

---

# Feature Management

Each tenant should have configurable feature access based on the subscribed plan.

### Supported Features

- Module Enable/Disable
- User Limits
- Branch Limits
- Storage Limits
- API Limits
- Reporting Features
- Notification Features
- Premium Features

Feature availability should be validated before executing any protected operation.

---

# Branding Management

Each tenant should be able to customize its business identity.

### Branding Components

- Company Name
- Logo
- Favicon
- Theme
- Primary Color
- Secondary Color
- Invoice Branding
- Business Contact Information

Branding updates should only affect the current tenant.

---

# Configuration Management

Every tenant should maintain independent business configurations.

### Configuration Categories

- Business Settings
- Invoice Settings
- Order Settings
- Tax Configuration
- Currency Settings
- Timezone
- Language
- Working Hours
- Notification Preferences
- Feature Flags

Configuration changes should never impact other tenants.

---

# Environment Variables

The Multi-Tenancy module should support configurable environment variables.

### Tenant Configuration

- DEFAULT_TRIAL_DAYS
- DEFAULT_CURRENCY
- DEFAULT_LANGUAGE
- DEFAULT_TIMEZONE

### Subscription Configuration

- MAX_TENANTS
- DEFAULT_PLAN
- ENABLE_TRIAL
- TRIAL_DURATION_DAYS

### Storage Configuration

- MAX_STORAGE_PER_TENANT
- FILE_UPLOAD_LIMIT
- DEFAULT_LOGO_PATH

---

# Logging Strategy

Every tenant operation should generate structured logs.

### Log Events

- Tenant Created
- Tenant Updated
- Tenant Activated
- Tenant Suspended
- Tenant Deleted
- Subscription Updated
- Feature Updated
- Branding Updated
- Configuration Updated

Sensitive business information should never be written to application logs.

---

# Audit Strategy

Every critical tenant operation must generate an audit record.

### Audit Events

- Tenant Registration
- Tenant Activation
- Tenant Suspension
- Subscription Changes
- Branding Changes
- Configuration Changes
- Feature Flag Changes
- Tenant Deletion

Each audit record should include:

- Tenant ID
- User ID
- Action
- Module
- Previous Value
- New Value
- Timestamp
- IP Address
- Correlation ID

---

# Error Handling

The module should return standardized errors for all tenant operations.

### Common Errors

- Tenant Not Found
- Tenant Already Exists
- Invalid Tenant Code
- Subscription Expired
- Subscription Not Found
- Feature Disabled
- Maximum User Limit Reached
- Maximum Branch Limit Reached
- Unauthorized Tenant Access
- Invalid Configuration

Errors should use a consistent response format with machine-readable error codes.

---

# Background Jobs

The Multi-Tenancy module should support background processing for long-running tasks.

### Scheduled Jobs

- Trial Expiry Check
- Subscription Renewal Check
- Subscription Expiry Reminder
- Tenant Suspension
- Tenant Reactivation
- Feature Synchronization
- Configuration Synchronization
- Inactive Tenant Cleanup

---

# Third-Party Integrations

The module should integrate with supporting platform services.

### Internal Integrations

- Authentication Module
- Branch Management
- User Management
- Settings Module
- Notification Module
- Audit Module
- Reports Module
- Dashboard Module

### External Integrations

- Payment Gateway
- Email Service
- SMS Provider
- Cloud Storage
- Subscription Billing Platform

---

# Security Requirements

The Multi-Tenancy module should enforce enterprise-grade security.

### Security Controls

- Complete Tenant Isolation
- Server-Side Validation
- Subscription Validation
- Feature Authorization
- Role-Based Access Control (RBAC)
- Input Validation
- Output Sanitization
- Secure Configuration Updates
- Least Privilege Access
- Data Encryption for Sensitive Information

---

# Tenant Lifecycle

Every tenant should follow a controlled lifecycle.

### Lifecycle States

- Trial
- Active
- Suspended
- Expired
- Disabled

### Lifecycle Rules

- Only active tenants can access all enabled modules.
- Trial tenants are limited by trial configuration.
- Suspended tenants cannot perform business operations.
- Expired tenants require subscription renewal.
- Disabled tenants cannot authenticate or access the platform.

---

# Cross-Module Dependencies

The Multi-Tenancy module provides tenant context for all ERP modules.

### Dependent Modules

- Authentication
- Branch Management
- User Management
- Customer Management
- Service Management
- Order Management
- Payment Management
- Expense Management
- Reports
- Dashboard
- Notifications
- Settings

Every dependent module must use the tenant context established by this module before processing any business request.

# Testing Strategy

The Multi-Tenancy module must be thoroughly tested to ensure complete tenant isolation, secure business registration, reliable subscription management, and consistent configuration handling. Since every ERP module depends on the tenant context, this module must be validated before any business module is implemented.

Testing should verify business functionality, security, performance, scalability, integration, and data isolation across multiple tenants.

---

# Unit Testing

Unit tests should validate individual business components independently.

### Tenant Management

- Tenant creation.
- Tenant update.
- Tenant activation.
- Tenant suspension.
- Tenant deactivation.
- Tenant deletion.

### Company Profile

- Company information validation.
- Contact information validation.
- Branding validation.
- Business type validation.

### Subscription Management

- Subscription creation.
- Trial activation.
- Subscription renewal.
- Subscription expiry.
- Subscription upgrade.
- Subscription downgrade.

### Feature Management

- Feature enable.
- Feature disable.
- Module access validation.
- User limit validation.
- Branch limit validation.

### Configuration Management

- Configuration creation.
- Configuration update.
- Default configuration initialization.
- Localization validation.
- Currency validation.
- Timezone validation.

---

# Integration Testing

Integration tests should verify communication between the Multi-Tenancy module and dependent services.

### Authentication Integration

- Tenant resolution during login.
- Active tenant validation.
- Disabled tenant restriction.

### Branch Integration

- Default branch creation.
- Branch ownership validation.
- Branch limit enforcement.

### User Integration

- Business owner creation.
- User association with tenant.
- User access validation.

### Notification Integration

- Welcome notification.
- Subscription reminder.
- Trial expiry notification.

### Audit Integration

- Tenant creation logs.
- Configuration changes.
- Subscription updates.
- Branding updates.

---

# Security Testing

The module should be tested against common SaaS security threats.

### Tenant Isolation

- Cross-tenant access prevention.
- Unauthorized tenant access.
- Tenant ID tampering.
- Direct database access validation.
- API isolation validation.

### Authorization

- Unauthorized configuration updates.
- Unauthorized branding changes.
- Unauthorized subscription updates.
- Invalid permission validation.

### Input Validation

- Invalid company information.
- Invalid email addresses.
- Invalid phone numbers.
- Invalid subscription plans.
- Invalid feature configuration.
- Invalid tenant status.

---

# Performance Testing

The Multi-Tenancy module should maintain high performance under normal and peak workloads.

### Performance Validation

- Tenant registration response time.
- Tenant lookup performance.
- Configuration loading.
- Subscription retrieval.
- Branding retrieval.
- Feature validation.

### Load Testing

- Concurrent tenant registration.
- Concurrent tenant updates.
- Large-scale tenant retrieval.
- Multiple tenant configuration requests.
- High-volume subscription validation.

---

# End-to-End Testing

The complete tenant lifecycle should be verified.

### Tenant Registration

- Register a new business.
- Generate tenant workspace.
- Create default configuration.
- Initialize subscription.
- Create default branch.
- Verify successful activation.

### Tenant Management

- Update company profile.
- Update branding.
- Update configuration.
- Change subscription.
- Suspend tenant.
- Reactivate tenant.

### Subscription Lifecycle

- Trial activation.
- Subscription renewal.
- Subscription expiry.
- Upgrade plan.
- Downgrade plan.
- Cancel subscription.

---

# Flutter Testing

The Flutter Web and Mobile applications should provide a consistent tenant management experience.

### Widget Testing

- Business registration form.
- Company profile form.
- Branding form.
- Configuration form.
- Subscription information.
- Validation messages.

### Integration Testing

- Complete business registration.
- Tenant profile updates.
- Branding updates.
- Configuration updates.
- Subscription viewing.

---

# Web Application Testing

The web application should support secure and responsive tenant management.

### UI Validation

- Responsive layouts.
- Form validation.
- Error handling.
- Loading states.
- Success messages.
- Accessibility compliance.

---

# Deliverables

The Multi-Tenancy phase should deliver:

### Backend

- Tenant module.
- Tenant APIs.
- Company profile management.
- Subscription management.
- Feature management.
- Configuration management.
- Branding management.
- Tenant isolation middleware.

### Frontend

- Business registration pages.
- Company profile pages.
- Branding management.
- Subscription management.
- Tenant settings.

### Mobile

- Business registration flow.
- Company profile management.
- Tenant settings.
- Subscription information.
- Branding management.

### Documentation

- Tenant architecture.
- Database documentation.
- API documentation.
- Security documentation.
- Configuration guide.
- Testing documentation.

---

# Acceptance Criteria

The Multi-Tenancy module will be considered complete when all of the following conditions are satisfied.

### Functional Acceptance

- New tenants can be registered successfully.
- Company profiles can be managed.
- Tenant configuration is initialized automatically.
- Branding updates function correctly.
- Subscription management works correctly.
- Feature configuration is applied successfully.

### Security Acceptance

- Complete tenant isolation is enforced.
- Cross-tenant access is impossible.
- Subscription validation works correctly.
- RBAC permissions are enforced.
- Sensitive configuration updates are protected.

### Performance Acceptance

- Tenant registration meets performance requirements.
- Tenant lookup is optimized.
- Configuration loading is efficient.
- Subscription validation scales correctly.

### Quality Acceptance

- Unit tests pass.
- Integration tests pass.
- Security tests pass.
- End-to-End tests pass.
- Flutter tests pass.
- Web application tests pass.

---

# Implementation Sequence

The Multi-Tenancy implementation should follow this sequence:

1. Verify previous phase completion.
2. Review repository architecture.
3. Design the tenant data model.
4. Create tenant lifecycle management.
5. Implement company profile management.
6. Implement subscription management.
7. Implement tenant configuration.
8. Implement branding management.
9. Configure feature management.
10. Enforce tenant isolation.
11. Integrate with Authentication.
12. Configure logging and audit support.
13. Complete frontend implementation.
14. Complete Flutter implementation.
15. Execute all testing.
16. Validate acceptance criteria.
17. Update documentation.
18. Update the corresponding Phase Completion Report.
19. Stop execution without starting the next phase.

---

# Completion Instructions

Before closing this phase:

- Verify every acceptance criterion.
- Ensure all required tests have passed.
- Review architecture consistency.
- Confirm tenant isolation across all modules.
- Validate subscription and feature management.
- Review API documentation.
- Review database documentation.
- Update only the corresponding Multi-Tenancy Phase Completion report.
- Record architecture decisions, assumptions, and known limitations.
- Do not modify future phase documentation.
- Stop execution immediately after completing this phase.

The completion report should accurately document the implementation, repository changes, testing evidence, security validations, performance observations, limitations, and recommendations for the next phase.