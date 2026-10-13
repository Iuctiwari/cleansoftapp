#!/usr/bin/env node
// Seeds ONE real-looking laundry business on the live server, through the same APIs the app uses:
// the shop owner, a full price list (~50 items), walk-in customers, workers with different
// module access, and the marketplace listing. It creates NO orders.
//
//   node scripts/demo/seed-laundry.mjs shop        owner + onboarding + listing
//   node scripts/demo/seed-laundry.mjs catalog     items + prices
//   node scripts/demo/seed-laundry.mjs people      walk-in customers + staff with module access
//   node scripts/demo/seed-laundry.mjs customer    the marketplace customer (sends an email code)
//   node scripts/demo/seed-laundry.mjs inspect     show what is there
//
// Safe to run again: it logs in when something already exists instead of creating it twice.
const DOMAIN = process.env.DEMO_DOMAIN ?? '65-1-66-219.sslip.io';
const PASSWORD = process.env.SEED_PASSWORD;
if (!PASSWORD) {
  console.error('Set SEED_PASSWORD to the password to give every seeded account.');
  process.exit(1);
}

const OWNER_EMAIL = 'ayushikrishna1199@gmail.com';
const CUSTOMER_EMAIL = 'iuckrishna1516@gmail.com';

const API = {
  auth: `https://auth.${DOMAIN}/api/v1`,
  tenant: `https://tenant.${DOMAIN}/api/v1`,
  market: `https://market.${DOMAIN}/api/v1`,
  customers: `https://customer.${DOMAIN}`,
  catalog: `https://catalog.${DOMAIN}/api/v1`,
  expenses: `https://expense.${DOMAIN}`, // this service has no /api prefix
  users: `https://user.${DOMAIN}/api/v1`,
};

const SHOP = {
  name: 'Nexoraa Laundry',
  ownerName: 'Ayushi Krishna',
  phone: '9876500011',
  branch: 'Hadapsar',
  listing: {
    streetAddress: 'Shop 12, Magarpatta Road',
    area: 'Hadapsar',
    landmark: 'Near Seasons Mall',
    city: 'Pune',
    state: 'Maharashtra',
    postalCode: '411028',
    latitude: 18.5089,
    longitude: 73.9259,
    bookingPhone: '020 2681 0011',
    serviceModes: ['visit_shop', 'home_service', 'pickup_drop'],
    serviceRadiusKm: 8,
    openingHours: [0, 1, 2, 3, 4, 5, 6].map((day) => ({ day, closed: false, open: '08:00', close: '21:00' })),
    about: 'Wash, iron and dry cleaning. Free pickup and drop on orders above ₹300.',
  },
};

// Workers sign in with a login ID (these are not real mailboxes, so no email code is involved).
const STAFF = [
  { loginId: 'abc@gmail.com', name: 'Abhay Chavan', role: 'Staff', access: 'default', note: 'pickup worker, standard Staff access' },
  { loginId: 'def@gmail.com', name: 'Deepak Shinde', role: 'Staff', access: 'default', note: 'second pickup worker, standard Staff access' },
  {
    loginId: 'xyz@gmail.com', name: 'Suresh Patil', role: 'Staff', access: 'custom',
    permissions: ['orders:read', 'orders:write', 'customers:read', 'customers:write', 'payments:read', 'payments:write'],
    note: 'front desk: orders, customers and payments',
  },
  {
    loginId: 'pqr@gmail.com', name: 'Priya Rane', role: 'Staff', access: 'custom',
    permissions: ['orders:read', 'reports:read'],
    note: 'view only: can see orders and reports, cannot change anything',
  },
  { loginId: 'lmn@gmail.com', name: 'Meena Nair', role: 'Branch Manager', access: 'default', note: 'branch manager' },
];

const WALK_INS = [
  ['Rohan Deshmukh', '9811100001'], ['Kavita Joshi', '9811100002'], ['Sameer Khan', '9811100003'],
  ['Anjali Kulkarni', '9811100004'], ['Vikram Bhosale', '9811100005'], ['Pooja Jadhav', '9811100006'],
  ['Nikhil Pawar', '9811100007'], ['Sneha Gaikwad', '9811100008'], ['Rahul More', '9811100009'],
  ['Divya Salunkhe', '9811100010'], ['Amol Kale', '9811100011'], ['Ritu Agarwal', '9811100012'],
];

