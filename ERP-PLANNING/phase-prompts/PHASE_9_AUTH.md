# PHASE 09 – AUTHENTICATION IMPLEMENTATION PROMPT

## Phase Number

01

## Phase Name

Authentication

---

# Role

You are a Senior Enterprise Software Architect and Lead Full Stack Engineer responsible for implementing the Authentication module of the Nexoraa CleanSoft ERP platform.

Your responsibility in this phase is to implement a secure, scalable, multi-tenant authentication system that serves as the security foundation of the ERP. Every authenticated request throughout the application will depend on the services established during this phase.

Implement only the Authentication module. Do not implement Multi-Tenancy, Branch Management, User Management, Customer Management, Orders, Payments, Reports, Notifications, or any unrelated module except where minimal integration is required.

---

# Phase Dependencies

Before starting implementation, perform the following verification steps:

1. Read the previous phase completion report.
2. Verify that the Foundation phase has been completed successfully.
3. Review the project architecture and repository structure.
4. Understand all coding standards and naming conventions.
5. Verify shared packages and infrastructure are available.
6. Maintain backward compatibility.
7. Never overwrite completed implementations.
8. Continue only after successful verification.

---

# Objective

Implement a production-ready Authentication module that provides secure user authentication, authorization, tenant identification, branch resolution, session management, and password recovery.

The module must establish the security boundary for every future ERP module while maintaining complete tenant isolation, branch awareness, and role-based access control.

---

# Business Objectives

The Authentication module should enable secure access to the ERP while ensuring that only authorized users can perform business operations within their assigned tenant and branch.

The module must support secure login, token management, password lifecycle management, account security, and session control while providing a seamless user experience across web and mobile applications.

---

# Scope

This phase includes:

- User Authentication
- Login
- Logout
- JWT Access Token
- JWT Refresh Token
- Refresh Token Rotation
- Session Management
- Password Change
- Forgot Password
- Password Reset using OTP
- Account Lockout
- Tenant Identification
- Branch Resolution
- RBAC Integration
- Authentication Middleware
- Authentication APIs
- Refresh Token Storage
- Password Reset Token Storage
- Authentication Audit Logging
- Security Validation
- Authentication Documentation
- Authentication Testing

---

# Out of Scope

Do not implement:

- User Management
- Tenant Management
- Branch Management
- Customer Management
- Orders
- Payments
- Inventory
- Reports
- Notifications
- Dashboard
- Search
- Billing
- Expense Management

These modules belong to later implementation phases.

---

# Functional Requirements

The Authentication module shall provide:

## Identity Verification

- Authenticate users using email or registered mobile number.
- Verify password credentials securely.
- Validate account status before authentication.
- Validate tenant status before granting access.
- Resolve tenant context automatically.
- Resolve branch context automatically.

---

## Token Management

The module shall support:

- JWT Access Tokens
- JWT Refresh Tokens
- Refresh Token Rotation
- Token Expiration
- Token Revocation
- Session Validation
- Secure Logout
- Multiple Device Sessions (configurable)

---

## Session Management

The system shall:

- Track active sessions.
- Allow session invalidation.
- Support logout from current device.
- Support logout from all devices.
- Expire inactive sessions.
- Prevent replay attacks.

---

## Password Management

The module shall support:

- Change Password
- Forgot Password
- Password Reset using OTP
- Password Strength Validation
- Password Expiration Policy (configurable)
- Password History Validation (future-ready)

---

## Account Security

Implement support for:

- Failed Login Tracking
- Account Lock after configurable failed attempts
- Automatic Unlock Timer
- Manual Unlock
- Brute Force Protection
- Replay Attack Protection
- Suspicious Login Detection (future-ready)

---

# Non-Functional Requirements

The Authentication module must be:

- Secure
- Highly Available
- Scalable
- Stateless
- Fault Tolerant
- Enterprise Grade
- Production Ready
- Audit Enabled
- Maintainable
- Extensible

Performance requirements:

- Login response < 500ms
- Token validation < 100ms
- Password hashing using bcrypt
- Secure JWT signing
- Horizontal scalability

---

# Architecture Overview

Authentication is the first business module implemented within the ERP.

Every protected API must authenticate users before processing requests.

The module is responsible for:

- User Identity
- Authentication
- Authorization
- Session Lifecycle
- Security Context
- Tenant Context
- Branch Context

All future modules consume the authenticated security context established here.

---

# Repository Responsibilities

Backend

- Authentication APIs
- JWT Services
- Token Validation
- Session Management
- Password Reset Logic
- Refresh Token Management
- Security Middleware

Frontend (Flutter Web)

