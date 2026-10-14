#!/usr/bin/env node
// Salon reset: remove every salon shop from the live server, then fill one complete demo salon
// (team with roles, service menu, staff logins, customers, a few bookings) through the same APIs the app uses.
//
//   node scripts/demo/salon-reset.mjs list            dry run: shows every salon shop and what would be deleted
//   node scripts/demo/salon-reset.mjs delete --yes    DELETE every salon shop and all its data (cannot be undone)
//   node scripts/demo/salon-reset.mjs seed            create the demo salon and print the logins
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

const OWNER_EMAIL = 'qwert@gmail.com';
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
  console.log(serverTool('list'));
  console.log('Nothing was deleted. To delete all of the above run:  node scripts/demo/salon-reset.mjs delete --yes');
}

async function deleteCommand(confirmed) {
  if (!confirmed) {
    console.log('This permanently deletes EVERY salon shop and its data. Run "list" first, then add --yes to confirm.');
    process.exit(1);
  }
  console.log(serverTool('delete'));
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
  must(await call('PUT', `${API.market}/shop-listing/me`, { token: owner.token, body: { ...SHOP.listing, isListed: true } }), 'listing');
  console.log('  + marketplace listing saved (Hadapsar, Pune)');

  const ctx = { token: owner.token, branchId: owner.branchId };
  const config = must(await call('PUT', `${API.market}/shop/salon/config`, {
    ...ctx,
    body: {
      slotMinutes: SLOT_MINUTES,
      staff: TEAM.map(([name, role]) => ({ name, role })),
      menu: MENU.map(([name, price, durationMinutes, role]) => ({ name, price, durationMinutes, role })),
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
const commands = { list: listCommand, delete: () => deleteCommand(flag === '--yes'), seed: seedCommand };
if (!commands[command]) {
  console.log('usage: node scripts/demo/salon-reset.mjs list | delete --yes | seed');
  process.exit(1);
}
commands[command]().catch((error) => {
  console.error('FAILED:', error.message);
  process.exit(1);
});