// (item, group, dry-clean price, wash+iron price, iron-only price) — null = not offered that way.
const ITEMS = [
  ['Shirt', 'Men', 60, 40, 15], ['T-Shirt', 'Men', 50, 35, 12], ['Trousers', 'Men', 80, 50, 20], ['Jeans', 'Men', 90, 60, 20],
  ['Kurta', 'Men', 90, 55, 20], ['Pyjama', 'Men', 60, 35, 15], ['Shorts', 'Men', 50, 30, 12], ['Track Pant', 'Men', 60, 35, 15],
  ['Suit (2 piece)', 'Men', 350, null, 80], ['Blazer', 'Men', 220, null, 50], ['Waistcoat', 'Men', 130, null, 30], ['Sherwani', 'Men', 450, null, 90],
  ['Dhoti', 'Men', 70, 40, 20], ['Jacket', 'Men', 180, null, 40], ['Sweater', 'Men', 120, 80, 25], ['Tie', 'Men', 40, null, 10],
  ['Saree (plain)', 'Women', 160, 90, 40], ['Saree (silk / heavy)', 'Women', 280, null, 60], ['Blouse', 'Women', 60, 35, 15], ['Salwar Kameez', 'Women', 170, 100, 35],
  ['Kurti', 'Women', 70, 45, 15], ['Leggings', 'Women', 40, 25, 10], ['Dupatta', 'Women', 60, 35, 15], ['Lehenga', 'Women', 600, null, 120],
  ['Gown / Evening Dress', 'Women', 380, null, 80], ['One Piece / Dress', 'Women', 150, 90, 30], ['Skirt', 'Women', 80, 50, 20], ['Shawl', 'Women', 140, null, 30],
  ['Bedsheet (single)', 'Home', 120, 70, 30], ['Bedsheet (double)', 'Home', 180, 100, 40], ['Pillow Cover', 'Home', 30, 20, 8], ['Blanket (single)', 'Home', 250, null, null],
  ['Blanket (double)', 'Home', 380, null, null], ['Quilt / Razai', 'Home', 400, null, null], ['Comforter', 'Home', 450, null, null], ['Curtain (per panel)', 'Home', 140, 90, 30],
  ['Sofa Cover', 'Home', 200, null, null], ['Table Cloth', 'Home', 90, 55, 20], ['Towel (bath)', 'Home', 50, 30, 10], ['Carpet (per sq ft)', 'Home', 25, null, null],
  ['Cushion Cover', 'Home', 40, 25, 10], ['Mattress Cover', 'Home', 220, null, null],
  ['Baby Clothes (set)', 'Kids', 60, 40, 15], ['School Uniform (set)', 'Kids', 90, 60, 25], ['Kids Jacket', 'Kids', 120, null, 25],
  ['Soft Toy', 'Other', 150, null, null], ['Leather Jacket', 'Other', 700, null, null], ['Sports Shoes', 'Other', 220, null, null],
  ['Backpack', 'Other', 260, null, null], ['Umbrella', 'Other', 120, null, null],
];

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
const why = (r) => JSON.stringify(r.body?.error ?? r.body?.message ?? r.body).slice(0, 200);
const list = (r) => (Array.isArray(r.data) ? r.data : (r.data?.items ?? []));
function must(r, what) {
  if (!ok(r)) throw new Error(`${what} failed: HTTP ${r.status} ${why(r)}`);
  return r.data;
}

async function ownerLogin() {
  const r = await call('POST', `${API.auth}/auth/login`, { body: { context: 'tenant', identifier: OWNER_EMAIL, password: PASSWORD } });
  if (!ok(r)) return null;
  return { token: r.data.accessToken, tenantId: r.data.tenant?.tenantId, branchId: r.data.branch?.branchId, userId: r.data.user.userId };
}