- Login Screen
- Forgot Password Screen
- Reset Password Screen
- Session Expiration Handling
- Secure Token Storage
- Authentication Guards

Mobile (Flutter)

- Login Flow
- Session Persistence
- Secure Authentication
- Token Refresh
- Logout
- Password Reset Flow

Shared Packages

- Authentication DTOs
- Shared Models
- JWT Interfaces
- Permission Models
- API Contracts
- Validation Utilities

# Database Documentation

The Authentication module is responsible for securely managing user sessions, refresh tokens, password reset requests, and authentication-related metadata. While user profile information is managed by the User Management module, Authentication owns all temporary security credentials and session lifecycle records.

The database design should prioritize security, scalability, auditability, and efficient lookup performance.

---

# MongoDB Collections

The Authentication module introduces the following collections:

1. refreshTokens
2. passwordResetTokens

These collections are owned exclusively by the Authentication module.

---

# Collection: refreshTokens

## Purpose

This collection stores active refresh tokens issued to authenticated users. It enables secure session management, refresh token rotation, logout, and token revocation without requiring users to log in repeatedly.

Refresh tokens should never be stored in plain text. Only securely hashed values should be persisted.

---

## Fields

### \_id

- MongoDB ObjectId
- Primary identifier

### tenantId

- ObjectId
- Required
- References Tenant

### branchId

- ObjectId
- Required
- References Branch

### userId

- ObjectId
- Required
- References User

### tokenHash

- String
- Required
- Store only hashed refresh token

### deviceId

- String
- Optional
- Identifies client device

### deviceName

- String
- Optional
- Browser or mobile device name

### ipAddress

- String
- Optional

### userAgent

- String
- Optional

### expiresAt

- Date
- Required

### revoked

- Boolean
- Default false

### revokedAt

- Date
- Optional

### revokedBy

- ObjectId
- Optional

### createdAt

- Date

### updatedAt

- Date

---

## Relationships

- Many Refresh Tokens belong to one User.
- One User can have multiple active sessions.
- Each Refresh Token belongs to one Tenant.
- Each Refresh Token belongs to one Branch.

---

## Recommended Indexes

- tenantId
- userId
- tokenHash (Unique)
- expiresAt (TTL)
- revoked
- createdAt

---

## Validation Rules

- tokenHash cannot be empty.
- expiresAt must be greater than current time.
- revoked defaults to false.
- tenantId must exist.
- userId must exist.
- branchId must exist.

---

# Collection: passwordResetTokens

## Purpose

Stores temporary password reset requests and OTP verification information used during password recovery.

Passwords are never stored here.

OTP values should be securely hashed before storage.

---

## Fields

### \_id

- ObjectId

### tenantId

- ObjectId

### userId

- ObjectId

### otpHash

- String

### expiresAt

- Date

### attempts

- Number

### verified

- Boolean

### consumed

- Boolean

### createdAt

- Date

---

## Relationships

- One User may have multiple reset requests.
- Only one active reset request should exist at a time.

---

## Indexes

- tenantId
- userId
- expiresAt (TTL)
- verified

---

## Validation Rules

- OTP must contain exactly six digits before hashing.
- OTP expiration should be configurable.
- Maximum verification attempts should be configurable.
- Expired requests cannot be reused.
- Consumed requests cannot be reused.

---

# Data Ownership

Authentication owns:

- Refresh Tokens
- Password Reset Tokens
- Session Information
- Authentication Audit Records

Authentication does not own:

- User Profile
- Tenant
- Branch
- Roles
- Permissions

Those remain owned by their respective modules.

---

# Authentication APIs

The module should expose secure REST APIs.

---

## Login

**Method**

POST

**Endpoint**

/auth/login

### Purpose

Authenticate user credentials and create an authenticated session.

### Request

- Email or Mobile Number
- Password

### Response

- Access Token
- Refresh Token
- User Summary
- Tenant Information
- Branch Information
- Permissions

---

## Refresh Token

POST

/auth/refresh

### Purpose

Generate a new access token using a valid refresh token while rotating the refresh token.

---

## Logout

POST

/auth/logout

### Purpose

Invalidate the current refresh token and terminate the active session.

---

## Forgot Password

POST

/auth/forgot-password

### Purpose

Generate a password reset request and send a one-time password (OTP) to the registered communication channel.

---

## Reset Password

POST

/auth/reset-password

### Purpose

Validate the OTP and securely update the user's password.

---

## Change Password

POST

/auth/change-password

### Purpose

Allow authenticated users to change their current password after validating the existing password.

---

# Authentication Flow

The Authentication lifecycle should follow these steps:

1. User submits login credentials.
2. Credentials are validated.
3. Tenant status is verified.
4. User account status is verified.
5. Branch access is resolved.
6. RBAC permissions are loaded.
7. JWT Access Token is generated.
8. Refresh Token is generated.
9. Refresh Token hash is stored.
10. Session information is recorded.
11. Authentication response is returned.

---

# Password Recovery Flow

1. User requests password reset.
2. System validates account.
3. Secure OTP is generated.
4. OTP hash is stored.
5. OTP is delivered.
6. User verifies OTP.
7. Password is updated.
8. Previous refresh tokens are revoked.
9. User logs in again.

---

# Session Lifecycle

The Authentication module should support:

- Login
- Refresh Session
- Logout Current Device
- Logout All Devices
- Session Expiration
- Session Revocation
- Refresh Token Rotation
- Concurrent Session Management (Configurable)

All session activity must be auditable and securely managed while preserving tenant and branch isolation.

# Security Architecture

The Authentication module is the security gateway of the Nexoraa CleanSoft ERP. Every protected request must pass through this module before accessing any business functionality. It is responsible for verifying user identity, establishing the security context, enforcing authorization rules, and protecting the platform from unauthorized access.

The security design should follow a **Zero Trust** approach where every request is authenticated, authorized, validated, and audited regardless of its origin.

---

# Authentication Strategy

The platform shall use JWT-based authentication with short-lived Access Tokens and long-lived Refresh Tokens.

### Authentication Components

- JWT Access Token
- JWT Refresh Token
- Refresh Token Rotation
- Session Validation
- Secure Logout
- Password Hashing
- OTP Verification
- Account Lock Protection

### Authentication Flow

1. User submits login credentials.
2. Credentials are validated.
3. User account is verified.
4. Tenant is verified.
5. Branch access is resolved.
6. Permissions are loaded.
7. Access Token is generated.
8. Refresh Token is generated.
9. Session is stored.
10. User receives authentication response.

---

# JWT Token Structure

The Access Token should contain only the minimum information required for authorization.

### Recommended Payload

- User ID
- Tenant ID
- Branch ID
- User Role
- Permission List
- Session ID
- Token Version
- Issued At
- Expiration Time

Sensitive business information should never be stored inside the JWT payload.

---

# Refresh Token Strategy

Refresh Tokens should provide secure session continuation without requiring users to log in repeatedly.

### Requirements

- Store only hashed refresh tokens.
- Rotate refresh tokens after every refresh request.
- Revoke old refresh tokens immediately.
- Prevent replay attacks.
- Support multiple active sessions (configurable).
- Support logout from current device.
- Support logout from all devices.

---

# Role-Based Access Control (RBAC)

Authentication establishes the security context required for Role-Based Access Control.

### Responsibilities

- Verify authenticated user.
- Load assigned role.
- Load permissions.
- Resolve tenant context.
- Resolve branch context.
- Pass security context to all protected modules.

### Example Roles

- Platform Administrator
- Tenant Owner
- Branch Manager
- Cashier
- Staff
- Delivery Executive

The Authentication module authenticates users but does not manage roles. Role management belongs to the User Management module.

---

# Tenant Isolation

Tenant isolation is one of the most critical security requirements of the ERP.

### Requirements

- Every authenticated request must include tenant context.
- Users can only access their assigned tenant.
- Cross-tenant access must never be allowed.
- Tenant validation occurs before business logic execution.
- Tenant context must be propagated across services.

---

# Branch Isolation

Branch isolation restricts users to authorized business locations.

### Requirements

- Resolve active branch during authentication.
- Verify branch belongs to authenticated tenant.
- Restrict branch-specific operations.
- Support users assigned to multiple branches.
- Prevent unauthorized branch switching.

---

# Password Security

Passwords should never be stored or transmitted in plain text.

### Security Standards

- Hash passwords using bcrypt.
- Configurable work factor.
- Minimum password length.
- Complexity validation.
- Password confirmation.
- Password history support (future-ready).

### Password Policy

- Minimum 8 characters.
- Uppercase letter.
- Lowercase letter.
- Number.
- Special character.
- No common passwords.

---

# Account Protection

The Authentication module should protect against unauthorized access attempts.

### Security Features

- Failed login tracking.
- Configurable account lock.
- Automatic unlock timer.
- Manual unlock.
- Brute-force prevention.
- Login attempt throttling.
- Suspicious activity monitoring.

---

# OTP Security

Password recovery should use secure One-Time Passwords.

### OTP Requirements

- Six-digit numeric OTP.
- Configurable expiration.
- Store only hashed OTP.
- Maximum verification attempts.
- Single-use OTP.
- Automatic expiration.

