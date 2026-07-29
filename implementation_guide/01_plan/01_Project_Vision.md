# Project Vision

## Source

This vision is reconstructed from the existing Phase 1 Software Idea and Phase 2 System Planning documents. It preserves their product intent while removing duplicated theory and the retired Flutter web-client scope.

## Product

Nexoraa CleanSoft ERP is a cloud-oriented, multi-tenant operating platform for small and medium service businesses. It serves businesses whose common lifecycle is to receive a customer request or item, perform work, collect payment, and return, deliver, or complete the service.

Initial examples in the source include laundry, dry cleaning, shoe cleaning, tailoring and alterations, device and appliance repair, car and bike wash, salon, spa, beauty clinic, pet grooming, printing, and other configurable service shops.

## Problem

The target businesses commonly depend on paper registers, handwritten receipts, spreadsheets, calls, and messaging applications. This creates:

- Incomplete or duplicated customer information.
- Lost order visibility and inconsistent status updates.
- Weak employee accountability.
- Payment and order reconciliation problems.
- Manual reporting.
- Poor multi-branch visibility.
- Repeated customer communication work.
- Systems that are too expensive, rigid, or designed for inventory-heavy industries.

## Vision

Nexoraa CleanSoft should become the daily operating system for service businesses: one governed source of truth for customers, operations, payments, staff accountability, settings, communication, and business insight.

The platform should feel adaptable to each tenant without creating industry-specific code forks. Tenants may configure services, item categories, pricing, tax, terminology, branding, notifications, and operational policies while the platform retains stable canonical concepts and security boundaries.

## Mission

Digitally transform small and medium service businesses with enterprise-grade software that is affordable, scalable, understandable, secure, and adaptable. Reduce operational complexity while improving productivity, transparency, accountability, customer experience, and profitability.

## Target users

- Platform Super Administrators who govern tenant lifecycle and plans without implicit access to tenant operations.
- Tenant Owners who administer the whole business and view tenant-wide results.
- Branch Managers who run assigned branches.
- Staff who perform assigned operational work.
- Cashiers who create orders, collect payments, issue receipts, and reconcile branch cash.
- Delivery-assigned staff who complete governed pickup/delivery work.
- Customers who receive service, receipts, and notifications.
- Support and operations personnel using separately governed, time-bound access.
- Engineers and reviewers who need authoritative, traceable implementation contracts.

Detailed permission ceilings appear in `03_User_Personas.md`.

## Core workflow

1. An eligible business becomes a tenant and receives an initial workspace.
2. The Owner configures branches, staff access, services, item categories, pricing, tax, payment methods, branding, and policies.
3. Staff find or create a customer, or use approved lightweight walk-in handling.
4. Staff create an order using authoritative catalog data; the server calculates totals and freezes historical snapshots.
5. Assigned staff move the order through allowed states, recording actor, time, prior state, next state, and notes.
6. One or more payments settle the order; refunds and corrections remain additive.
7. The completed work is collected or delivered with proof where required.
8. Branch expenses and cash registers reconcile operational money.
9. In-app and entitled external notifications inform staff and customers without controlling the source transaction.
10. Search, reports, dashboards, and immutable audit evidence provide governed visibility.

## Unique value

- One configurable platform supports multiple service industries.
- Tenant and branch isolation are enforced by the backend, not trusted to client filtering.
- Historical pricing and financial records remain accurate through immutable snapshots and additive corrections.
- Owners receive tenant-wide control while operational roles remain branch- and assignment-scoped.
- Business modules share contracts and events without reading another service's private persistence.
- The Android/iOS Flutter client uses the same governed backend contracts.

## Product principles preserved from the source

- Security and isolation are invariants, not optional features.
- The server is authoritative for identity, authorization, totals, financial state, and lifecycle rules.
- Every business capability has one owner.
- Events represent completed facts, not disguised remote commands.
- Operational failure must degrade safely.
- Notification or export outages must not roll back successful orders or payments.
- Finalized financial and audit records are immutable or correction-based.
- New modules reuse tenant, branch, RBAC, audit, observability, retention, and contract foundations.

## Success

Success means a service business can replace fragmented manual processes with a reliable daily workflow, grow from one branch to many without redesign, trace operational and financial history, and give every actor only the information and actions their role permits.