async function shop() {
  console.log(`# Shop owner ${OWNER_EMAIL}`);
  let owner = await ownerLogin();
  if (!owner) {
    must(await call('POST', `${API.tenant}/tenants/register`, {
      body: { businessName: SHOP.name, businessType: 'laundry', ownerName: SHOP.ownerName, email: OWNER_EMAIL, mobileNumber: SHOP.phone, password: PASSWORD, agreedToTerms: true },
    }), 'register shop');
    owner = await ownerLogin();
    if (!owner) throw new Error('registered, but the owner cannot sign in (an email code may be required)');
    must(await call('PATCH', `${API.tenant}/tenants/${owner.tenantId}`, {
      token: owner.token,
      body: {
        businessName: SHOP.name, businessType: 'laundry', ownerName: SHOP.ownerName, email: OWNER_EMAIL, mobileNumber: SHOP.phone,
        services: ['laundry', 'dry_cleaning'], staff: [],
        branch: { branchName: SHOP.branch, streetAddress: SHOP.listing.streetAddress, city: SHOP.listing.city, postalCode: SHOP.listing.postalCode, phone: SHOP.phone, email: OWNER_EMAIL },
      },
    }), 'onboard shop');
    owner = await ownerLogin(); // the token now carries the branch
    console.log('  + shop created and onboarded');
  } else {
    console.log('  = shop already exists');
  }
  must(await call('PUT', `${API.market}/shop-listing/me`, { token: owner.token, body: { ...SHOP.listing, isListed: true } }), 'listing');
  console.log('  + marketplace listing saved (Hadapsar, Pune)');
  return owner;
}

// Already created by the shop's onboarding template (they keep the template's prices).
const ALREADY_THERE = new Set(['Shirt', 'Trousers', 'Jacket', 'Suit (2 piece)', 'Curtain (per panel)', 'Carpet (per sq ft)', 'Sports Shoes']);
const slug = (name) => name.toUpperCase().replace(/[^A-Z0-9]+/g, '_').replace(/^_|_$/g, '');
const round = (value, step) => Math.round(value / step) * step;

async function catalog() {
  const owner = await ownerLogin();
  if (!owner) throw new Error('owner cannot sign in; run "shop" first');
  const ctx = { token: owner.token, branchId: owner.branchId };
  const services = Object.fromEntries(list(await call('GET', `${API.catalog}/services`, ctx)).map((x) => [x.code, x.id]));
  const have = new Map(list(await call('GET', `${API.catalog}/item-categories`, ctx)).map((x) => [x.name.toLowerCase(), x]));
  const effectiveFrom = new Date(Date.now() - 60_000).toISOString();
  let created = 0;
  let prices = 0;
  for (const [name, group, dry, wash, iron] of ITEMS) {
    if (ALREADY_THERE.has(name)) continue;
    let item = have.get(name.toLowerCase());
    if (!item) {
      item = must(await call('POST', `${API.catalog}/item-categories`, { ...ctx, body: { name, code: `ITEM_${slug(name)}`, category: group.toUpperCase(), unitType: 'Piece' } }), `item ${name}`);
      created++;
    }
    const offers = [
      ['SERVICE_DRY_CLEANING', dry],
      ['SERVICE_WASH_FOLD', wash],
      ['SERVICE_IRONING', iron],
      ['SERVICE_PREMIUM_CLEANING', dry !== null && dry >= 150 ? round(dry * 1.5, 10) : null],
      ['SERVICE_WASH_ONLY', wash !== null ? round(wash * 0.7, 5) : null],
    ];
    for (const [serviceCode, price] of offers) {
      if (price === null || !services[serviceCode]) continue;
      const mapping = await call('POST', `${API.catalog}/service-mappings`, { ...ctx, body: { itemCategoryId: item.id, serviceId: services[serviceCode] } });
      if (!ok(mapping) && mapping.status !== 409) throw new Error(`mapping ${name}/${serviceCode} failed: ${why(mapping)}`);
      const priced = await call('POST', `${API.catalog}/services/${services[serviceCode]}/pricing`, { ...ctx, body: { itemCategoryId: item.id, basePrice: price, taxPct: 0, effectiveFrom } });
      if (ok(priced)) prices++;
      else if (priced.status !== 409) throw new Error(`price ${name}/${serviceCode} failed: ${why(priced)}`);
    }
  }
  const items = list(await call('GET', `${API.catalog}/item-categories`, ctx));
  console.log(`  + ${created} new items, ${prices} new prices. The shop now has ${items.length} items.`);
}

async function staffLogin(loginId) {
  const r = await call('POST', `${API.auth}/auth/login`, { body: { context: 'tenant', identifier: loginId, password: PASSWORD } });
  return ok(r) ? r.data : null;
}

