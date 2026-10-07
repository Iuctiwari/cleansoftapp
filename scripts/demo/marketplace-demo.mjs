#!/usr/bin/env node
// Demo data + end-to-end tests for the customer marketplace, online requests
// and Worker Tasks — against the LIVE server, through the same APIs the app uses.
//
//   node scripts/demo/marketplace-demo.mjs seed        fill demo shops, staff, customers, requests, orders
//   node scripts/demo/marketplace-demo.mjs e2e         end-to-end tests of every new feature
//   node scripts/demo/marketplace-demo.mjs cleanup     list what would be deleted
//   node scripts/demo/marketplace-demo.mjs cleanup --yes   delete ALL demo data
//
// Every demo account uses an email like ayushikrishna1199+demo-…@gmail.com and
// every demo name ends with "(Demo)". Cleanup only matches that pattern.
// Needs Node 20+ and the AWS CLI signed in (for the two server-side steps:
// verifying demo customers' emails and cleanup), e.g. the Terraform admin user.
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const DOMAIN = process.env.DEMO_DOMAIN ?? '65-1-66-219.sslip.io';
const INSTANCE = process.env.DEMO_INSTANCE ?? 'i-01a4e8536097607c8';
const REGION = 'ap-south-1';
const PASSWORD = 'Demo@2026';
const EMAIL_PATTERN = process.env.DEMO_EMAIL_PATTERN ?? '^ayushikrishna1199\\+demo-';
const email = (key) => `ayushikrishna1199+demo-${key}@gmail.com`;

const API = {
  auth: `https://auth.${DOMAIN}/api/v1`,
  tenant: `https://tenant.${DOMAIN}/api/v1`,
  market: `https://market.${DOMAIN}/api/v1`,
  customers: `https://customer.${DOMAIN}`,
  orders: `https://order.${DOMAIN}/api/v1`,
  catalog: `https://catalog.${DOMAIN}/api/v1`,
  users: `https://user.${DOMAIN}/api/v1`,
};

// ── Demo data (Andheri, Mumbai) ─────────────────────────────────────────────
const week = (open, close, closedDays = []) =>
  [0, 1, 2, 3, 4, 5, 6].map((day) => (closedDays.includes(day) ? { day, closed: true } : { day, closed: false, open, close }));

const SHOPS = [
  {
    key: 'sparkle', name: 'Sparkle Laundry (Demo)', type: 'laundry', services: ['laundry', 'dry_cleaning'], phone: '6100000001',
    branch: 'Lokhandwala', listing: {
      streetAddress: 'Shop 4, Crystal Plaza, Lokhandwala Complex', area: 'Andheri West', landmark: 'Near Lokhandwala Market',
      city: 'Mumbai', state: 'Maharashtra', postalCode: '400053', latitude: 19.1405, longitude: 72.827,
      bookingPhone: '022 2632 1001', serviceModes: ['visit_shop', 'pickup_drop'], serviceRadiusKm: 4,
      openingHours: week('08:00', '21:00'), about: 'Same-day ironing. Free pickup and drop above ₹300.',
    },
    staff: [
      { key: 'ravi', name: 'Ravi Kumar (Demo)' },
      { key: 'sunita', name: 'Sunita Rao (Demo)' },
    ],
  },
  {
    key: 'glamour', name: 'Glamour Salon (Demo)', type: 'salon', services: ['salon'], phone: '6100000002',
    branch: 'Four Bungalows', listing: {
      streetAddress: '12, Silver Arch, JP Road', area: 'Four Bungalows', city: 'Mumbai', state: 'Maharashtra',
      postalCode: '400053', latitude: 19.129, longitude: 72.824, serviceModes: ['visit_shop', 'home_service'],
      serviceRadiusKm: 3, openingHours: week('10:00', '21:00'), about: 'Haircuts, facials and bridal makeup. Home visits available.',
    },
  },
  {
    key: 'quickfix', name: 'QuickFix Repairs (Demo)', type: 'appliance_repair', services: ['appliance_repair', 'mobile_repair'], phone: '6100000003',
    branch: 'Andheri East', listing: {
      streetAddress: 'Unit 7, Sai Industrial Estate', area: 'Andheri East', landmark: 'Opp. Andheri Station (E)',
      city: 'Mumbai', state: 'Maharashtra', postalCode: '400069', latitude: 19.1197, longitude: 72.8468,
      bookingPhone: '98200 11003', serviceModes: ['visit_shop', 'home_service'], serviceRadiusKm: 6,
      openingHours: week('09:30', '20:30', [0]), about: 'Fridge, AC, washing machine and mobile repairs.',
    },
  },
  {
    key: 'stitch', name: 'Perfect Stitch Tailors (Demo)', type: 'tailoring', services: ['tailoring'], phone: '6100000004',
    branch: 'Versova', listing: {
      streetAddress: '3, Yari Road', area: 'Versova', city: 'Mumbai', state: 'Maharashtra', postalCode: '400061',
      latitude: 19.131, longitude: 72.815, serviceModes: ['visit_shop'], serviceRadiusKm: 2,
      openingHours: week('11:00', '20:00', [0]), about: 'Alterations, blouses and suits.',
    },
  },
  {
    key: 'shine', name: 'Shine Car Wash (Demo)', type: 'vehicle_wash', services: ['vehicle_wash'], phone: '6100000005',
    branch: 'MIDC', listing: {
      streetAddress: 'Plot 22, MIDC Central Road', area: 'Andheri East', city: 'Mumbai', state: 'Maharashtra',
      postalCode: '400093', latitude: 19.1176, longitude: 72.8697, serviceModes: ['visit_shop', 'home_service'],
      serviceRadiusKm: 5, openingHours: week('07:00', '19:00'), about: 'Foam wash, interior cleaning, doorstep wash.',
    },
  },
  // Signed up but never added an address: shows the "Add your shop address" prompt.
  { key: 'newshop', name: 'New Shop Pending Address (Demo)', type: 'laundry', services: ['laundry'], phone: '6100000006', branch: 'Main' },
];

