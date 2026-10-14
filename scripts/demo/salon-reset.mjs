#!/usr/bin/env node
// Salon reset: remove every salon shop from the live server, then fill one complete demo salon
// (team with roles, service menu, staff logins, customers, a few bookings) through the same APIs the app uses.
//
//   node scripts/demo/salon-reset.mjs list            dry run: shows every salon shop and what would be deleted
//   node scripts/demo/salon-reset.mjs delete --yes    DELETE every salon shop and all its data (cannot be undone)
//   node scripts/demo/salon-reset.mjs seed            fill the demo salon and print the logins
//   node scripts/demo/salon-reset.mjs seed-shop       same, but only the shop side (no customer or bookings, no server step)
//   node scripts/demo/salon-reset.mjs catalog         the shop's own services, items and prices (walk-in orders)
//
// The shop owned by qwerty@gmail.com is kept (set SALON_OWNER to use another email); the demo data goes into it.
//
// Needs Node 20+ and the AWS CLI signed in (list/delete/verify run on the server through AWS SSM).
// Other businesses (laundry, tailoring, ...) are never touched.
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const DOMAIN = process.env.DEMO_DOMAIN ?? '65-1-66-219.sslip.io';
const INSTANCE = process.env.DEMO_INSTANCE ?? 'i-01a4e8536097607c8';
const REGION = 'ap-south-1';
const PASSWORD = 'Iuc@12345';

const OWNER_EMAIL = process.env.SALON_OWNER ?? 'qwerty@gmail.com';
const MANAGER_ID = 'asdfg@gmail.com';
const STAFF_ID = 'zxcvb@gmail.com';
const CUSTOMER_EMAIL = 'poiuy@gmail.com';
const CUSTOMER_MOBILE = '9811200099';

const API = {
  auth: `https://auth.${DOMAIN}/api/v1`,
  tenant: `https://tenant.${DOMAIN}/api/v1`,
  market: `https://market.${DOMAIN}/api/v1`,
  customers: `https://customer.${DOMAIN}`,
  users: `https://user.${DOMAIN}/api/v1`,
  catalog: `https://catalog.${DOMAIN}/api/v1`,
};

const SHOP = {
  name: 'Glow Salon',
  ownerName: 'Ayushi Krishna',
  phone: '9876500022',
  branch: 'Hadapsar',
  listing: {
    streetAddress: 'Shop 5, Magarpatta Road',
    area: 'Hadapsar',
    landmark: 'Near Seasons Mall',
    city: 'Pune',
    state: 'Maharashtra',
    postalCode: '411028',
    latitude: 18.5095,
    longitude: 73.9262,
    bookingPhone: '020 2681 0022',
    serviceModes: ['visit_shop', 'home_service'],
    serviceRadiusKm: 8,
    openingHours: [0, 1, 2, 3, 4, 5, 6].map((day) => ({ day, closed: false, open: '10:00', close: '20:00' })),
    about: 'Haircuts, colour, facials, nails and bridal makeup. Home visits available.',
  },
};