async function people() {
  const owner = await ownerLogin();
  if (!owner) throw new Error('owner cannot sign in; run "shop" first');
  const ctx = { token: owner.token, branchId: owner.branchId };

  console.log('# Walk-in customers (the shop\'s own customer list)');
  const existing = list(await call('GET', `${API.customers}/customers?limit=100`, ctx));
  const known = new Set(existing.map((c) => String(c.mobile ?? '').replace(/\D/g, '').slice(-10)));
  let added = 0;
  for (const [name, mobile] of WALK_INS) {
    if (known.has(mobile)) continue;
    must(await call('POST', `${API.customers}/customers`, { ...ctx, body: { name, mobile: `+91${mobile}`, customerType: 'Regular' } }), `customer ${name}`);
    added++;
  }
  console.log(`  + ${added} customers added (${WALK_INS.length} total)`);

  console.log('# Staff and their module access');
  for (const member of STAFF) {
    let userId;
    if (await staffLogin(member.loginId)) {
      const users = list(await call('GET', `${API.users}/users/tenant/${owner.tenantId}`, ctx));
      userId = users.find((u) => (u.loginId ?? '').toLowerCase() === member.loginId)?.userId;
      console.log(`  = ${member.name} already exists`);
    } else {
      const created = must(await call('POST', `${API.users}/users/tenant/${owner.tenantId}/register`, {
        ...ctx, body: { name: member.name, loginId: member.loginId, password: PASSWORD, role: member.role, branchIds: [owner.branchId], sendInvite: false },
      }), `staff ${member.name}`);
      userId = created.userId;
      console.log(`  + ${member.name} (${member.role}) — ${member.note}`);
    }
    if (member.access === 'custom' && userId) {
      must(await call('PATCH', `${API.users}/users/${userId}`, { ...ctx, body: { accessMode: 'custom', permissions: member.permissions } }), `access ${member.name}`);
      console.log(`      custom access: ${member.permissions.join(', ')}`);
    }
  }
}

// The marketplace customer ("I need a service"). A new sign-up emails a 6-digit code to a real inbox,
// so an account that already exists (and can sign in) is used as is: nothing is emailed again.
async function customer() {
  const signIn = () => call('POST', `${API.auth}/auth/login`, { body: { context: 'consumer', identifier: CUSTOMER_EMAIL, password: PASSWORD } });
  let login = await signIn();
  if (!ok(login) && login.body?.error?.code !== 'auth.email_not_verified') {
    const register = await call('POST', `${API.auth}/auth/consumer/register`, {
      body: { fullName: 'Iuc Krishna', email: CUSTOMER_EMAIL, mobileNumber: '9811200001', password: PASSWORD },
    });
    console.log(ok(register) ? `  + registered; a verification code was emailed to ${CUSTOMER_EMAIL}` : `  customer: ${why(register)}`);
    login = await signIn();
  }
  if (!ok(login)) {
    console.log(`  customer cannot sign in yet (${login.body?.error?.code ?? login.status}): the email is not verified`);
    return;
  }
  const token = login.data.accessToken;
  const have = list(await call('GET', `${API.market}/consumer/addresses`, { token }));
  const wanted = [
    { label: 'Home', houseFlat: 'Flat 204, Sai Heights', streetArea: 'Hadapsar, Pune', landmark: 'Near Seasons Mall', city: 'Pune', state: 'Maharashtra', pincode: '411028', latitude: 18.5097, longitude: 73.9272 },
    { label: 'Work', houseFlat: '3rd floor, Tech Park One', streetArea: 'Kharadi, Pune', landmark: 'Near EON IT Park', city: 'Pune', state: 'Maharashtra', pincode: '411014', latitude: 18.5522, longitude: 73.9487 },
    { label: 'Other', houseFlat: 'B-7, Gulmohar Society', streetArea: 'Magarpatta City, Hadapsar', city: 'Pune', state: 'Maharashtra', pincode: '411013', latitude: 18.5149, longitude: 73.9275 },
  ];
  let added = 0;
  for (const address of wanted) {
    if (have.some((a) => a.label === address.label)) continue;
    must(await call('POST', `${API.market}/consumer/addresses`, { token, body: address }), `address ${address.label}`);
    added++;
  }
  console.log(`  + ${added} addresses added (${have.length + added} saved)`);
  const shops = list(await call('GET', `${API.market}/marketplace/shops?latitude=18.5097&longitude=73.9272`, { token }));
  console.log(`  nearby shops she can see: ${shops.length}${shops[0] ? ` (first: ${shops[0].shopName})` : ''}`);
}

