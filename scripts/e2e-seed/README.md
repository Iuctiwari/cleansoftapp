# End-to-end check + test data seed

`seed.mjs` tests the **deployed backend** the way the mobile app uses it, and fills a brand-new **test tenant** with realistic data you can then browse in the app.

It never touches existing tenants. Each run registers its own business (`E2E Test Laundry <date>-<id>`) with its own owner login.

## Run it

Needs Node 22+ and nothing else. From the repo root:

```bash
node scripts/e2e-seed/seed.mjs
```

Choose how much data (defaults shown):

```bash
node scripts/e2e-seed/seed.mjs --branches 2 --customers 30 --staff 4 --orders 60 --expenses 25 --concurrency 4
```

Point it at another server: `--domain 1-2-3-4.sslip.io` (default `65-1-66-219.sslip.io`).

## What it checks (≈ 90–100 checks)

| # | Area | Checks |
|---|---|---|
| 0 | All 13 services | Each answers over HTTPS (not a 502 from Caddy) |
| 1 | Sign-up + login | Register tenant, owner login, wrong password rejected, auth context |
| 2 | Profile | Read, **edit profile** (the old `/api/v1/api/v1` bug), branches |
| 3 | Branches | Create, list, statistics |
| 4 | Subscription | Plans from Company Admin visible to tenant, select plan, status, tenant config |
| 5 | Catalog | Item categories, services (per-item + per-kg), mappings, pricing; **quote = price set** |
| 6 | Customers | Bulk create, list, search, edit, statistics |
| 7 | Staff | Register Staff / Cashier / Branch Manager, list, **staff login** |
| 8 | Orders | Create (**subtotal checked against catalog prices**, never ₹0), advance payments, overpayment rejected, workflow Received → InProgress → Ready → Delivered, illegal jump rejected, assign → staff accepts, staff sees own orders, cancel, history, **receipt PDF**, filters, statistics, payment stats |
| 9 | Expenses | Categories, bulk expenses, list, statistics |
| 10 | Reports etc. | 5 reports, notifications + read-all, settings |

At the end it prints:
- **RESULT:** passed / failed, with the exact error for every failure
- **Slowest API calls:** average and maximum time per endpoint
- **The test owner's email and password** (and a staff login), so you can log in on the phone and see all the data

The same report, plus the logins, is saved to `scripts/e2e-seed/output/run-<id>.json`. That folder is git-ignored because it contains passwords.

Exit code is `0` when everything passed and `1` otherwise, so it can run in CI.

## Cleaning up

Test tenants are normal tenants named `E2E Test Laundry …` with `@example.com` emails.
Suspend them from the Company Admin panel, or ask to have them deleted from the database.