const SLOT_MINUTES = 15;
const TEAM = [
  ['Priya Sharma', 'Hair Stylist'],
  ['Neha Kulkarni', 'Hair Stylist'],
  ['Kiran Patil', 'Barber'],
  ['Sana Sheikh', 'Makeup Artist'],
  ['Riya Joshi', 'Beautician'],
  ['Pooja More', 'Nail Artist'],
];
// [name, price, minutes, role]
const MENU = [
  ['Haircut (Women)', 400, 45, 'Hair Stylist'],
  ['Haircut (Men)', 200, 30, 'Barber'],
  ['Hair Wash & Blow-dry', 300, 30, 'Hair Stylist'],
  ['Hair Colour', 1800, 90, 'Hair Stylist'],
  ['Hair Spa', 1200, 60, 'Hair Stylist'],
  ['Beard Trim', 120, 15, 'Barber'],
  ['Shave', 100, 15, 'Barber'],
  ['Facial', 900, 60, 'Beautician'],
  ['Clean-up', 500, 30, 'Beautician'],
  ['Waxing (Full Arms)', 350, 30, 'Beautician'],
  ['Threading', 60, 15, 'Beautician'],
  ['Manicure', 450, 45, 'Nail Artist'],
  ['Pedicure', 550, 45, 'Nail Artist'],
  ['Party Makeup', 2500, 60, 'Makeup Artist'],
  ['Bridal Makeup', 12000, 120, 'Makeup Artist'],
];
const WALK_INS = [
  ['Rohan Deshmukh', '9811100001'], ['Kavita Joshi', '9811100002'], ['Sameer Khan', '9811100003'],
  ['Anjali Kulkarni', '9811100004'], ['Vikram Bhosale', '9811100005'], ['Pooja Jadhav', '9811100006'],
];
const STAFF_LOGINS = [
  { loginId: MANAGER_ID, name: 'Meera Nair', role: 'Branch Manager' },
  { loginId: STAFF_ID, name: 'Sunil Gaikwad', role: 'Staff' },
];

// The shop's own price list (what the New Order screen uses): items, services and a price for each pair.
// [name, group, unit]
const CATALOG_ITEMS = [
  ['Hair (Women)', 'Hair', 'Piece'], ['Hair (Men)', 'Hair', 'Piece'], ['Hair (Kids)', 'Hair', 'Piece'], ['Beard', 'Hair', 'Piece'],
  ['Face', 'Face', 'Piece'], ['Hands', 'Hands', 'Pair'], ['Feet', 'Feet', 'Pair'], ['Nails', 'Nails', 'Piece'],
];
// Services the salon template does not have: [name, code, minutes]
const EXTRA_SERVICES = [
  ['Hair Spa', 'SALON_HAIR_SPA', 60], ['Beard Trim', 'SALON_BEARD_TRIM', 15], ['Shave', 'SALON_SHAVE', 15], ['Clean-up', 'SALON_CLEANUP', 30],
  ['Waxing', 'SALON_WAXING', 30], ['Threading', 'SALON_THREADING', 15], ['Party Makeup', 'SALON_PARTY_MAKEUP', 60], ['Bridal Makeup', 'SALON_BRIDAL_MAKEUP', 120],
];
// item -> [service code, price]
const PRICES = {
  'Hair (Women)': [['SALON_HAIRCUT', 400], ['SALON_HAIR_WASH', 300], ['SALON_HAIR_COLOR', 1800], ['SALON_HAIR_STYLING', 500], ['SALON_CURLING', 700], ['SALON_STRAIGHTENING', 2500], ['SALON_HAIR_SPA', 1200]],
  'Hair (Men)': [['SALON_HAIRCUT', 200], ['SALON_HAIR_WASH', 120], ['SALON_HAIR_COLOR', 900], ['SALON_HAIR_STYLING', 250], ['SALON_HAIR_SPA', 800]],
  'Hair (Kids)': [['SALON_HAIRCUT', 150], ['SALON_HAIR_WASH', 100]],
  Beard: [['SALON_BEARD_TRIM', 120], ['SALON_SHAVE', 100], ['SALON_HAIR_COLOR', 300]],
  Face: [['SALON_FACIAL', 900], ['SALON_CLEANUP', 500], ['SALON_THREADING', 60], ['SALON_WAXING', 150], ['SALON_PARTY_MAKEUP', 2500], ['SALON_BRIDAL_MAKEUP', 12000]],
  Hands: [['SALON_MANICURE', 450], ['SALON_WAXING', 350]],
  Feet: [['SALON_PEDICURE', 550], ['SALON_WAXING', 400]],
  Nails: [['SALON_MANICURE', 300], ['SALON_PEDICURE', 350]],
};
// Each online menu item is billed as one entry of the price list: menu name -> [service code, item name].
const MENU_LINKS = {
  'Haircut (Women)': ['SALON_HAIRCUT', 'Hair (Women)'],
  'Haircut (Men)': ['SALON_HAIRCUT', 'Hair (Men)'],
  'Hair Wash & Blow-dry': ['SALON_HAIR_WASH', 'Hair (Women)'],
  'Hair Colour': ['SALON_HAIR_COLOR', 'Hair (Women)'],
  'Hair Spa': ['SALON_HAIR_SPA', 'Hair (Women)'],
  'Beard Trim': ['SALON_BEARD_TRIM', 'Beard'],
  Shave: ['SALON_SHAVE', 'Beard'],
  Facial: ['SALON_FACIAL', 'Face'],
  'Clean-up': ['SALON_CLEANUP', 'Face'],
  'Waxing (Full Arms)': ['SALON_WAXING', 'Hands'],
  Threading: ['SALON_THREADING', 'Face'],
  Manicure: ['SALON_MANICURE', 'Hands'],
  Pedicure: ['SALON_PEDICURE', 'Feet'],
  'Party Makeup': ['SALON_PARTY_MAKEUP', 'Face'],
  'Bridal Makeup': ['SALON_BRIDAL_MAKEUP', 'Face'],
};
const slug = (name) => name.toUpperCase().replace(/[^A-Z0-9]+/g, '_').replace(/^_|_$/g, '');

// ── plumbing ────────────────────────────────────────────────────────────────
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
const ok = (r) => r.status >= 200 && r.status < 300;
const why = (r) => JSON.stringify(r.body?.error ?? r.body?.message ?? r.body).slice(0, 300);
const list = (r) => (Array.isArray(r.data) ? r.data : (r.data?.items ?? []));
function must(r, what) {
  if (!ok(r)) throw new Error(`${what} failed: HTTP ${r.status} ${why(r)}`);
  return r.data;
}
const istDate = (days) => new Date(Date.now() + 330 * 60_000 + days * 86_400_000).toISOString().slice(0, 10);

function serverTool(args) {
  const here = dirname(fileURLToPath(import.meta.url));
  const b64 = readFileSync(join(here, 'salon-server-tool.cjs')).toString('base64');
  const script = `cd ~/nexoraa-cleansoft/apps/backend/auth-service && echo ${b64} | base64 -d > .salon-tool.cjs && node .salon-tool.cjs ${args}; rc=$?; rm -f .salon-tool.cjs; exit $rc`;
  const wrapper = `echo ${Buffer.from(script).toString('base64')} | base64 -d > /tmp/salon-tool.sh && sudo -u ubuntu -i bash /tmp/salon-tool.sh; rc=$?; rm -f /tmp/salon-tool.sh; exit $rc`;
  const dir = mkdtempSync(join(tmpdir(), 'salon-'));
  const params = join(dir, 'params.json');
  writeFileSync(params, JSON.stringify({ commands: [wrapper] }));
  const aws = (rest) => execFileSync('aws', ['--region', REGION, ...rest], { encoding: 'utf8', env: { ...process.env, PYTHONIOENCODING: 'utf-8', PYTHONUTF8: '1' } }).trim();
  try {
    const id = aws(['ssm', 'send-command', '--instance-ids', INSTANCE, '--document-name', 'AWS-RunShellScript', '--comment', `salon ${args.split(' ')[0]}`, '--parameters', `file://${params}`, '--query', 'Command.CommandId', '--output', 'text']);
    for (let i = 0; i < 90; i++) {
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

// ── commands ────────────────────────────────────────────────────────────────
async function listCommand() {
  console.log(serverTool(`list ${OWNER_EMAIL}`));
  console.log(`Nothing was deleted. The shop owned by ${OWNER_EMAIL} is kept. To delete everything listed above run:  node scripts/demo/salon-reset.mjs delete --yes`);
}

async function deleteCommand(confirmed) {
  if (!confirmed) {
    console.log('This permanently deletes EVERY salon shop and its data. Run "list" first, then add --yes to confirm.');
    process.exit(1);
  }
  console.log(serverTool(`delete ${OWNER_EMAIL}`));
}

async function ownerLogin() {
  const r = await call('POST', `${API.auth}/auth/login`, { body: { context: 'tenant', identifier: OWNER_EMAIL, password: PASSWORD } });
  if (!ok(r)) return null;
  return { token: r.data.accessToken, tenantId: r.data.tenant?.tenantId, branchId: r.data.branch?.branchId, userId: r.data.user.userId };
}

async function seedShop() {
  console.log(`# Salon owner ${OWNER_EMAIL}`);
  let owner = await ownerLogin();
  if (!owner) {
    must(await call('POST', `${API.tenant}/tenants/register`, {
      body: { businessName: SHOP.name, businessType: 'salon', ownerName: SHOP.ownerName, email: OWNER_EMAIL, mobileNumber: SHOP.phone, password: PASSWORD, agreedToTerms: true },
    }), 'register salon');
    owner = await ownerLogin();
    if (!owner) throw new Error('registered, but the owner cannot sign in (an email code may be required)');
    must(await call('PATCH', `${API.tenant}/tenants/${owner.tenantId}`, {
      token: owner.token,
      body: {
        businessName: SHOP.name, businessType: 'salon', ownerName: SHOP.ownerName, email: OWNER_EMAIL, mobileNumber: SHOP.phone,
        services: ['salon'], staff: [],
        branch: { branchName: SHOP.branch, streetAddress: SHOP.listing.streetAddress, city: SHOP.listing.city, postalCode: SHOP.listing.postalCode, phone: SHOP.phone, email: OWNER_EMAIL },
      },
    }), 'onboard salon');
    owner = await ownerLogin(); // the token now carries the branch
    console.log('  + salon created and onboarded');
  } else {
    console.log('  = salon already exists');
  }
  // A listing the owner already saved (address, hours, modes) is left exactly as it is.
  const current = await call('GET', `${API.market}/shop-listing/me`, { token: owner.token, branchId: owner.branchId });
  if (ok(current) && current.data.saved && current.data.isComplete) {
    console.log('  = marketplace listing already complete, kept as is');
  } else {
    must(await call('PUT', `${API.market}/shop-listing/me`, { token: owner.token, branchId: owner.branchId, body: { ...SHOP.listing, isListed: true } }), 'listing');
    console.log('  + marketplace listing saved (Hadapsar, Pune)');
  }

  const ctx = { token: owner.token, branchId: owner.branchId };
  const { services, items } = await ensureCatalog(ctx);
  const link = (name) => {
    const [serviceCode, itemName] = MENU_LINKS[name] ?? [];
    const catalogServiceId = services.get(serviceCode);
    const catalogItemCategoryId = items.get(String(itemName).toLowerCase())?.id;
    return catalogServiceId && catalogItemCategoryId ? { catalogServiceId, catalogItemCategoryId } : {};
  };
  const config = must(await call('PUT', `${API.market}/shop/salon/config`, {
    ...ctx,
    body: {
      slotMinutes: SLOT_MINUTES,
      staff: TEAM.map(([name, role]) => ({ name, role })),
      menu: MENU.map(([name, price, durationMinutes, role]) => ({ name, price, durationMinutes, role, ...link(name) })),
    },
  }), 'salon team and menu');
  console.log(`  + team of ${config.staff.length} and a menu of ${config.menu.length} services (${SLOT_MINUTES}-minute slots)`);
  return { owner, ctx, config };
}

async function seedPeople(owner, ctx) {
  console.log('# Walk-in customers and staff logins');
  const known = new Set(list(await call('GET', `${API.customers}/customers?limit=100`, ctx)).map((c) => String(c.mobile ?? '').replace(/\D/g, '').slice(-10)));
  let added = 0;
  for (const [name, mobile] of WALK_INS) {
    if (known.has(mobile)) continue;
    must(await call('POST', `${API.customers}/customers`, { ...ctx, body: { name, mobile: `+91${mobile}`, customerType: 'Regular' } }), `customer ${name}`);
    added++;
  }
  console.log(`  + ${added} walk-in customers`);
  for (const member of STAFF_LOGINS) {
    const login = await call('POST', `${API.auth}/auth/login`, { body: { context: 'tenant', identifier: member.loginId, password: PASSWORD } });
    if (ok(login)) { console.log(`  = ${member.name} already exists`); continue; }
    must(await call('POST', `${API.users}/users/tenant/${owner.tenantId}/register`, {
      ...ctx, body: { name: member.name, loginId: member.loginId, password: PASSWORD, role: member.role, branchIds: [owner.branchId], sendInvite: false },
    }), `staff ${member.name}`);
    console.log(`  + ${member.name} (${member.role})`);
  }
}

async function seedCustomer() {
  console.log('# Marketplace customer');
  const signIn = () => call('POST', `${API.auth}/auth/login`, { body: { context: 'consumer', identifier: CUSTOMER_EMAIL, password: PASSWORD } });
  let login = await signIn();
  if (!ok(login)) {
    const register = await call('POST', `${API.auth}/auth/consumer/register`, {
      body: { fullName: 'Isha Verma', email: CUSTOMER_EMAIL, mobileNumber: CUSTOMER_MOBILE, password: PASSWORD },
    });
    if (!ok(register)) console.log(`  register: ${why(register)}`);
    console.log(`  ${serverTool(`verify ${CUSTOMER_EMAIL}`).trim()} (email marked verified on the server)`);
    login = await signIn();
  }
  if (!ok(login)) throw new Error(`the customer cannot sign in: ${why(login)}`);
  const token = login.data.accessToken;
  if (list(await call('GET', `${API.market}/consumer/addresses`, { token })).length === 0) {
    must(await call('POST', `${API.market}/consumer/addresses`, {
      token,
      body: { label: 'Home', houseFlat: 'Flat 204, Sai Heights', streetArea: 'Hadapsar, Pune', landmark: 'Near Seasons Mall', city: 'Pune', state: 'Maharashtra', pincode: '411028', latitude: 18.5097, longitude: 73.9272 },
    }), 'customer address');
  }
  console.log('  + customer ready with a saved Home address');
  return token;
}

/** A few bookings tomorrow so the app shows Booked and Pending slots, then print what the customer sees. */
async function seedBookings(shop, customerToken) {
  console.log('# Bookings (tomorrow)');
  const date = istDate(1);
  const byName = Object.fromEntries(shop.config.menu.map((item) => [item.name, item.serviceId]));
  const book = async (names, start, mode = 'visit_shop') => {
    const request = await call('POST', `${API.market}/consumer/requests`, {
      token: customerToken,
      body: {
        shopId: shop.owner.branchId, category: 'salon', requestType: mode, description: `Salon: ${names.join(', ')}`,
        preferredDate: date, preferredSlot: { start, end: start }, salonServiceIds: names.map((n) => byName[n]),
      },
    });
    if (!ok(request)) { console.log(`  ! ${names.join(' + ')} at ${start}: ${why(request)}`); return null; }
    console.log(`  + ${request.data.requestNumber}: ${names.join(' + ')} at ${start} (Pending)`);
    return request.data;
  };
  const first = await book(['Haircut (Women)', 'Facial'], '11:00');
  if (first) {
    must(await call('POST', `${API.market}/shop/requests/${first.requestId}/accept`, { ...shop.ctx, body: {} }), 'accept booking');
    console.log('  + accepted by the owner (shows as Booked)');
  }
  await book(['Party Makeup'], '14:00');

  const slots = await call('GET', `${API.market}/marketplace/salons/${shop.owner.branchId}/slots?date=${date}&serviceIds=${byName['Haircut (Women)']},${byName['Facial']}`, { token: customerToken });
  if (ok(slots)) {
    const states = list({ data: slots.data.slots }).map((s) => `${s.start} ${s.state}`);
    console.log(`  customer's view of Haircut (Women) + Facial tomorrow:\n    ${states.join('\n    ')}`);
  }
}

/** The shop's own items, services and prices (for walk-in orders on the New Order screen). */
async function catalogCommand() {
  const owner = await ownerLogin();
  if (!owner) throw new Error(`${OWNER_EMAIL} cannot sign in`);
  await ensureCatalog({ token: owner.token, branchId: owner.branchId });
}

async function ensureCatalog(ctx) {
  console.log('# Services, items and prices');
  const services = new Map(list(await call('GET', `${API.catalog}/services?limit=100`, ctx)).map((x) => [x.code, x.id]));
  let newServices = 0;
  for (const [name, code, minutes] of EXTRA_SERVICES) {
    if (services.has(code)) continue;
    const created = must(await call('POST', `${API.catalog}/services`, { ...ctx, body: { name, code, pricingType: 'PerItem', estimatedTimeMins: minutes } }), `service ${name}`);
    services.set(code, created.id);
    newServices++;
  }
  const items = new Map(list(await call('GET', `${API.catalog}/item-categories?limit=100`, ctx)).map((x) => [x.name.toLowerCase(), x]));
  let newItems = 0;
  for (const [name, group, unitType] of CATALOG_ITEMS) {
    if (items.has(name.toLowerCase())) continue;
    items.set(name.toLowerCase(), must(await call('POST', `${API.catalog}/item-categories`, { ...ctx, body: { name, code: `SALON_${slug(name)}`, category: group.toUpperCase(), unitType } }), `item ${name}`));
    newItems++;
  }
  const effectiveFrom = new Date(Date.now() - 60_000).toISOString();
  let prices = 0;
  for (const [itemName, offers] of Object.entries(PRICES)) {
    const item = items.get(itemName.toLowerCase());
    for (const [serviceCode, price] of offers) {
      const serviceId = services.get(serviceCode);
      if (!serviceId) throw new Error(`service ${serviceCode} is missing`);
      const mapping = await call('POST', `${API.catalog}/service-mappings`, { ...ctx, body: { itemCategoryId: item.id, serviceId } });
      if (!ok(mapping) && mapping.status !== 409) throw new Error(`mapping ${itemName}/${serviceCode} failed: ${why(mapping)}`);
      const priced = await call('POST', `${API.catalog}/services/${serviceId}/pricing`, { ...ctx, body: { itemCategoryId: item.id, basePrice: price, taxPct: 0, effectiveFrom } });
      if (ok(priced)) prices++;
      else if (priced.status !== 409) throw new Error(`price ${itemName}/${serviceCode} failed: ${why(priced)}`);
    }
  }
  console.log(`  + ${newServices} new services, ${newItems} new items, ${prices} new prices`);
  console.log(`  the salon now has ${services.size} services and ${items.size} items`);
  return { services, items };
}

/** Everything on the shop side, with no server step: team, menu, walk-in customers and staff logins. */
async function shopOnlyCommand() {
  const shop = await seedShop();
  await seedPeople(shop.owner, shop.ctx);
  console.log(`
# Logins (password for all: ${PASSWORD})
  Salon owner ("I run a business") ${OWNER_EMAIL}
  Branch manager (shop login)      ${MANAGER_ID}
  Staff (shop login)               ${STAFF_ID}`);
}

async function seedCommand() {
  const shop = await seedShop();
  await seedPeople(shop.owner, shop.ctx);
  const token = await seedCustomer();
  await seedBookings(shop, token);
  console.log(`
# Logins (password for all: ${PASSWORD})
  Salon owner ("I run a business") ${OWNER_EMAIL}
  Branch manager (shop login)      ${MANAGER_ID}
  Staff (shop login)               ${STAFF_ID}
  Customer ("I need a service")    ${CUSTOMER_EMAIL}  /  ${CUSTOMER_MOBILE}`);
}

const [command, flag] = process.argv.slice(2);
const commands = { list: listCommand, delete: () => deleteCommand(flag === '--yes'), seed: seedCommand, 'seed-shop': shopOnlyCommand, catalog: catalogCommand };
if (!commands[command]) {
  console.log('usage: node scripts/demo/salon-reset.mjs list | delete --yes | seed | seed-shop | catalog');
  process.exit(1);
}
commands[command]().catch((error) => {
  console.error('FAILED:', error.message);
  process.exit(1);
});