// (category keyword, amount, method, vendor, what, days ago)
const EXPENSES = [
  [/rent/i, 18000, 'BankTransfer', 'Magarpatta Estates', 'Shop rent for the month', 24],
  [/electric|utilit/i, 4650, 'UPI', 'MSEDCL', 'Electricity bill', 20],
  [/water/i, 900, 'Cash', 'Pune Municipal Corporation', 'Water charges', 20],
  [/detergent|material|supply/i, 3200, 'UPI', 'CleanChem Traders', 'Detergent, softener and stain remover', 18],
  [/detergent|material|supply/i, 1450, 'Cash', 'Shree Packaging', 'Hangers, polythene covers and tags', 15],
  [/salary|wage|staff/i, 12000, 'BankTransfer', 'Staff payroll', 'Salary: Abhay Chavan', 12],
  [/salary|wage|staff/i, 12000, 'BankTransfer', 'Staff payroll', 'Salary: Deepak Shinde', 12],
  [/salary|wage|staff/i, 15000, 'BankTransfer', 'Staff payroll', 'Salary: Suresh Patil', 12],
  [/transport|fuel|delivery/i, 1800, 'Cash', 'HP Petrol Pump', 'Fuel for the pickup and delivery scooter', 9],
  [/maint|repair/i, 2600, 'UPI', 'Kumar Machine Works', 'Washing machine drum bearing repair', 7],
  [/maint|repair/i, 850, 'Cash', 'Local Electrician', 'Iron table and steam iron fix', 5],
  [/market|advert|promo/i, 1500, 'UPI', 'Print Point', 'Flyers for Hadapsar housing societies', 4],
  [/misc|other|general/i, 600, 'Cash', 'Tea & snacks', 'Refreshments for staff', 2],
  [/detergent|material|supply/i, 2100, 'UPI', 'CleanChem Traders', 'Dry-cleaning solvent refill', 1],
];

async function expenses() {
  const owner = await ownerLogin();
  if (!owner) throw new Error('owner cannot sign in; run "shop" first');
  const ctx = { token: owner.token, branchId: owner.branchId };
  const categories = list(await call('GET', `${API.expenses}/expense-categories`, ctx));
  if (categories.length === 0) throw new Error('the shop has no expense categories');
  const existing = list(await call('GET', `${API.expenses}/expenses?limit=100`, ctx));
  if (existing.length >= EXPENSES.length) return console.log(`  = ${existing.length} expenses already recorded`);
  let added = 0;
  for (const [pattern, amount, paymentMethod, vendor, description, daysAgo] of EXPENSES) {
    const category = categories.find((c) => pattern.test(c.categoryName)) ?? categories[0];
    must(await call('POST', `${API.expenses}/expenses`, {
      ...ctx,
      body: { expenseCategoryId: category.id, amount, paymentMethod, vendor, description, expenseDate: new Date(Date.now() - daysAgo * 86_400_000).toISOString() },
    }), `expense ${description}`);
    added++;
  }
  console.log(`  + ${added} expenses recorded (categories: ${categories.map((c) => c.categoryName).join(', ')})`);
}

async function inspect() {
  const owner = await ownerLogin();
  if (!owner) return console.log('owner cannot sign in yet');
  const services = list(await call('GET', `${API.catalog}/services`, { token: owner.token, branchId: owner.branchId }));
  const items = list(await call('GET', `${API.catalog}/item-categories`, { token: owner.token, branchId: owner.branchId }));
  console.log(`services (${services.length}):`);
  for (const s of services) console.log(`  ${s.id}  ${s.code}  ${s.name ?? s.serviceName}  [${s.pricingType}]`);
  console.log(`items (${items.length}):`);
  console.log('  ' + items.map((i) => i.name).join(', '));
}

const command = process.argv[2];
const commands = { shop, catalog, people, customer, expenses, inspect };
if (!commands[command]) {
  console.log('usage: node scripts/demo/seed-laundry.mjs shop|catalog|people|customer|inspect');
  process.exit(1);
}
commands[command]().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });
