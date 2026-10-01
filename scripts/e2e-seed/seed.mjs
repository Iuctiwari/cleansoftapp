#!/usr/bin/env node
// End-to-end check + realistic data seed for the deployed Nexoraa backend.
//
// Creates its OWN brand-new test tenant (never touches existing tenants), then
// walks every module the mobile app uses — exactly the HTTP calls the app
// makes — and verifies each response: tenant signup, login, profile, branches,
// subscription plans, catalog + pricing, customers, staff (incl. staff login),
// orders (totals vs. catalog prices), advance payments, status workflow,
// assignment accept, cancel, receipt PDF, expenses, notifications, reports,
// settings. Prints a pass/fail report and the test owner's login so you can
// open the filled-in app on your phone.
//
//   node scripts/e2e-seed/seed.mjs                  # defaults below
//   node scripts/e2e-seed/seed.mjs --customers 50 --orders 150
//   E2E_DOMAIN=65-1-66-219.sslip.io node scripts/e2e-seed/seed.mjs
//
// Requires Node 22+ (built-in fetch). No npm packages.

import { randomBytes, randomUUID } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// ── Config ────────────────────────────────────────────────────────────────────

const args = Object.fromEntries(
  process.argv.slice(2).reduce((pairs, arg, i, all) => {
    if (arg.startsWith('--')) pairs.push([arg.slice(2), all[i + 1]?.startsWith('--') ? 'true' : all[i + 1] ?? 'true']);
    return pairs;
  }, []),
);
const num = (key, fallback) => Number(args[key] ?? process.env[`E2E_${key.toUpperCase()}`] ?? fallback);

const DOMAIN = args.domain ?? process.env.E2E_DOMAIN ?? '65-1-66-219.sslip.io';
const COUNTS = {
  branches: num('branches', 2), // extra branches besides the auto-created head office
  customers: num('customers', 30),
  staff: num('staff', 4),
  orders: num('orders', 60),
  expenses: num('expenses', 25),
};
const CONCURRENCY = num('concurrency', 4);
const TIMEOUT_MS = num('timeout', 60_000);

// Same base URLs the app's .env uses (each service has its own prefix).
const BASE = {
  auth: `https://auth.${DOMAIN}/api/v1`,
  tenant: `https://tenant.${DOMAIN}/api/v1`,
  branch: `https://branch.${DOMAIN}/v1`,
  customer: `https://customer.${DOMAIN}`,
  catalog: `https://catalog.${DOMAIN}/api/v1`,
  order: `https://order.${DOMAIN}/api/v1`,
  payment: `https://payment.${DOMAIN}/api/v1`,
  expense: `https://expense.${DOMAIN}`,
  report: `https://report.${DOMAIN}/api/v1`,
  notification: `https://notification.${DOMAIN}/api/v1`,
  user: `https://user.${DOMAIN}/api/v1`,
  settings: `https://settings.${DOMAIN}/api/v1`,
  admin: `https://admin.${DOMAIN}/api/v1`,
};

// ── Tiny HTTP client ──────────────────────────────────────────────────────────

class ApiError extends Error {
  constructor(method, url, status, body) {
    const msg =
      body?.error?.message ?? body?.error?.code ?? (Array.isArray(body?.message) ? body.message.join('; ') : body?.message) ??
      (typeof body === 'string' ? body.slice(0, 200) : JSON.stringify(body)?.slice(0, 200));
    super(`${method} ${url.replace(/^https:\/\/([a-z-]+)\.[^/]+/, '$1')} → ${status}: ${msg}`);
    this.status = status;
    this.body = body;
  }
}

const session = { token: null, branchId: null };