---

# Security Headers

The backend should enforce secure HTTP communication.

### Recommended Headers

- Authorization
- Content-Type
- X-Request-ID
- X-Correlation-ID
- X-Forwarded-For
- User-Agent

---

# Environment Variables

Authentication should be configurable using environment variables.

### JWT Configuration

- JWT_SECRET
- JWT_EXPIRES_IN
- JWT_REFRESH_SECRET
- JWT_REFRESH_EXPIRES_IN

### Password Configuration

- BCRYPT_ROUNDS
- PASSWORD_MIN_LENGTH

### OTP Configuration

- OTP_EXPIRY_MINUTES
- OTP_MAX_ATTEMPTS

### Security Configuration

- LOGIN_MAX_ATTEMPTS
- ACCOUNT_LOCK_DURATION
- SESSION_TIMEOUT

---

# Logging Strategy

Every authentication event should be logged for operational monitoring.

### Log Events

- Login Success
- Login Failure
- Logout
- Password Changed
- Password Reset
- Token Refresh
- Session Expired
- Account Locked
- Account Unlocked

Sensitive information such as passwords, tokens, and OTP values must never appear in logs.

---

# Audit Strategy

Every security-sensitive operation should generate an audit record.

### Audit Events

- User Login
- User Logout
- Password Change
- Password Reset
- Account Lock
- Account Unlock
- Refresh Token Revocation
- Session Revocation

Each audit record should include:

- User ID
- Tenant ID
- Branch ID
- Timestamp
- Action
- IP Address
- Device Information
- Correlation ID

---

# Error Handling

Authentication errors should be standardized.

### Common Errors

- Invalid Credentials
- User Not Found
- Account Locked
- Tenant Disabled
- Branch Not Found
- Token Expired
- Token Invalid
- Session Expired
- OTP Expired
- OTP Invalid
- Permission Denied

Every error should return a consistent response structure with machine-readable error codes.

---

# Background Processing

Authentication may trigger asynchronous operations.

### Background Jobs

- OTP Delivery
- Expired Token Cleanup
- Expired OTP Cleanup
- Session Cleanup
- Security Notifications
- Audit Log Processing

---

# Third-Party Integrations

The Authentication module may integrate with external services.

### Supported Integrations

- Email Provider
- SMS Gateway
- Push Notification Service
- Identity Provider (Future)
- OAuth Providers (Future)
- SSO Integration (Future)

---

# Configuration Requirements

The Authentication module should support centralized configuration.

### Configurable Features

- Token Expiration
- Password Policy
- OTP Settings
- Session Limits
- Login Attempts
- Lock Duration
- Remember Me
- Multi-Device Sessions

All configuration should be environment-driven and validated during application startup.

# Testing Strategy

The Authentication module must undergo comprehensive testing to ensure security, reliability, performance, and correctness. Since authentication is the entry point for every protected resource in the ERP, every workflow should be thoroughly validated before production deployment.

Testing should cover successful scenarios, validation failures, security threats, concurrent requests, tenant isolation, branch isolation, and integration with dependent modules.

---

# Unit Testing

Unit tests should validate individual business logic components without depending on external systems.

### Authentication Logic

- Login credential validation.
- Password verification.
- JWT generation.
- JWT validation.
- Refresh token creation.
- Refresh token rotation.
- Session creation.
- Session termination.

### Password Management

- Password complexity validation.
- Password hashing.
- Password comparison.
- Password change validation.
- Password reset validation.

### OTP Management

- OTP generation.
- OTP validation.
- OTP expiration.
- Maximum retry validation.
- OTP consumption.

### Security Validation

- Failed login counting.
- Account locking.
- Account unlocking.
- Permission validation.
- Tenant resolution.
- Branch resolution.

---

# Integration Testing

Integration tests should verify communication between the Authentication module and supporting infrastructure.

### Database Integration

- Refresh Token persistence.
- Password Reset Token persistence.
- Session storage.
- TTL expiration.
- Index validation.

### API Integration

- Login endpoint.
- Logout endpoint.
- Refresh endpoint.
- Forgot Password endpoint.
- Reset Password endpoint.
- Change Password endpoint.

### External Service Integration

- Email service.
- SMS provider.
- Notification service.
- Audit logging.
- Shared authentication package.

---

# Security Testing

Authentication must be tested against common security threats.

### Authentication Security

- Invalid credentials.
- Invalid JWT.
- Expired JWT.
- Expired Refresh Token.
- Replay attack prevention.
- Token tampering.
- Session hijacking.

### Authorization Security

- Unauthorized access.
- Missing permissions.
- Invalid roles.
- Cross-tenant access.
- Cross-branch access.
- Privilege escalation attempts.

### Input Validation

- SQL Injection attempts.
- NoSQL Injection attempts.
- XSS payloads.
- Invalid request bodies.
- Oversized payloads.
- Missing required fields.

---

# Performance Testing

Authentication should remain responsive under normal and peak workloads.

### Performance Validation

- Login response time.
- Token refresh latency.
- Password reset response.
- Concurrent login requests.
- Session validation performance.
- Database query efficiency.

### Load Testing

- Multiple concurrent users.
- High login frequency.
- Multiple refresh requests.
- OTP generation under load.
- Token validation under load.

---

# End-to-End Testing

The complete authentication lifecycle should be verified from the user's perspective.

### User Authentication

- Successful login.
- Invalid login.
- Locked account.
- Disabled account.
- Tenant validation.
- Branch validation.

### Session Lifecycle

- Login.
- Refresh token.
- Logout.
- Logout all devices.
- Session expiration.
- Session revocation.

### Password Lifecycle

- Forgot password.
- Receive OTP.
- Verify OTP.
- Reset password.
- Login using new password.
- Reject old password.

---

# Flutter Testing

Authentication should behave consistently across Flutter Web, Android, and iOS.

### Widget Testing

- Login form.
- Forgot Password form.
- Reset Password form.
- Change Password form.
- Validation messages.
- Loading indicators.

### Integration Testing

- Complete login flow.
- Token persistence.
- Session restoration.
- Logout flow.
- Password reset flow.

---

# Web Application Testing

The web application should provide a secure and accessible authentication experience.

### UI Validation

- Responsive layout.
- Form validation.
- Error handling.
- Loading states.
- Success messages.
- Accessibility compliance.

---

# Deliverables

The Authentication phase should deliver:

### Backend

- Authentication module.
- JWT implementation.
- Refresh Token management.
- Password reset workflow.
- OTP verification.
- Authentication middleware.
- Security guards.

### Frontend

- Login page.
- Forgot Password page.
- Reset Password page.
- Session handling.
- Logout functionality.

### Mobile

- Login flow.
- Secure session storage.
- Password reset flow.
- Logout support.

### Documentation

- Authentication architecture.
- Database documentation.
- API documentation.
- Security documentation.
- Configuration guide.
- Testing documentation.

---

# Acceptance Criteria

The Authentication module will be considered complete when all of the following conditions are satisfied.

### Functional Acceptance

- Users can securely log in.
- JWT authentication functions correctly.
- Refresh Tokens rotate correctly.
- Password reset workflow is complete.
- OTP verification functions correctly.
- Logout invalidates sessions.
- Session management functions correctly.

### Security Acceptance

- Passwords are securely hashed.
- Refresh Tokens are securely stored.
- Tenant isolation is enforced.
- Branch isolation is enforced.
- RBAC validation succeeds.
- Account lockout functions correctly.
- Replay attacks are prevented.

### Performance Acceptance

- Login performance meets requirements.
- Token validation is efficient.
- Session management scales correctly.
- Database queries are optimized.

### Quality Acceptance

- Unit tests pass.
- Integration tests pass.
- Security tests pass.
- End-to-End tests pass.
- Flutter tests pass.
- Web application tests pass.

---

# Implementation Sequence

The Authentication implementation should follow this sequence:

1. Verify previous phase completion.
2. Review repository architecture.
3. Configure authentication module.
4. Design authentication data model.
5. Implement JWT strategy.
6. Implement refresh token management.
7. Implement password management.
8. Implement OTP workflow.
9. Implement session management.
10. Implement authentication APIs.
11. Integrate RBAC.
12. Configure tenant and branch resolution.
13. Add logging and audit support.
14. Complete frontend authentication flow.
15. Complete Flutter authentication flow.
16. Execute all testing.
17. Validate acceptance criteria.
18. Update documentation.
19. Update the corresponding Phase Completion Report.
20. Stop execution without starting the next phase.

---

# Completion Instructions

Before closing this phase:

- Verify every acceptance criterion.
- Ensure all required tests have passed.
- Review architecture consistency.
- Confirm security requirements.
- Validate tenant and branch isolation.
- Review API documentation.
- Review database documentation.
- Update only the corresponding Authentication Phase Completion report.
- Record assumptions, architectural decisions, and known limitations.
- Do not modify future phase documentation.
- Stop execution immediately after completing this phase.

The completion report should accurately reflect the work completed, files created or modified, testing evidence, outstanding limitations, and any recommendations for subsequent phases.