const CUSTOMERS = [
  {
    key: 'riya', name: 'Riya Sharma (Demo)', mobile: '6200000001',
    addresses: [
      { label: 'Home', houseFlat: 'Flat 302, Sai Residency', streetArea: 'Lokhandwala, Andheri West', landmark: 'Near Infiniti Mall', city: 'Mumbai', state: 'Maharashtra', pincode: '400053', latitude: 19.1364, longitude: 72.8296 },
      { label: 'Work', houseFlat: '5th floor, Times Square', streetArea: 'Marol, Andheri East', city: 'Mumbai', state: 'Maharashtra', pincode: '400059', latitude: 19.115, longitude: 72.86 },
    ],
  },
  { key: 'amit', name: 'Amit Patel (Demo)', mobile: '6200000002', addresses: [{ label: 'Home', houseFlat: 'B-12, Sea Breeze', streetArea: 'Versova, Andheri West', city: 'Mumbai', state: 'Maharashtra', pincode: '400061', latitude: 19.133, longitude: 72.813 }] },
  { key: 'neha', name: 'Neha Iyer (Demo)', mobile: '6200000003', addresses: [{ label: 'Home', houseFlat: '7A, Green Acres', streetArea: 'Four Bungalows, Andheri West', city: 'Mumbai', state: 'Maharashtra', pincode: '400053', latitude: 19.1265, longitude: 72.8235 }] },
];