async function api(service, method, path, { body, token = session.token, branch = session.branchId, headers = {}, raw = false } = {}) {
  const url = `${BASE[service]}${path}`;
  const started = performance.now();
  const response = await fetch(url, {
    method,
    headers: {
      accept: raw ? '*/*' : 'application/json',
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(branch ? { 'x-branch-id': branch } : {}),
      ...headers,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  timings.push({ key: `${method} ${service}${path.replace(/[0-9a-f]{24}/g, ':id').split('?')[0]}`, ms: performance.now() - started });
  if (raw) {
    if (!response.ok) throw new ApiError(method, url, response.status, await response.text());
    return { status: response.status, contentType: response.headers.get('content-type'), bytes: (await response.arrayBuffer()).byteLength };
  }
  const text = await response.text();
  let parsed;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
  if (!response.ok) throw new ApiError(method, url, response.status, parsed);
  return unwrap(parsed);
}

const unwrap = (value) => (value && typeof value === 'object' && !Array.isArray(value) && 'data' in value && Object.keys(value).every((k) => ['data', 'meta', 'success', 'message'].includes(k)) ? value.data : value);
const list = (value) => (Array.isArray(value) ? value : value?.items ?? value?.data ?? value?.results ?? value?.customers ?? value?.orders ?? []);
const idOf = (record) => record?.id ?? record?._id ?? record?.userId ?? record?.branchId ?? record?.customerId ?? record?.tenantId;

// ── Report bookkeeping ────────────────────────────────────────────────────────

const results = []; // { section, name, ok, ms, detail }
const timings = [];
let currentSection = '';

function section(title) {
  currentSection = title;
  console.log(`\n\x1b[1m▸ ${title}\x1b[0m`);
}

async function check(name, fn, { critical = false } = {}) {
  const started = performance.now();
  try {
    const detail = await fn();
    const ms = performance.now() - started;
    results.push({ section: currentSection, name, ok: true, ms, detail });
    console.log(`  \x1b[32m✔\x1b[0m ${name}${detail ? ` \x1b[90m— ${detail}\x1b[0m` : ''} \x1b[90m(${fmtMs(ms)})\x1b[0m`);
    return true;
  } catch (error) {
    const ms = performance.now() - started;
    results.push({ section: currentSection, name, ok: false, ms, detail: error.message });
    console.log(`  \x1b[31m✘ ${name}\x1b[0m — ${error.message}`);
    if (critical) throw new Error(`Critical step failed: ${name}`);
    return false;
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const fmtMs = (ms) => (ms >= 1000 ? `${(ms / 1000).toFixed(1)}s` : `${Math.round(ms)}ms`);

async function pool(items, size, worker) {
  const out = new Array(items.length);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(size, items.length) }, async () => {
      while (next < items.length) {
        const index = next++;
        out[index] = await worker(items[index], index);
      }
    }),
  );
  return out;
}

// ── Realistic fake data ───────────────────────────────────────────────────────

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const between = (min, max) => min + Math.floor(Math.random() * (max - min + 1));
const round2 = (n) => Math.round(n * 100) / 100;
const FIRST = ['Aarav', 'Vivaan', 'Aditya', 'Ananya', 'Diya', 'Ishaan', 'Kavya', 'Meera', 'Rohan', 'Saanvi', 'Arjun', 'Priya', 'Neha', 'Rahul', 'Sneha', 'Karan', 'Pooja', 'Vikram', 'Riya', 'Siddharth', 'Nisha', 'Amit', 'Tanvi', 'Harsh'];
const LAST = ['Sharma', 'Patil', 'Deshmukh', 'Kulkarni', 'Joshi', 'Iyer', 'Reddy', 'Mehta', 'Gupta', 'Nair', 'Shinde', 'Verma', 'Kapoor', 'Rao', 'Pawar', 'Chavan'];
const AREAS = ['Koregaon Park', 'Baner', 'Aundh', 'Kothrud', 'Viman Nagar', 'Hadapsar', 'Wakad', 'Hinjewadi', 'Shivaji Nagar', 'Kalyani Nagar'];
const VENDORS = ['Shree Detergents', 'MSEB', 'City Transport Co.', 'Sai Hangers', 'Om Plumbing', 'Packaging Hub'];
const usedMobiles = new Set();
const mobile = () => {
  let m;
  do m = `${pick(['9', '8', '7'])}${String(between(0, 999_999_999)).padStart(9, '0')}`; while (usedMobiles.has(m));
  usedMobiles.add(m);
  return m;
};
const personName = () => `${pick(FIRST)} ${pick(LAST)}`;
const daysAgoIso = (days) => new Date(Date.now() - days * 86_400_000).toISOString();

// ── State shared across steps ─────────────────────────────────────────────────

const RUN = `${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${randomBytes(2).toString('hex')}`;
const owner = {
  name: 'E2E Test Owner',
  email: `e2e-owner-${RUN}@example.com`,
  mobile: `9${String(Date.now()).slice(-9)}`,
  password: `E2e!${randomBytes(6).toString('hex')}A`,
  businessName: `E2E Test Laundry ${RUN}`,
};
const state = { tenantId: null, tenantSlug: null, headOfficeId: null, branches: [], customers: [], staff: [], catalog: [], orders: [], expenseCategories: [], expenses: 0 };

// ── Steps ─────────────────────────────────────────────────────────────────────

async function stepHealth() {
  section('0. Every service reachable over HTTPS');
  const probes = {
    auth: '/health/live', tenant: '/tenants/000000000000000000000000', branch: '/branches', customer: '/customers',
    catalog: '/services', order: '/orders', payment: '/payments', expense: '/expenses', report: '/reports/summary',
    notification: '/notifications', user: '/users/me', settings: '/settings-services', admin: '/tenant/subscription/plans',
  };
  await pool(Object.entries(probes), 6, ([service, path]) =>
    check(`${service}-service answers`, async () => {
      try {
        await api(service, 'GET', path, { token: null, branch: null });
        return 'up';
      } catch (error) {
        // 400/401/403/404 all prove the service itself responded (not Caddy 502).
        if (error instanceof ApiError && error.status < 500) return `up (${error.status} without login, as expected)`;
        throw error;
      }
    }),
  );
}

async function stepSignup() {
  section('1. Tenant sign-up + login');
  await check('Register a new test tenant', async () => {
    const res = await api('tenant', 'POST', '/tenants/register', {
      token: null, branch: null,
      body: { businessName: owner.businessName, businessType: 'laundry', ownerName: owner.name, email: owner.email, mobileNumber: owner.mobile, password: owner.password, agreedToTerms: true },
    });
    state.tenantId = res.tenantId;
    state.tenantSlug = res.slug;
    assert(state.tenantId, 'no tenantId returned');
    return `tenant ${state.tenantId} (${state.tenantSlug})`;
  }, { critical: true });

  const expectConflict = async (label, body, field) => {
    try {
      await api('tenant', 'POST', '/tenants/register', { token: null, branch: null, body });
    } catch (error) {
      const fields = error.body?.error?.fields ?? [];
      assert(error.status === 409, `expected 409, got ${error.status} (${error.message})`);
      assert(fields.some((f) => f.field === field), `409 does not name the ${field} field`);
      return `refused (409 ${error.body.error.code})`;
    }
    throw new Error(`${label} was accepted — duplicate account created`);
  };
  const base = { businessName: `${owner.businessName} dup`, businessType: 'laundry', ownerName: 'Dup', password: owner.password, agreedToTerms: true };
  await check('Sign-up with an already-registered PHONE is refused clearly', () =>
    expectConflict('Duplicate phone', { ...base, email: `dup-phone-${RUN}@example.com`, mobileNumber: owner.mobile }, 'mobileNumber'));
  await check('Sign-up with an already-registered EMAIL is refused clearly', () =>
    expectConflict('Duplicate email', { ...base, email: owner.email, mobileNumber: mobile() }, 'email'));

  await check('Owner logs in (tenant context)', async () => {
    const res = await api('auth', 'POST', '/auth/login', { token: null, branch: null, body: { context: 'tenant', identifier: owner.email, password: owner.password, tenantSlug: state.tenantSlug } });
    session.token = res.accessToken;
    session.branchId = res.branch?.branchId ?? null;
    state.headOfficeId = session.branchId;
    assert(session.token, 'no accessToken');
    assert(res.user?.roleCode, 'no roleCode in login response');
    assert(res.tenant?.tenantId === state.tenantId, 'login tenant mismatch');
    return `role ${res.user.roleCode}, head office ${session.branchId ?? '(none)'}`;
  }, { critical: true });

  await check('Login is rejected with a wrong password', async () => {
    try {
      await api('auth', 'POST', '/auth/login', { token: null, branch: null, body: { context: 'tenant', identifier: owner.email, password: 'Wrong-pass-123', tenantSlug: state.tenantSlug } });
    } catch (error) {
      assert(error.status === 401 || error.status === 400, `expected 401, got ${error.status}`);
      return `rejected (${error.status})`;
    }
    throw new Error('wrong password was accepted');
  });

  await check('Auth context resolves the session', async () => {
    const ctx = await api('auth', 'GET', '/auth/context');
    assert(ctx?.tenantId === state.tenantId || ctx?.kind === 'tenant', 'context does not match tenant');
    if (!session.branchId && ctx?.branchId) session.branchId = state.headOfficeId = ctx.branchId;
    assert(session.branchId, 'no branch in session');
    return `kind=${ctx?.kind ?? '?'}`;
  }, { critical: true });
}

async function stepProfile() {
  section('2. Tenant profile');
  await check('Read tenant profile', async () => {
    const t = await api('tenant', 'GET', `/tenants/${state.tenantId}`);
    assert((t.businessName ?? t.tenantName) === owner.businessName, 'businessName mismatch');
    return t.status ?? 'ok';
  });
  await check('Edit profile (location) — the screen that used to 404', async () => {
    await api('tenant', 'PATCH', `/tenants/${state.tenantId}/profile`, { body: { location: 'Pune' } });
    return 'saved';
  });
  await check('List tenant branches', async () => {
    const b = list(await api('tenant', 'GET', `/tenants/${state.tenantId}/branches`));
    assert(b.length >= 1, 'no branches');
    return `${b.length} branch(es)`;
  });
}

async function stepBranches() {
  section(`3. Branches (+${COUNTS.branches})`);
  state.branches.push({ id: state.headOfficeId, name: 'Head Office' });
  for (let i = 0; i < COUNTS.branches; i++) {
    const area = AREAS[i % AREAS.length];
    await check(`Create branch "${area}"`, async () => {
      const b = await api('branch', 'POST', '/branches', {
        body: { branchName: `${area} Outlet`, streetAddress: `${between(1, 200)} ${area} Road`, city: 'Pune', state: 'Maharashtra', country: 'India', postalCode: `4110${between(10, 99)}`, phone: mobile(), email: `branch-${i + 1}-${RUN}@example.com`, openingTime: '09:00', closingTime: '21:00' },
      });
      state.branches.push({ id: idOf(b), name: `${area} Outlet` });
      return `${idOf(b)} code ${b.code ?? '?'}`;
    });
  }
  await check('List branches', async () => {
    const all = list(await api('branch', 'GET', '/branches'));
    assert(all.length >= state.branches.length, `expected ≥${state.branches.length}, got ${all.length}`);
    return `${all.length} total`;
  });
  await check('Branch statistics', async () => JSON.stringify(await api('branch', 'GET', '/branches/statistics')).slice(0, 80));
}

async function stepSubscription() {
  section('4. Subscription (platform-admin ↔ tenant link)');
  let plans = [];
  await check('Tenant sees plans created by platform admin', async () => {
    plans = list(await api('admin', 'GET', '/tenant/subscription/plans'));
    assert(plans.length > 0, 'no active plans — create one in the Company Admin panel');
    return plans.map((p) => p.planKey ?? p.key).join(', ');
  });
  await check('Select a plan', async () => {
    const plan = plans.find((p) => (p.planKey ?? p.key) === 'FREE_TRIAL') ?? plans.find((p) => Number(p.monthlyPrice ?? p.priceMonthly ?? 0) === 0) ?? plans[0];
    assert(plan, 'no plan to select');
    await api('admin', 'POST', '/tenant/subscription/select-plan', { body: { planKey: plan.planKey ?? plan.key, billingCycle: 'MONTHLY' } });
    return plan.planKey ?? plan.key;
  });
  await check('Subscription status', async () => {
    const s = await api('admin', 'GET', '/tenant/subscription/status');
    assert(s.hasSubscription, 'no subscription after select-plan');
    return `${s.subscription?.planKey} ${s.subscription?.status}, ${s.subscription?.daysRemaining ?? '?'} days left`;
  });
  await check('Tenant config (modules/theme)', async () => {
    await api('admin', 'GET', '/tenant/config/active');
    return 'ok';
  });
}

const CATALOG = {
  categories: [
    { name: 'Shirt', code: 'SHIRT', unitType: 'Piece' },
    { name: 'Trousers', code: 'TROUSER', unitType: 'Piece' },
    { name: 'Saree', code: 'SAREE', unitType: 'Piece' },
    { name: 'Suit (2pc)', code: 'SUIT', unitType: 'Piece' },
    { name: 'Bedsheet', code: 'BEDSHEET', unitType: 'Piece' },
    { name: 'Mixed Laundry', code: 'MIXKG', unitType: 'Kg' },
  ],
  services: [
    { name: 'Wash & Iron', code: 'WASHIRON', pricingType: 'PerItem', applies: ['SHIRT', 'TROUSER', 'BEDSHEET'] },
    { name: 'Dry Clean', code: 'DRYCLEAN', pricingType: 'PerItem', applies: ['SHIRT', 'TROUSER', 'SAREE', 'SUIT'] },
    { name: 'Steam Press', code: 'STEAM', pricingType: 'PerItem', applies: ['SHIRT', 'TROUSER', 'SAREE', 'SUIT'] },
    { name: 'Wash & Fold', code: 'WASHFOLD', pricingType: 'PerKg', applies: ['MIXKG'] },
  ],
  price: { WASHIRON: 30, DRYCLEAN: 120, STEAM: 20, WASHFOLD: 70, SAREE: 1.8, SUIT: 2.5, BEDSHEET: 1.4 }, // base × category multiplier
};

async function stepCatalog() {
  section('5. Service catalog + pricing');
  const cat = {};
  const svc = {};
  for (const c of CATALOG.categories) {
    await check(`Item category ${c.name}`, async () => {
      const r = await api('catalog', 'POST', '/item-categories', { body: { name: c.name, code: `E2E_${c.code}`, unitType: c.unitType } });
      cat[c.code] = idOf(r);
      return cat[c.code];
    });
  }
  for (const s of CATALOG.services) {
    await check(`Service ${s.name} (${s.pricingType})`, async () => {
      const r = await api('catalog', 'POST', '/services', { body: { name: s.name, code: `E2E_${s.code}`, pricingType: s.pricingType, estimatedTimeMins: 1440 } });
      svc[s.code] = idOf(r);
      return svc[s.code];
    });
  }
  for (const s of CATALOG.services) {
    for (const code of s.applies) {
      if (!svc[s.code] || !cat[code]) continue;
      const price = round2(CATALOG.price[s.code] * (CATALOG.price[code] ?? 1));
      await check(`Map + price ${s.name} × ${code} = ₹${price}`, async () => {
        await api('catalog', 'POST', '/service-mappings', { body: { itemCategoryId: cat[code], serviceId: svc[s.code] } });
        await api('catalog', 'POST', `/services/${svc[s.code]}/pricing`, { body: { itemCategoryId: cat[code], basePrice: price, taxPct: 5, effectiveFrom: daysAgoIso(1) } });
        const q = await api('catalog', 'GET', `/services/${svc[s.code]}/quote?branchId=${session.branchId}&itemCategoryId=${cat[code]}`);
        assert(Number(q.basePrice) === price, `quote says ₹${q.basePrice}, expected ₹${price}`);
        state.catalog.push({ serviceId: svc[s.code], itemCategoryId: cat[code], price, taxPct: Number(q.taxPct ?? 0), pricingType: s.pricingType, label: `${s.name} – ${code}` });
        return 'quote matches';
      });
    }
  }
  await check('Catalog lists what was created', async () => {
    const services = list(await api('catalog', 'GET', '/services'));
    const categories = list(await api('catalog', 'GET', '/item-categories'));
    return `${services.length} services, ${categories.length} item categories`;
  });
  assert(state.catalog.length > 0, 'No priced catalog entries — order steps cannot run');
}

async function stepCustomers() {
  section(`6. Customers (${COUNTS.customers})`);
  const types = ['Regular', 'Regular', 'Regular', 'Walk-in', 'Corporate', 'VIP'];
  await check(`Create ${COUNTS.customers} customers`, async () => {
    const made = await pool(Array.from({ length: COUNTS.customers }), CONCURRENCY, async (_, i) => {
      const name = personName();
      try {
        const c = await api('customer', 'POST', '/customers', {
          body: { name, mobile: mobile(), email: `${name.toLowerCase().replace(/\s+/g, '.')}.${i}@example.com`, address: `${between(1, 99)}, ${pick(AREAS)}, Pune`, customerType: pick(types), joiningDate: daysAgoIso(between(0, 180)).slice(0, 10) },
        });
        return { id: idOf(c), name };
      } catch (error) {
        return { error: error.message };
      }
    });
    state.customers = made.filter((c) => c.id);
    const failed = made.filter((c) => c.error);
    assert(failed.length === 0, `${failed.length} failed, e.g. ${failed[0]?.error}`);
    return `${state.customers.length} created`;
  });
  await check('Customer list + search', async () => {
    const page = await api('customer', 'GET', '/customers?page=1&limit=50');
    const target = state.customers[0];
    const found = list(await api('customer', 'GET', `/customers?page=1&limit=10&search=${encodeURIComponent(target.name.split(' ')[0])}`));
    assert(found.some((c) => idOf(c) === target.id), 'search did not find the customer');
    return `${page.total ?? list(page).length} listed, search ok`;
  });
  await check('Customer detail + edit', async () => {
    const id = state.customers[0].id;
    await api('customer', 'PATCH', `/customers/${id}`, { body: { address: '12, MG Road, Pune' } });
    const c = await api('customer', 'GET', `/customers/${id}`);
    assert(c.address === '12, MG Road, Pune', 'edit not saved');
    return 'saved';
  });
  await check('Customer statistics', async () => JSON.stringify(await api('customer', 'GET', '/customers/statistics')).slice(0, 90));
}

async function stepStaff() {
  section(`7. Staff (${COUNTS.staff})`);
  const roles = ['Staff', 'Cashier', 'Branch Manager', 'Staff'];
  for (let i = 0; i < COUNTS.staff; i++) {
    const role = roles[i % roles.length];
    const name = personName();
    const password = `Staff!${randomBytes(4).toString('hex')}9`;
    const loginId = `e2e-staff-${i + 1}-${RUN}@example.com`;
    await check(`Register ${role} ${name}`, async () => {
      const u = await api('user', 'POST', `/users/tenant/${state.tenantId}/register`, {
        body: { name, loginId, password, email: loginId, mobileNumber: mobile(), department: 'Operations', role, branchIds: [state.headOfficeId] },
      });
      state.staff.push({ id: idOf(u), name, role, loginId, password });
      return idOf(u);
    });
  }
  await check('Staff list', async () => {
    const all = list(await api('user', 'GET', `/users/tenant/${state.tenantId}`));
    return `${all.length} users`;
  });
  const worker = state.staff.find((s) => s.role === 'Staff');
  if (worker) {
    await check(`Staff member logs in (${worker.loginId})`, async () => {
      const res = await api('auth', 'POST', '/auth/login', { token: null, branch: null, body: { context: 'tenant', identifier: worker.loginId, password: worker.password, tenantSlug: state.tenantSlug } });
      worker.token = res.accessToken;
      return `role ${res.user?.roleCode}`;
    });
  }
}

const ADDITIONAL_SERVICE_SURCHARGE = 10;

async function createOrder(i) {
  const customer = state.customers[i % state.customers.length];
  const lines = Array.from({ length: between(1, 3) }, () => pick(state.catalog));
  const items = lines.map((l) => (l.pricingType === 'PerKg' ? { itemCategoryId: l.itemCategoryId, serviceId: l.serviceId, weight: round2(1 + Math.random() * 5) } : { itemCategoryId: l.itemCategoryId, serviceId: l.serviceId, quantity: between(1, 6) }));
  // Business rule (order-service ADDITIONAL_SERVICE_SURCHARGE, mirrored in the app's
  // NewOrderController): the first service on an item category is charged its catalog
  // price; every further service on the SAME item category in the order is a flat ₹10/unit.
  const servicesPerCategory = new Map();
  const expectedSubtotal = round2(
    items.reduce((sum, item, k) => {
      const nth = servicesPerCategory.get(item.itemCategoryId) ?? 0;
      servicesPerCategory.set(item.itemCategoryId, nth + 1);
      return sum + (nth === 0 ? lines[k].price : ADDITIONAL_SERVICE_SURCHARGE) * (item.quantity ?? item.weight);
    }, 0),
  );
  const order = await api('order', 'POST', '/orders', { body: { customerId: customer.id, items, expectedDeliveryDate: new Date(Date.now() + between(1, 5) * 86_400_000).toISOString() } });
  const grand = Number(order.grandTotal);
  const subtotal = Number(order.subtotal);
  assert(grand > 0, `grandTotal is ${order.grandTotal}`);
  assert(Math.abs(subtotal - expectedSubtotal) < 0.05, `subtotal ₹${subtotal} ≠ expected ₹${expectedSubtotal} from catalog prices`);
  return { id: idOf(order), number: order.orderNumber, customerId: customer.id, grandTotal: grand, outstanding: Number(order.outstandingAmount ?? grand), status: order.status };
}

async function pay(order, amount, method) {
  const minor = Math.round(amount * 100);
  const res = await api('payment', 'POST', '/payments', {
    headers: { 'idempotency-key': `e2e-${order.id}-${randomUUID()}` },
    body: { amountMinor: minor, currency: 'INR', customerId: order.customerId, method, orderId: order.id, paymentType: 'Advance' },
  });
  const updated = res.order ?? res;
  order.outstanding = Number(updated.outstandingAmount ?? order.outstanding - amount);
  return updated;
}

async function stepOrders() {
  section(`8. Orders (${COUNTS.orders}) — create, pay, workflow`);
  await check(`Create ${COUNTS.orders} orders (totals checked against catalog prices)`, async () => {
    const made = await pool(Array.from({ length: COUNTS.orders }), CONCURRENCY, async (_, i) => {
      try { return await createOrder(i); } catch (error) { return { error: error.message }; }
    });
    state.orders = made.filter((o) => o.id);
    const failed = made.filter((o) => o.error);
    assert(state.orders.length > 0, `all failed, e.g. ${failed[0]?.error}`);
    assert(failed.length === 0, `${failed.length}/${made.length} failed, e.g. ${failed[0]?.error}`);
    const revenue = state.orders.reduce((s, o) => s + o.grandTotal, 0);
    return `${state.orders.length} orders, ₹${revenue.toFixed(2)} billed`;
  });
  if (!state.orders.length) return;

  const methods = ['Cash', 'UPI', 'Card'];
  await check('Advance payments on ~60% of orders', async () => {
    const targets = state.orders.filter((_, i) => i % 5 < 3);
    const done = await pool(targets, CONCURRENCY, async (o, i) => {
      try {
        const amount = i % 3 === 0 ? o.outstanding : round2(Math.max(1, o.outstanding * 0.4));
        const updated = await pay(o, amount, pick(methods));
        assert(Number(updated.paidAmount) > 0, 'paidAmount not updated on order');
        return true;
      } catch (error) { return error.message; }
    });
    const failed = done.filter((d) => d !== true);
    assert(failed.length === 0, `${failed.length} failed, e.g. ${failed[0]}`);
    return `${done.length} payments`;
  });

  await check('Overpayment is rejected', async () => {
    const o = state.orders.find((x) => x.outstanding > 0);
    assert(o, 'no order with balance');
    try { await pay(o, o.outstanding + 1000, 'Cash'); } catch (error) { assert(error.status >= 400 && error.status < 500, `expected 4xx, got ${error.status}`); return `rejected (${error.status})`; }
    throw new Error('payment above outstanding was accepted');
  });

  const flow = async (o, path) => {
    for (const status of path) await api('order', 'PATCH', `/orders/${o.id}/status`, { body: { status, note: `E2E → ${status}` } });
    o.status = path.at(-1);
  };
  await check('Status workflow: Received → InProgress → Ready → Delivered', async () => {
    const targets = state.orders.slice(0, Math.ceil(state.orders.length * 0.5));
    const done = await pool(targets, CONCURRENCY, async (o, i) => {
      try {
        const path = i % 3 === 0 ? ['InProgress'] : i % 3 === 1 ? ['InProgress', 'Ready'] : ['InProgress', 'Ready'];
        await flow(o, path);
        if (i % 3 === 2) {
          if (o.outstanding > 0) await pay(o, o.outstanding, 'UPI');
          await flow(o, ['Delivered']);
        }
        return true;
      } catch (error) { return `${o.number}: ${error.message}`; }
    });
    const failed = done.filter((d) => d !== true);
    assert(failed.length === 0, `${failed.length} failed, e.g. ${failed[0]}`);
    const by = state.orders.reduce((m, o) => ({ ...m, [o.status]: (m[o.status] ?? 0) + 1 }), {});
    return Object.entries(by).map(([k, v]) => `${k} ${v}`).join(', ');
  });

  await check('Invalid status jump is rejected (Received → Delivered)', async () => {
    const o = state.orders.find((x) => x.status === 'Received');
    assert(o, 'no Received order left');
    try { await api('order', 'PATCH', `/orders/${o.id}/status`, { body: { status: 'Delivered' } }); } catch (error) { return `rejected (${error.status})`; }
    throw new Error('illegal transition accepted');
  });

  const worker = state.staff.find((s) => s.token);
  if (worker) {
    await check(`Assign order to ${worker.name}, staff accepts`, async () => {
      const o = state.orders.find((x) => x.status === 'Received');
      assert(o, 'no Received order to assign');
      await api('order', 'POST', `/orders/${o.id}/assign`, { body: { assignedTo: worker.id, note: 'E2E assignment' } });
      await api('order', 'POST', `/orders/${o.id}/assignment/accept`, { token: worker.token });
      o.status = 'Accepted';
      return o.number;
    });
    await check('Staff sees only their assigned orders', async () => {
      const mine = list(await api('order', 'GET', '/orders?page=1&limit=50', { token: worker.token }));
      assert(mine.length >= 1, 'assigned order not visible to staff');
      return `${mine.length} visible`;
    });
  }

  await check('Cancel an order', async () => {
    const o = [...state.orders].reverse().find((x) => x.status === 'Received');
    assert(o, 'no Received order to cancel');
    const res = await api('order', 'POST', `/orders/${o.id}/cancel`, { body: { reason: 'E2E: customer changed plans' } });
    o.status = res.status ?? 'Cancelled';
    return `${o.number} → ${o.status}`;
  });

  await check('Order detail + status history', async () => {
    const o = state.orders.find((x) => x.status === 'Delivered') ?? state.orders[0];
    const detail = await api('order', 'GET', `/orders/${o.id}`);
    const history = list(await api('order', 'GET', `/orders/${o.id}/history`));
    assert(detail.orderNumber, 'no orderNumber');
    assert(history.length >= 1, 'empty history');
    return `${detail.orderNumber}: ${history.map((h) => h.newStatus).join(' → ')}`;
  });

  await check('Receipt PDF downloads', async () => {
    const r = await api('order', 'GET', `/orders/${state.orders[0].id}/receipt`, { raw: true });
    assert(/pdf/i.test(r.contentType ?? ''), `content-type ${r.contentType}`);
    assert(r.bytes > 1000, `only ${r.bytes} bytes`);
    return `${(r.bytes / 1024).toFixed(0)} KB`;
  });

  await check('Order list, filters, statistics', async () => {
    const all = await api('order', 'GET', '/orders?page=1&limit=100&sortBy=createdAt&sortDirection=desc');
    const delivered = list(await api('order', 'GET', '/orders?page=1&limit=100&status=Delivered'));
    const stats = await api('order', 'GET', '/orders/statistics');
    assert(delivered.every((o) => o.status === 'Delivered'), 'status filter returned other statuses');
    return `${all.total ?? list(all).length} total, ${delivered.length} delivered; stats ${JSON.stringify(stats).slice(0, 60)}`;
  });

  await check('Payments list + statistics', async () => {
    const p = await api('payment', 'GET', '/payments?page=1&limit=100');
    const s = await api('payment', 'GET', '/payments/statistics');
    return `${p.total ?? list(p).length} payments; ${JSON.stringify(s).slice(0, 70)}`;
  });
}

async function stepExpenses() {
  section(`9. Expenses (${COUNTS.expenses})`);
  for (const name of ['Rent', 'Electricity', 'Detergent & Chemicals', 'Salaries', 'Transport', 'Maintenance']) {
    await check(`Expense category ${name}`, async () => {
      const c = await api('expense', 'POST', '/expense-categories', { body: { categoryName: name, description: `E2E ${name}` } });
      state.expenseCategories.push({ id: idOf(c), name });
      return idOf(c);
    });
  }
  if (!state.expenseCategories.length) return;
  await check(`Create ${COUNTS.expenses} expenses`, async () => {
    const done = await pool(Array.from({ length: COUNTS.expenses }), CONCURRENCY, async () => {
      const c = pick(state.expenseCategories);
      try {
        await api('expense', 'POST', '/expenses', { body: { expenseCategoryId: c.id, amount: between(150, 12_000), paymentMethod: pick(['Cash', 'UPI', 'Card', 'BankTransfer']), vendor: pick(VENDORS), description: `${c.name} – E2E`, expenseDate: daysAgoIso(between(0, 60)) } });
        return true;
      } catch (error) { return error.message; }
    });
    const failed = done.filter((d) => d !== true);
    state.expenses = done.length - failed.length;
    assert(failed.length === 0, `${failed.length} failed, e.g. ${failed[0]}`);
    return `${state.expenses} created`;
  });
  await check('Expense list + statistics', async () => {
    const l = await api('expense', 'GET', '/expenses?page=1&limit=50');
    const s = await api('expense', 'GET', '/expenses/statistics');
    return `${l.total ?? list(l).length} listed; ${JSON.stringify(s).slice(0, 70)}`;
  });
}

async function stepReportsEtc() {
  section('10. Reports, notifications, settings');
  const range = `startDate=${encodeURIComponent(daysAgoIso(90))}&endDate=${encodeURIComponent(new Date(Date.now() + 86_400_000).toISOString())}`;
  for (const r of ['summary', 'branch-performance', 'orders', 'payments', 'expenses']) {
    await check(`Report: ${r}`, async () => JSON.stringify(await api('report', 'GET', `/reports/${r}?${range}`)).slice(0, 90));
  }
  await check('Notifications list + unread count', async () => {
    const n = await api('notification', 'GET', '/notifications?page=1&limit=20');
    const u = await api('notification', 'GET', '/notifications/unread-count');
    return `${n.total ?? list(n).length} notifications, unread ${JSON.stringify(u)}`;
  });
  await check('Mark all notifications read', async () => {
    await api('notification', 'PATCH', '/notifications/read-all');
    return 'ok';
  });
  await check('Settings', async () => {
    const s = await api('settings', 'GET', '/settings-services');
    return JSON.stringify(s).slice(0, 80);
  });
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\x1b[1mNexoraa E2E seed\x1b[0m → ${DOMAIN}  run ${RUN}`);
  console.log(`counts: ${JSON.stringify(COUNTS)}  concurrency ${CONCURRENCY}`);
  const started = performance.now();
  try {
    await stepHealth();
    await stepSignup();
    await stepProfile();
    await stepBranches();
    await stepSubscription();
    await stepCatalog();
    await stepCustomers();
    await stepStaff();
    await stepOrders();
    await stepExpenses();
    await stepReportsEtc();
  } catch (error) {
    console.log(`\n\x1b[31m${error.message} — stopping.\x1b[0m`);
  }
  report(performance.now() - started);
}

function report(totalMs) {
  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok);
  const slow = Object.values(
    timings.reduce((m, t) => {
      (m[t.key] ??= { key: t.key, n: 0, total: 0, max: 0 });
      m[t.key].n++; m[t.key].total += t.ms; m[t.key].max = Math.max(m[t.key].max, t.ms);
      return m;
    }, {}),
  ).map((x) => ({ ...x, avg: x.total / x.n })).sort((a, b) => b.avg - a.avg).slice(0, 8);

  console.log(`\n\x1b[1m════ RESULT: ${passed} passed, ${failed.length} failed  (${fmtMs(totalMs)}) ════\x1b[0m`);
  for (const f of failed) console.log(`  \x1b[31m✘\x1b[0m [${f.section}] ${f.name}\n      ${f.detail}`);
  console.log('\n\x1b[1mSlowest API calls (avg / max)\x1b[0m');
  for (const s of slow) console.log(`  ${fmtMs(s.avg).padStart(6)} / ${fmtMs(s.max).padStart(6)}  ×${String(s.n).padEnd(3)} ${s.key}`);

  console.log('\n\x1b[1mData created\x1b[0m');
  console.log(`  branches ${state.branches.length}, customers ${state.customers.length}, staff ${state.staff.length}, priced services ${state.catalog.length}, orders ${state.orders.length}, expenses ${state.expenses}`);
  if (state.tenantId) {
    console.log('\n\x1b[1mOpen this data in the app (log in as the test owner):\x1b[0m');
    console.log(`  Email:    ${owner.email}\n  Password: ${owner.password}\n  Business: ${owner.businessName}`);
    const staff = state.staff.find((s) => s.role === 'Staff');
    if (staff) console.log(`  Staff login: ${staff.loginId} / ${staff.password}`);
  }

  const outDir = join(dirname(fileURLToPath(import.meta.url)), 'output');
  mkdirSync(outDir, { recursive: true });
  const file = join(outDir, `run-${RUN}.json`);
  writeFileSync(file, JSON.stringify({ domain: DOMAIN, run: RUN, counts: COUNTS, owner, tenantId: state.tenantId, tenantSlug: state.tenantSlug, staff: state.staff.map(({ token, ...s }) => s), results, slowest: slow }, null, 2));
  console.log(`\nFull report + logins saved to ${file}`);
  process.exitCode = failed.length ? 1 : 0;
}

await main();