// ── Plumbing ────────────────────────────────────────────────────────────────
async function call(method, url, { token, body, branchId } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(branchId ? { 'x-branch-id': branchId } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  const data = json && typeof json === 'object' && 'data' in json && Object.keys(json).every((k) => k === 'data' || k === 'meta') ? json.data : json;
  return { status: response.status, body: json, data };
}
const why = (r) => JSON.stringify(r.body?.error ?? r.body?.message ?? r.body).slice(0, 180);
const ok = (r) => r.status >= 200 && r.status < 300;
const list = (r) => (Array.isArray(r.data) ? r.data : (r.data?.items ?? []));
function must(r, what) {
  if (!ok(r)) throw new Error(`${what} failed: HTTP ${r.status} ${why(r)}`);
  return r.data;
}
const istDate = (days) => new Date(Date.now() + 330 * 60_000 + days * 86_400_000).toISOString().slice(0, 10);
/** Next date (from tomorrow) that is not a Sunday. */
function weekday(from = 1) {
  for (let d = from; ; d++) if (new Date(`${istDate(d)}T00:00:00Z`).getUTCDay() !== 0) return istDate(d);
}

function serverTool(args) {
  const here = dirname(fileURLToPath(import.meta.url));
  const b64 = readFileSync(join(here, 'server-tool.cjs')).toString('base64');
  const script = `cd ~/nexoraa-cleansoft/apps/backend/auth-service && echo ${b64} | base64 -d > .demo-tool.cjs && node .demo-tool.cjs ${args}; rc=$?; rm -f .demo-tool.cjs; exit $rc`;
  const wrapper = `echo ${Buffer.from(script).toString('base64')} | base64 -d > /tmp/demo-tool.sh && sudo -u ubuntu -i bash /tmp/demo-tool.sh; rc=$?; rm -f /tmp/demo-tool.sh; exit $rc`;
  const dir = mkdtempSync(join(tmpdir(), 'demo-'));
  const params = join(dir, 'params.json');
  writeFileSync(params, JSON.stringify({ commands: [wrapper] }));
  const aws = (args2) => execFileSync('aws', ['--region', REGION, ...args2], { encoding: 'utf8', env: { ...process.env, PYTHONIOENCODING: 'utf-8' } }).trim();
  try {
    const id = aws(['ssm', 'send-command', '--instance-ids', INSTANCE, '--document-name', 'AWS-RunShellScript', '--comment', `demo ${args.split(' ')[0]}`, '--parameters', `file://${params}`, '--query', 'Command.CommandId', '--output', 'text']);
    for (let i = 0; i < 60; i++) {
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 2000);
      const status = aws(['ssm', 'get-command-invocation', '--command-id', id, '--instance-id', INSTANCE, '--query', 'Status', '--output', 'text']);
      if (['Success', 'Failed', 'Cancelled', 'TimedOut'].includes(status)) {
        const out = aws(['ssm', 'get-command-invocation', '--command-id', id, '--instance-id', INSTANCE, '--query', '[StandardOutputContent,StandardErrorContent]', '--output', 'text']);
        if (status !== 'Success') throw new Error(`server step failed: ${out}`);
        return out;
      }
    }
    throw new Error('server step timed out');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ── Accounts ────────────────────────────────────────────────────────────────
async function shopLogin(identifier) {
  const r = await call('POST', `${API.auth}/auth/login`, { body: { context: 'tenant', identifier, password: PASSWORD } });
  if (!ok(r)) return null;
  return { token: r.data.accessToken, tenantId: r.data.tenant?.tenantId, branchId: r.data.branch?.branchId, userId: r.data.user.userId, role: r.data.user.roleCode };
}

async function customerLogin(identifier, password = PASSWORD) {
  const r = await call('POST', `${API.auth}/auth/login`, { body: { context: 'consumer', identifier, password } });
  return ok(r) ? { token: r.data.accessToken, consumerId: r.data.user.userId } : null;
}

/** Catalog pairs (service × item) that have a price for this branch. */
async function pricedPairs(shop) {
  const services = list(await call('GET', `${API.catalog}/services`, { token: shop.token, branchId: shop.branchId }));
  const pairs = [];
  for (const service of services) {
    const prices = list(await call('GET', `${API.catalog}/services/${service.id}/pricing`, { token: shop.token, branchId: shop.branchId }));
    for (const p of prices) pairs.push({ serviceId: service.id, serviceName: service.serviceName ?? service.name, itemCategoryId: p.itemCategoryId, price: p.basePrice });
  }
  return pairs;
}

async function createOrder(shop, customerId, items) {
  return must(
    await call('POST', `${API.orders}/orders`, {
      token: shop.token, branchId: shop.branchId,
      body: { customerId, items, expectedDeliveryDate: weekday(2) },
    }),
    'create order',
  );
}

// ── seed ────────────────────────────────────────────────────────────────────
async function seed() {
  console.log(`# Seeding demo data on ${DOMAIN} (Andheri, Mumbai)\n`);
  const shops = {};
  for (const def of SHOPS) {
    const ownerEmail = email(def.key);
    let shop = await shopLogin(ownerEmail);
    if (!shop) {
      must(await call('POST', `${API.tenant}/tenants/register`, {
        body: { businessName: def.name, businessType: def.type, ownerName: `${def.name.replace(' (Demo)', '')} Owner (Demo)`, email: ownerEmail, mobileNumber: def.phone, password: PASSWORD, agreedToTerms: true },
      }), `register ${def.name}`);
      shop = await shopLogin(ownerEmail);
      // Same call as the app's onboarding: branch + services (fills the catalog).
      must(await call('PATCH', `${API.tenant}/tenants/${shop.tenantId}`, {
        token: shop.token,
        body: {
          businessName: def.name, businessType: def.type, ownerName: `${def.name.replace(' (Demo)', '')} Owner (Demo)`,
          email: ownerEmail, mobileNumber: def.phone, services: def.services, staff: [],
          branch: { branchName: def.branch, streetAddress: def.listing?.streetAddress ?? 'Address to be added', city: 'Mumbai', postalCode: def.listing?.postalCode ?? '400053', phone: def.phone, email: ownerEmail },
        },
      }), `onboard ${def.name}`);
      shop = await shopLogin(ownerEmail); // token now carries the onboarded branch
      console.log(`  + shop      ${def.name}`);
    } else {
      console.log(`  = shop      ${def.name} (already there)`);
    }
    if (def.listing) {
      must(await call('PUT', `${API.market}/shop-listing/me`, { token: shop.token, body: { ...def.listing, isListed: true } }), `listing ${def.name}`);
    }
    for (const s of def.staff ?? []) {
      const loginId = email(s.key);
      if (!(await shopLogin(loginId))) {
        must(await call('POST', `${API.users}/users/tenant/${shop.tenantId}/register`, {
          token: shop.token, branchId: shop.branchId,
          body: { name: s.name, loginId, password: PASSWORD, role: 'Staff', branchIds: [shop.branchId], sendInvite: false },
        }), `staff ${s.name}`);
        console.log(`  + staff     ${s.name} at ${def.name}`);
      }
      const staff = await shopLogin(loginId);
      if (staff) {
        await call('PATCH', `${API.users}/users/me/availability`, { token: staff.token, branchId: shop.branchId, body: { availability: 'Available' } });
      }
    }
    shops[def.key] = shop;
  }

  for (const def of CUSTOMERS) {
    const r = await call('POST', `${API.auth}/auth/consumer/register`, {
      body: { fullName: def.name, email: email(def.key), mobileNumber: def.mobile, password: PASSWORD },
    });
    console.log(ok(r) ? `  + customer  ${def.name} (code emailed to your inbox)` : `  = customer  ${def.name} (${r.body?.error?.code ?? r.status})`);
  }
  console.log(`  ${serverTool(`verify '${EMAIL_PATTERN}'`).trim()}`);

  const customers = {};
  for (const def of CUSTOMERS) {
    const c = await customerLogin(email(def.key));
    if (!c) throw new Error(`customer login failed for ${def.name}`);
    const existing = list(await call('GET', `${API.market}/consumer/addresses`, { token: c.token }));
    if (existing.length === 0) {
      for (const a of def.addresses) must(await call('POST', `${API.market}/consumer/addresses`, { token: c.token, body: a }), `address ${def.name}`);
    }
    c.addresses = list(await call('GET', `${API.market}/consumer/addresses`, { token: c.token }));
    customers[def.key] = c;
  }

  // Requests in every state, only on the first run.
  const sparkle = shops.sparkle;
  const already = list(await call('GET', `${API.market}/shop/requests`, { token: sparkle.token }));
  if (already.length === 0) {
    const home = (key) => customers[key].addresses.find((a) => a.isDefault).addressId;
    const book = async (who, shopKey, body) =>
      must(await call('POST', `${API.market}/consumer/requests`, {
        token: customers[who].token,
        body: { shopId: shops[shopKey].branchId, preferredDate: weekday(1), preferredSlot: { start: '10:00', end: '12:00' }, ...body },
      }), `request ${who}→${shopKey}`);

    await book('riya', 'sparkle', { category: 'laundry', requestType: 'pickup_drop', addressId: home('riya'), description: 'Pickup 6 kg clothes, wash and fold. 2 bedsheets have stains.', items: [{ name: 'Clothes (kg)', quantity: 6 }, { name: 'Bedsheet', quantity: 2 }] });
    await book('amit', 'sparkle', { category: 'dry_cleaning', requestType: 'visit_shop', description: 'Dry clean 2 suits before Saturday wedding.', items: [{ name: 'Suit', quantity: 2 }], preferredSlot: { start: '17:00', end: '19:00' } });
    const neha = await book('neha', 'sparkle', { category: 'laundry', requestType: 'pickup_drop', addressId: home('neha'), description: 'Curtains and sofa covers.', items: [{ name: 'Curtain', quantity: 4 }] });
    const accepted = must(await call('POST', `${API.market}/shop/requests/${neha.requestId}/accept`, { token: sparkle.token, body: { note: 'Our delivery boy will come at 10:30 am.' } }), 'accept');
    const pairs = await pricedPairs(sparkle);
    const order = await createOrder(sparkle, accepted.shopCustomerId, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 4 }]);
    must(await call('POST', `${API.market}/shop/requests/${neha.requestId}/link-order`, { token: sparkle.token, body: { orderId: order.id } }), 'link order');

    const salon = await book('riya', 'glamour', { category: 'salon', requestType: 'home_service', addressId: home('riya'), description: 'Haircut and facial at home for 2 people.', preferredSlot: { start: '16:00', end: '18:00' } });
    must(await call('POST', `${API.market}/shop/requests/${salon.requestId}/accept`, { token: shops.glamour.token, body: { note: 'Stylist Pooja will visit.' } }), 'accept salon');
    const done = await book('neha', 'glamour', { category: 'salon', requestType: 'visit_shop', description: 'Hair spa appointment.', preferredSlot: { start: '12:00', end: '13:00' } });
    must(await call('POST', `${API.market}/shop/requests/${done.requestId}/accept`, { token: shops.glamour.token, body: {} }), 'accept salon 2');
    must(await call('POST', `${API.market}/shop/requests/${done.requestId}/complete`, { token: shops.glamour.token, body: {} }), 'complete salon');
    const fridge = await book('amit', 'quickfix', { category: 'appliance_repair', requestType: 'home_service', addressId: home('amit'), description: 'Fridge not cooling since yesterday.' });
    must(await call('POST', `${API.market}/shop/requests/${fridge.requestId}/decline`, { token: shops.quickfix.token, body: { reason: 'Technician on leave this week — please call 98200 11003 next week.' } }), 'decline');
    const blouse = await book('riya', 'stitch', { category: 'tailoring', requestType: 'visit_shop', description: 'Blouse stitching, need by Diwali.', preferredSlot: { start: '15:00', end: '16:00' } });
    must(await call('POST', `${API.consumerRequests ?? `${API.market}/consumer/requests`}/${blouse.requestId}/cancel`, { token: customers.riya.token, body: { reason: 'Found a tailor closer to work.' } }), 'cancel');
    console.log('  + requests  waiting ×2, accepted ×2 (one with a linked order), completed, declined, cancelled');

    // Worker Tasks: walk-in orders assigned to the two demo workers.
    const ravi = await shopLogin(email('ravi'));
    const sunita = await shopLogin(email('sunita'));
    const raviId = await staffUserId(sparkle, 'ravi');
    const sunitaId = await staffUserId(sparkle, 'sunita');
    const walkIns = [];
    for (const [name, mobile] of [['Kavita Desai (Demo)', '+916300000001'], ['Rohan Mehta (Demo)', '+916300000002'], ['Sameer Khan (Demo)', '+916300000003']]) {
      walkIns.push(must(await call('POST', `${API.customers}/customers`, { token: sparkle.token, branchId: sparkle.branchId, body: { name, mobile, customerType: 'Regular' } }), `walk-in ${name}`));
    }
    const o1 = await createOrder(sparkle, walkIns[0].id, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 3 }]);
    const o2 = await createOrder(sparkle, walkIns[1].id, [{ serviceId: pairs[1 % pairs.length].serviceId, itemCategoryId: pairs[1 % pairs.length].itemCategoryId, quantity: 2 }]);
    const o3 = await createOrder(sparkle, walkIns[2].id, [{ serviceId: pairs[2 % pairs.length].serviceId, itemCategoryId: pairs[2 % pairs.length].itemCategoryId, quantity: 5 }]);
    await createOrder(sparkle, walkIns[0].id, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 1 }]); // left unassigned
    must(await call('POST', `${API.orders}/orders/${o1.id}/assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { assignedTo: raviId, note: 'Urgent — customer pickup at 6 pm.' } }), 'assign o1');
    must(await call('POST', `${API.orders}/orders/${o1.id}/assignment/accept`, { token: ravi.token, branchId: sparkle.branchId, body: {} }), 'ravi accepts');
    must(await call('POST', `${API.orders}/orders/${o1.id}/notes`, { token: ravi.token, branchId: sparkle.branchId, body: { text: 'Collar of one shirt already torn when received.', kind: 'Damage' } }), 'damage note');
    must(await call('POST', `${API.orders}/orders/${o2.id}/assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { assignedTo: sunitaId } }), 'assign o2');
    must(await call('POST', `${API.orders}/orders/${o2.id}/assignment/decline-request`, { token: sunita.token, branchId: sparkle.branchId, body: { reason: 'On half day today, cannot finish by evening.' } }), 'decline request');
    must(await call('POST', `${API.orders}/orders/${o3.id}/assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { assignedTo: sunitaId } }), 'assign o3');
    console.log('  + orders    4 walk-in orders: accepted by Ravi (with damage note), decline request from Sunita (waiting for owner), one assigned, one unassigned');
  } else {
    console.log('  = requests and orders already seeded (run cleanup --yes to start over)');
  }

  printLogins();
}

async function staffUserId(shop, key) {
  const users = list(await call('GET', `${API.users}/users/tenant/${shop.tenantId}`, { token: shop.token, branchId: shop.branchId }));
  const user = users.find((u) => (u.loginId ?? u.email ?? '').toLowerCase() === email(key));
  if (!user) throw new Error(`staff ${key} not found in user-service`);
  return user.id ?? user._id ?? user.userId;
}

function printLogins() {
  console.log(`\n# Demo logins (password for all: ${PASSWORD})`);
  console.log('  Shops ("I run a business"):');
  for (const s of SHOPS) console.log(`    ${s.name.padEnd(34)} ${email(s.key)}`);
  console.log('  Workers (shop login):');
  for (const s of SHOPS.flatMap((x) => x.staff ?? [])) console.log(`    ${s.name.padEnd(34)} ${email(s.key)}`);
  console.log('  Customers ("I need a service" — email or mobile):');
  for (const c of CUSTOMERS) console.log(`    ${c.name.padEnd(34)} ${email(c.key)}  /  ${c.mobile}`);
}

// ── e2e ─────────────────────────────────────────────────────────────────────
async function e2e() {
  let passed = 0;
  let failed = 0;
  let section = '';
  const check = (name, condition, detail = '') => {
    condition ? passed++ : failed++;
    console.log(`${condition ? 'PASS' : 'FAIL'}  ${name}${detail !== '' ? `  — ${detail}` : ''}`);
  };
  const head = (title) => { section = title; console.log(`\n## ${title}`); };
  console.log(`# End-to-end tests on ${DOMAIN}`);

  try {
    const sparkle = await shopLogin(email('sparkle'));
    const glamour = await shopLogin(email('glamour'));
    const newshop = await shopLogin(email('newshop'));
    const ravi = await shopLogin(email('ravi'));
    const sunita = await shopLogin(email('sunita'));
    const riya = await customerLogin(email('riya'));
    const amit = await customerLogin('6200000002'); // by mobile
    if (!sparkle || !glamour || !newshop || !ravi || !sunita || !riya || !amit) throw new Error('demo accounts missing — run seed first');

    // 1. Customer accounts
    head('1. Customer sign-up and login');
    const run = Date.now().toString(36);
    const newEmail = email(`e2e-${run}`);
    const newMobile = `64${String(Date.now()).slice(-8)}`;
    const reg = await call('POST', `${API.auth}/auth/consumer/register`, { body: { fullName: `E2E Tester ${run} (Demo)`, email: newEmail, mobileNumber: `+91 ${newMobile}`, password: PASSWORD } });
    check('sign-up emails a 6-digit code (real email to your inbox)', reg.status === 201 && /6-digit code/.test(reg.data?.deliveryHint ?? ''), `${reg.status} ${reg.data?.deliveryHint ?? why(reg)}`);
    const dupMobile = await call('POST', `${API.auth}/auth/consumer/register`, { body: { fullName: 'Dup (Demo)', email: email(`dup-${run}`), mobileNumber: newMobile, password: PASSWORD } });
    check('same mobile cannot sign up twice', dupMobile.status === 409 && dupMobile.body?.error?.code === 'consumer.mobile_taken', `${dupMobile.status}`);
    const weak = await call('POST', `${API.auth}/auth/consumer/register`, { body: { fullName: 'Weak (Demo)', email: email(`weak-${run}`), mobileNumber: `65${String(Date.now()).slice(-8)}`, password: 'password' } });
    check('weak password refused', weak.status === 400 && weak.body?.error?.code === 'auth.password_policy_failed', `${weak.status}`);
    const early = await call('POST', `${API.auth}/auth/login`, { body: { context: 'consumer', identifier: newEmail, password: PASSWORD } });
    check('login refused until the email is verified', early.status === 403 && early.body?.error?.code === 'auth.email_not_verified', `${early.status}`);
    const wrongCode = await call('POST', `${API.auth}/auth/consumer/verify-email`, { body: { email: newEmail, otp: '000000' } });
    check('wrong code refused', wrongCode.status === 400, `${wrongCode.status}`);
    const resend = await call('POST', `${API.auth}/auth/consumer/resend-verification`, { body: { email: newEmail } });
    check('resend is rate-limited (wait shown)', ok(resend) && resend.data.resendAvailableInSeconds > 0, `${resend.data?.resendAvailableInSeconds}s`);
    serverTool(`verify '${EMAIL_PATTERN}'`);
    const fresh = await customerLogin(newMobile);
    check('verified customer signs in with mobile number', !!fresh);
    const badPw = await call('POST', `${API.auth}/auth/login`, { body: { context: 'consumer', identifier: newEmail, password: 'Wrong@2026' } });
    check('wrong password refused without saying why', badPw.status === 401 && badPw.body?.error?.code === 'auth.login_denied', `${badPw.status}`);
    const ctx = await call('GET', `${API.auth}/auth/consumer/context`, { token: fresh.token });
    check('customer profile resolves', ok(ctx) && ctx.data.kind === 'consumer' && ctx.data.mobileNumber === newMobile);
    const forgot = await call('POST', `${API.auth}/auth/forgot-password`, { body: { context: 'consumer', identifier: newEmail } });
    check('forgot password works for customers (code emailed)', ok(forgot), `${forgot.status}`);

    // 2. Security boundaries
    head('2. Security');
    const noLogin = await call('GET', `${API.market}/marketplace/shops`);
    check('no login → no shops or phone numbers', noLogin.status === 401, `${noLogin.status}`);
    const asShop = await call('GET', `${API.auth}/auth/context`, { token: riya.token, branchId: sparkle.branchId });
    check('customer token refused by every shop service check', asShop.status === 403, `${asShop.status}`);
    for (const [label, url] of [['orders', `${API.orders}/orders`], ['shop customer list', `${API.customers}/customers`], ['shop inbox', `${API.market}/shop/requests`], ['listing editor', `${API.market}/shop-listing/me`]]) {
      const r = await call('GET', url, { token: riya.token, branchId: sparkle.branchId });
      check(`customer cannot open ${label}`, r.status === 401 || r.status === 403, `${r.status}`);
    }
    const shopAsCustomer = await call('GET', `${API.market}/marketplace/shops`, { token: sparkle.token });
    check('shop token cannot use customer search', shopAsCustomer.status === 401 || shopAsCustomer.status === 403, `${shopAsCustomer.status}`);
    const riyaAddr = list(await call('GET', `${API.market}/consumer/addresses`, { token: riya.token }));
    const steal = await call('PATCH', `${API.market}/consumer/addresses/${riyaAddr[0].addressId}`, { token: amit.token, body: { city: 'Pune' } });
    check("one customer cannot edit another's address", steal.status === 404, `${steal.status}`);

    // 3. Addresses
    head('3. Addresses');
    const noAddr = await call('GET', `${API.market}/marketplace/shops`, { token: fresh.token });
    check('no address → asked to add one before seeing shops', noAddr.status === 409, `${noAddr.status}`);
    const a1 = await call('POST', `${API.market}/consumer/addresses`, { token: fresh.token, body: { label: 'Home', houseFlat: 'Flat 9, Demo Heights', streetArea: 'Lokhandwala', city: 'Mumbai', state: 'Maharashtra', pincode: '400053', latitude: 19.1385, longitude: 72.8305 } });
    check('first address becomes default; contact filled from profile', a1.status === 201 && a1.data.isDefault && a1.data.contactPhone === newMobile, `${a1.status}`);
    const lastDel = await call('DELETE', `${API.market}/consumer/addresses/${a1.data.addressId}`, { token: fresh.token });
    check('the only address cannot be deleted', lastDel.status === 409, `${lastDel.status}`);
    const a2 = await call('POST', `${API.market}/consumer/addresses`, { token: fresh.token, body: { label: 'Work', houseFlat: 'Desk 4', streetArea: 'Marol', city: 'Mumbai', state: 'Maharashtra', pincode: '400059', latitude: 19.115, longitude: 72.86, isDefault: true } });
    const afterDefault = list(await call('GET', `${API.market}/consumer/addresses`, { token: fresh.token }));
    check('new default replaces the old one (exactly one default)', a2.status === 201 && afterDefault.filter((a) => a.isDefault).length === 1 && afterDefault[0].addressId === a2.data.addressId);
    const badPin = await call('POST', `${API.market}/consumer/addresses`, { token: fresh.token, body: { label: 'Other', houseFlat: 'x', streetArea: 'y', city: 'z', state: 's', pincode: '012345', latitude: 19.1, longitude: 72.8 } });
    check('invalid PIN refused', badPin.status === 400, `${badPin.status}`);
    const outside = await call('POST', `${API.market}/consumer/addresses`, { token: fresh.token, body: { label: 'Other', houseFlat: 'x', streetArea: 'y', city: 'z', state: 's', pincode: '400053', latitude: 51.5, longitude: -0.12 } });
    check('pin outside India refused', outside.status === 400, `${outside.status}`);
    await call('POST', `${API.market}/consumer/addresses/${a1.data.addressId}/default`, { token: fresh.token });
    const del2 = await call('DELETE', `${API.market}/consumer/addresses/${a2.data.addressId}`, { token: fresh.token });
    check('a second address can be deleted', del2.status === 204, `${del2.status}`);

    // 4. Nearby search
    head('4. Nearby shops');
    const all = await call('GET', `${API.market}/marketplace/shops?radiusKm=10&limit=50`, { token: riya.token });
    const demoShops = list(all).filter((s) => s.shopName.endsWith('(Demo)'));
    check('all 5 listed demo shops found near Riya', demoShops.length === 5, demoShops.map((s) => `${s.shopName} ${s.distanceKm}km`).join(' | '));
    check('sorted nearest first', demoShops.every((s, i) => i === 0 || s.distanceKm >= demoShops[i - 1].distanceKm));
    check('shop with no address is hidden from customers', !list(all).some((s) => s.shopName.startsWith('New Shop Pending')));
    const sp = demoShops.find((s) => s.shopName.startsWith('Sparkle'));
    check('booking landline shown as typed', sp?.phone === '02226321001', sp?.phone);
    const gl = demoShops.find((s) => s.shopName.startsWith('Glamour'));
    check('no booking phone → owner phone shown', gl?.phone === '6100000002', gl?.phone);
    const salons = list(await call('GET', `${API.market}/marketplace/shops?category=salon&radiusKm=10`, { token: riya.token })).filter((s) => s.shopName.endsWith('(Demo)'));
    check('category filter (salon)', salons.length === 1 && salons[0].shopName.startsWith('Glamour'));
    const home = list(await call('GET', `${API.market}/marketplace/shops?mode=home_service&radiusKm=10`, { token: riya.token })).filter((s) => s.shopName.endsWith('(Demo)'));
    check('home-service filter only shows shops that reach Riya', home.length > 0 && home.every((s) => s.servesYourLocation), home.map((s) => s.shopName).join(', '));
    const near = list(await call('GET', `${API.market}/marketplace/shops?radiusKm=1`, { token: riya.token })).filter((s) => s.shopName.endsWith('(Demo)'));
    check('1 km radius narrows the list', near.length < demoShops.length, `${near.length} within 1 km`);
    const byName = list(await call('GET', `${API.market}/marketplace/shops?q=stitch&radiusKm=10`, { token: riya.token }));
    check('search by name', byName.length === 1 && byName[0].shopName.startsWith('Perfect Stitch'));
    const gps = list(await call('GET', `${API.market}/marketplace/shops?latitude=19.1176&longitude=72.8697&radiusKm=10`, { token: riya.token })).filter((s) => s.shopName.endsWith('(Demo)'));
    check('search from current GPS (MIDC) puts the car wash first', gps[0]?.shopName.startsWith('Shine'), gps[0]?.shopName);
    const work = riyaAddr.find((a) => a.label === 'Work');
    const fromWork = list(await call('GET', `${API.market}/marketplace/shops?addressId=${work.addressId}&radiusKm=10`, { token: riya.token })).filter((s) => s.shopName.endsWith('(Demo)'));
    check("search from Riya's Work address changes the order", fromWork[0]?.shopName !== demoShops[0].shopName, `${fromWork[0]?.shopName} first`);
    const detail = await call('GET', `${API.market}/marketplace/shops/${sparkle.branchId}`, { token: riya.token });
    check('shop page: 7 days of hours, about, directions link', ok(detail) && detail.data.openingHours.length === 7 && !!detail.data.about && detail.data.directionsUrl.includes('19.1405'));

    // 5. Booking rules
    head('5. Booking');
    const book = (token, body) => call('POST', `${API.market}/consumer/requests`, { token, body: { shopId: sparkle.branchId, category: 'laundry', requestType: 'visit_shop', description: 'E2E booking test', preferredDate: weekday(1), preferredSlot: { start: '10:00', end: '12:00' }, ...body } });
    const qf = (await shopLogin(email('quickfix')));
    const sunday = (() => { for (let d = 1; ; d++) if (new Date(`${istDate(d)}T00:00:00Z`).getUTCDay() === 0) return istDate(d); })();
    const closed = await call('POST', `${API.market}/consumer/requests`, { token: fresh.token, body: { shopId: qf.branchId, category: 'appliance_repair', requestType: 'visit_shop', description: 'Sunday test', preferredDate: sunday, preferredSlot: { start: '10:00', end: '11:00' } } });
    check('closed day refused (QuickFix is shut on Sunday)', closed.status === 400, why(closed));
    check('past date refused', (await book(fresh.token, { preferredDate: istDate(-1) })).status === 400);
    check('slot ending before it starts refused', (await book(fresh.token, { preferredSlot: { start: '12:00', end: '10:00' } })).status === 400);
    check('service the shop does not offer refused', (await book(fresh.token, { category: 'salon' })).status === 400);
    check('pickup without an address refused', (await book(fresh.token, { requestType: 'pickup_drop' })).status === 400);
    const farPickup = await call('POST', `${API.market}/consumer/requests`, { token: fresh.token, body: { shopId: glamour.branchId, category: 'salon', requestType: 'home_service', description: 'Too far test', preferredDate: weekday(1), preferredSlot: { start: '10:00', end: '11:00' }, addressId: a2.data?.addressId ?? a1.data.addressId } });
    // a2 was deleted, so use a fresh far address for the travel-radius check
    const farAddr = await call('POST', `${API.market}/consumer/addresses`, { token: fresh.token, body: { label: 'Other', houseFlat: 'Far', streetArea: 'Powai', city: 'Mumbai', state: 'Maharashtra', pincode: '400076', latitude: 19.1176, longitude: 72.906 } });
    const tooFar = await call('POST', `${API.market}/consumer/requests`, { token: fresh.token, body: { shopId: glamour.branchId, category: 'salon', requestType: 'home_service', description: 'Too far test', preferredDate: weekday(1), preferredSlot: { start: '10:00', end: '11:00' }, addressId: farAddr.data.addressId } });
    check('home service beyond the shop’s reach refused (Glamour reaches 3 km)', tooFar.status === 400 && /km/.test(why(tooFar)), why(tooFar));
    void farPickup;
    const r1 = await book(fresh.token, { requestType: 'pickup_drop', addressId: a1.data.addressId, items: [{ name: 'Shirt', quantity: 5 }], description: 'E2E: wash and iron 5 shirts' });
    check('customer books a pickup', r1.status === 201 && r1.data.status === 'Pending' && /^SR-\d{4}-\d{6}$/.test(r1.data.requestNumber), `${r1.status} ${r1.data?.requestNumber ?? why(r1)}`);
    const r2 = await book(fresh.token, { description: 'E2E: second booking' });
    const r3 = await book(fresh.token, { description: 'E2E: third booking' });
    const r4 = await book(fresh.token, { description: 'E2E: fourth booking' });
    check('max 3 waiting requests per shop', ok(r2) && ok(r3) && r4.status === 409, `${r4.status}`);

    // 6. Shop side: inbox, customer list, accept / create order / complete, decline, cancel
    head('6. Shop: Online requests');
    const sum = await call('GET', `${API.market}/shop/requests/summary`, { token: sparkle.token });
    check('dashboard badge counts waiting requests', ok(sum) && sum.data.pending >= 3, JSON.stringify(sum.data));
    const inbox = list(await call('GET', `${API.market}/shop/requests?status=Pending&limit=50`, { token: sparkle.token }));
    const mine = inbox.find((r) => r.requestId === r1.data.requestId);
    check('request appears in the shop inbox with customer details', !!mine && mine.customer.mobile === newMobile && mine.actions.accept);
    const crm = list(await call('GET', `${API.customers}/customers?source=online&limit=100`, { token: sparkle.token, branchId: sparkle.branchId }));
    check("customer added to the shop's customer list as Online", crm.some((c) => c.consumerId === fresh.consumerId));
    const otherShop = await call('POST', `${API.market}/shop/requests/${r1.data.requestId}/accept`, { token: glamour.token, body: {} });
    check("another shop cannot touch Sparkle's request", otherShop.status === 404, `${otherShop.status}`);
    const confirmed = `${weekday(1)}T10:30:00+05:30`;
    const acc = await call('POST', `${API.market}/shop/requests/${r1.data.requestId}/accept`, { token: sparkle.token, body: { confirmedAt: confirmed, note: 'Coming at 10:30' } });
    check('shop accepts with time and note', ok(acc) && acc.data.status === 'Accepted' && acc.data.actions.linkOrder, `${acc.status}`);
    const seen = await call('GET', `${API.market}/consumer/requests/${r1.data.requestId}`, { token: fresh.token });
    check('customer sees Accepted, the note and the confirmed time', seen.data.status === 'Accepted' && seen.data.shopNote === 'Coming at 10:30' && Date.parse(seen.data.confirmedAt) === Date.parse(confirmed));
    check('customer never sees which staff member acted', seen.data.history.every((h) => !('actorId' in h)));
    const pairs = await pricedPairs(sparkle);
    check('shop catalog has priced items for orders', pairs.length > 0, `${pairs.length} priced pairs`);
    const order = await createOrder(sparkle, acc.data.shopCustomerId, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 5 }]);
    check('real order created for the online customer', !!order.id && !!order.orderNumber, order.orderNumber);
    const otherCust = list(await call('GET', `${API.customers}/customers?limit=100`, { token: sparkle.token, branchId: sparkle.branchId })).find((c) => c.id !== acc.data.shopCustomerId);
    const wrongOrder = await createOrder(sparkle, otherCust.id, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 1 }]);
    const mismatch = await call('POST', `${API.market}/shop/requests/${r1.data.requestId}/link-order`, { token: sparkle.token, body: { orderId: wrongOrder.id } });
    check('linking an order for a different customer refused', mismatch.status === 409, why(mismatch));
    const linked = await call('POST', `${API.market}/shop/requests/${r1.data.requestId}/link-order`, { token: sparkle.token, body: { orderId: order.id } });
    check('order linked to the request (checked through order-service)', ok(linked) && linked.data.orderNumber === order.orderNumber, `${linked.status}`);
    const lateCancel = await call('POST', `${API.market}/consumer/requests/${r1.data.requestId}/cancel`, { token: fresh.token, body: {} });
    check('customer cannot cancel once the order exists', lateCancel.status === 409, why(lateCancel));
    const done = await call('POST', `${API.market}/shop/requests/${r1.data.requestId}/complete`, { token: sparkle.token, body: {} });
    check('shop completes the request', ok(done) && done.data.status === 'Completed');
    const dec = await call('POST', `${API.market}/shop/requests/${r2.data.requestId}/decline`, { token: sparkle.token, body: { reason: 'Fully booked that day' } });
    const decSeen = await call('GET', `${API.market}/consumer/requests/${r2.data.requestId}`, { token: fresh.token });
    check('decline reason reaches the customer', ok(dec) && decSeen.data.declineReason === 'Fully booked that day');
    const noReason = await call('POST', `${API.market}/shop/requests/${r3.data.requestId}/decline`, { token: sparkle.token, body: { reason: '' } });
    check('decline needs a reason', noReason.status === 400);
    const cancel = await call('POST', `${API.market}/consumer/requests/${r3.data.requestId}/cancel`, { token: fresh.token, body: { reason: 'Changed plans' } });
    check('customer cancels a waiting request', ok(cancel) && cancel.data.status === 'Cancelled');
    const acceptCancelled = await call('POST', `${API.market}/shop/requests/${r3.data.requestId}/accept`, { token: sparkle.token, body: {} });
    check('cancelled request cannot be accepted', acceptCancelled.status === 409);
    const myRequests = list(await call('GET', `${API.market}/consumer/requests`, { token: fresh.token }));
    check('My requests shows every booking with its status', myRequests.length === 3 && new Set(myRequests.map((r) => r.status)).size === 3, myRequests.map((r) => r.status).join(', '));
    const workerInbox = await call('GET', `${API.market}/shop/requests/summary`, { token: ravi.token, branchId: sparkle.branchId });
    check('workers can see the Online requests count', ok(workerInbox), `${workerInbox.status}`);

    // 7. Shop listing
    head('7. Shop listing');
    const draft = await call('GET', `${API.market}/shop-listing/me`, { token: newshop.token });
    check('shop without an address gets the prompt (missing fields listed)', ok(draft) && draft.data.missingFields.includes('location') && draft.data.isVisibleToCustomers === false, JSON.stringify(draft.data?.missingFields));
    const workerEdit = await call('PUT', `${API.market}/shop-listing/me`, { token: ravi.token, branchId: sparkle.branchId, body: SHOPS[0].listing });
    check('a worker cannot change the listing', workerEdit.status === 403, `${workerEdit.status}`);
    const noHours = await call('PUT', `${API.market}/shop-listing/me`, { token: newshop.token, body: { ...SHOPS[0].listing, openingHours: week('09:00', '20:00').map((d) => ({ day: d.day, closed: true })) } });
    check('listing must be open at least one day', noHours.status === 400);
    const badPhone = await call('PUT', `${API.market}/shop-listing/me`, { token: newshop.token, body: { ...SHOPS[0].listing, bookingPhone: '12345' } });
    check('invalid booking phone refused', badPhone.status === 400);
    const sv = await call('GET', `${API.market}/shop-listing/me`, { token: sparkle.token });
    check('Sparkle listing is complete and visible', ok(sv) && sv.data.isVisibleToCustomers && sv.data.missingFields.length === 0);
    const off = await call('PUT', `${API.market}/shop-listing/me`, { token: glamour.token, body: { ...SHOPS[1].listing, isListed: false } });
    const hidden = list(await call('GET', `${API.market}/marketplace/shops?radiusKm=10`, { token: riya.token }));
    check('owner switches listing off → hidden from customers', ok(off) && off.data.hiddenReason === 'unlisted' && !hidden.some((s) => s.shopName.startsWith('Glamour')));
    await call('PUT', `${API.market}/shop-listing/me`, { token: glamour.token, body: { ...SHOPS[1].listing, isListed: true } });
    const back = list(await call('GET', `${API.market}/marketplace/shops?radiusKm=10`, { token: riya.token }));
    check('…and back on → visible again', back.some((s) => s.shopName.startsWith('Glamour')));

    // 8. Worker Tasks
    head('8. Worker Tasks');
    const ravId = await staffUserId(sparkle, 'ravi');
    const sunId = await staffUserId(sparkle, 'sunita');
    const o1 = await createOrder(sparkle, otherCust.id, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 2 }]);
    const asg = await call('POST', `${API.orders}/orders/${o1.id}/assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { assignedTo: sunId, note: 'E2E assignment' } });
    check('owner assigns an order to a worker', ok(asg), `${asg.status} ${ok(asg) ? '' : why(asg)}`);
    const reject = await call('POST', `${API.orders}/orders/${o1.id}/assignment/reject`, { token: sunita.token, branchId: sparkle.branchId, body: { reason: 'no' } });
    check('worker cannot reject outright', reject.status === 403 || reject.status === 400 || reject.status === 409, `${reject.status}`);
    const dreq = await call('POST', `${API.orders}/orders/${o1.id}/assignment/decline-request`, { token: sunita.token, branchId: sparkle.branchId, body: { reason: 'E2E: too much work today' } });
    check('worker sends a decline request with a reason', ok(dreq), `${dreq.status} ${ok(dreq) ? '' : why(dreq)}`);
    const pendingDeclines = list(await call('GET', `${API.orders}/orders/decline-requests`, { token: sparkle.token, branchId: sparkle.branchId }));
    check('owner sees the decline request', pendingDeclines.some((o) => (o.id ?? o.orderId) === o1.id), `${pendingDeclines.length} waiting`);
    const deny = await call('POST', `${API.orders}/orders/${o1.id}/assignment/decline-request/deny`, { token: sparkle.token, branchId: sparkle.branchId, body: { note: 'Please finish it, it is small' } });
    check('owner denies → worker keeps the order', ok(deny) && (deny.data.assignedTo ?? deny.data.assignment?.assignedTo) === sunId, `${deny.status}`);
    const dreq2 = await call('POST', `${API.orders}/orders/${o1.id}/assignment/decline-request`, { token: sunita.token, branchId: sparkle.branchId, body: { reason: 'E2E: still too much' } });
    const approve = await call('POST', `${API.orders}/orders/${o1.id}/assignment/decline-request/approve`, { token: sparkle.token, branchId: sparkle.branchId, body: {} });
    check('second request approved → order back to Received, unassigned', ok(dreq2) && ok(approve) && approve.data.status === 'Received' && !approve.data.assignedTo, `${approve.status} ${approve.data?.status}`);
    const asg2 = await call('POST', `${API.orders}/orders/${o1.id}/assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { assignedTo: ravId } });
    const accept = await call('POST', `${API.orders}/orders/${o1.id}/assignment/accept`, { token: ravi.token, branchId: sparkle.branchId, body: {} });
    check('worker accepts an assignment', ok(asg2) && ok(accept), `${accept.status}`);
    const note = await call('POST', `${API.orders}/orders/${o1.id}/notes`, { token: ravi.token, branchId: sparkle.branchId, body: { text: 'E2E: button missing on one shirt', kind: 'Damage' } });
    check('worker adds a damage note', ok(note), `${note.status}`);
    const withNote = await call('GET', `${API.orders}/orders/${o1.id}`, { token: sparkle.token, branchId: sparkle.branchId });
    check('owner sees the note on the order', (withNote.data.notes ?? []).some((n) => n.kind === 'Damage' && n.text.startsWith('E2E')));
    const notMine = await call('GET', `${API.orders}/orders/${o1.id}`, { token: sunita.token, branchId: sparkle.branchId });
    check("a worker cannot open another worker's order", notMine.status === 404 || notMine.status === 403, `${notMine.status}`);
    const bulkOrders = [];
    for (let i = 0; i < 4; i++) bulkOrders.push((await createOrder(sparkle, otherCust.id, [{ serviceId: pairs[0].serviceId, itemCategoryId: pairs[0].itemCategoryId, quantity: 1 }])).id);
    const dry = await call('POST', `${API.orders}/orders/bulk-assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { mode: 'auto', orderIds: bulkOrders, workerIds: [ravId, sunId], dryRun: true } });
    const stillFree = await call('GET', `${API.orders}/orders/${bulkOrders[0]}`, { token: sparkle.token, branchId: sparkle.branchId });
    check('bulk auto-assign dry run previews without assigning', ok(dry) && !stillFree.data.assignedTo, `${dry.status} ${ok(dry) ? '' : why(dry)}`);
    const real = await call('POST', `${API.orders}/orders/bulk-assign`, { token: sparkle.token, branchId: sparkle.branchId, body: { mode: 'auto', orderIds: bulkOrders, workerIds: [ravId, sunId] } });
    const after = await Promise.all(bulkOrders.map((id) => call('GET', `${API.orders}/orders/${id}`, { token: sparkle.token, branchId: sparkle.branchId })));
    const counts = after.reduce((m, r) => ({ ...m, [r.data.assignedTo]: (m[r.data.assignedTo] ?? 0) + 1 }), {});
    check('bulk auto-assign splits the orders between both workers', ok(real) && Object.keys(counts).length === 2 && after.every((r) => r.data.assignedTo), JSON.stringify(Object.values(counts)));
    const workload = await call('GET', `${API.orders}/orders/workload`, { token: sparkle.token, branchId: sparkle.branchId });
    const workers = workload.data?.workers ?? [];
    const raviLoad = workers.find((w) => w.workerId === ravId);
    check(
      'workload view: each worker with open, accepted and damage counts',
      ok(workload) && workers.length >= 2 && raviLoad?.accepted >= 1 && raviLoad?.damageReports >= 1,
      workers.map((w) => `open ${w.open}/accepted ${w.accepted}/damage ${w.damageReports}`).join(' | '),
    );
  } catch (error) {
    failed++;
    console.log(`ERROR in "${section}": ${error.message}`);
  }
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exitCode = failed ? 1 : 0;
}

// ── cleanup ─────────────────────────────────────────────────────────────────
function cleanup(confirm) {
  console.log(serverTool(`cleanup '${EMAIL_PATTERN}'${confirm ? ' --delete' : ''}`));
  if (!confirm) console.log('\nDry run only. Run again with --yes to delete.');
}

const [command, flag] = process.argv.slice(2);
if (command === 'seed') await seed();
else if (command === 'e2e') await e2e();
else if (command === 'cleanup') cleanup(flag === '--yes');
else if (command === 'logins') printLogins();
else {
  console.log('usage: node scripts/demo/marketplace-demo.mjs seed | e2e | cleanup [--yes] | logins');
  process.exitCode = 1;
}
