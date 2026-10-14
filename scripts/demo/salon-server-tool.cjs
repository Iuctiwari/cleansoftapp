// Runs ON THE SERVER (uploaded by salon-reset.mjs through AWS SSM).
//
//   node salon-server-tool.cjs list                     dry run: every salon shop and what would be deleted
//   node salon-server-tool.cjs delete                   delete EVERY salon shop (businessType "salon") and all its data
//   node salon-server-tool.cjs verify a@x.com,b@x.com   mark these marketplace customers' emails as verified
//
// "Salon shop" means a tenant whose business type is salon. Other businesses are never touched.
// Marketplace customer accounts are kept; only their bookings at salon shops are removed.
// The security audit log is kept on purpose.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const mongoose = require('mongoose');

const ENV_DIR = path.join(os.homedir(), 'nexoraa-env');
const uris = [
  ...new Set(
    fs
      .readdirSync(ENV_DIR)
      .filter((file) => file.endsWith('.env'))
      .flatMap((file) => fs.readFileSync(path.join(ENV_DIR, file), 'utf8').split('\n'))
      .filter((line) => line.startsWith('MONGODB_URI='))
      .map((line) => line.slice('MONGODB_URI='.length).trim()),
  ),
];
const dbName = (uri) => new URL(uri.replace(/^mongodb(\+srv)?:\/\//, 'http://')).pathname.slice(1);

async function eachDb(fn) {
  for (const uri of uris) {
    const conn = await mongoose.createConnection(uri).asPromise();
    try {
      await fn(conn.db, dbName(uri));
    } finally {
      await conn.close();
    }
  }
}

async function verify(emails) {
  const list = emails.split(',').map((email) => email.trim().toLowerCase()).filter(Boolean);
  if (list.length === 0) throw new Error('give at least one email');
  let verified = 0;
  await eachDb(async (db) => {
    const r = await db.collection('consumerAccounts').updateMany(
      { email: { $in: list }, emailVerified: false },
      {
        $set: { emailVerified: true, emailVerifiedAtUtc: new Date().toISOString() },
        $unset: { verificationOtpHash: '', verificationExpiresAtUtc: '' },
      },
    );
    verified += r.modifiedCount;
  });
  console.log(`verified=${verified}`);
}

async function salonReset(doDelete) {
  // 1. Find every salon shop, then everyone who works there.
  const shops = new Map();
  await eachDb(async (db) => {
    for (const t of await db
      .collection('tenants')
      .find({ businessType: 'salon' }, { projection: { tenantId: 1, businessName: 1, ownerEmail: 1 } })
      .toArray()) {
      shops.set(t.tenantId, `${t.businessName} (${t.ownerEmail})`);
    }
  });
  const tenantIds = [...shops.keys()];
  console.log(`salon shops found: ${tenantIds.length}`);
  for (const [id, label] of shops) console.log(`  - ${label}  [${id}]`);
  if (tenantIds.length === 0) return;

  const userIds = new Set();
  await eachDb(async (db) => {
    for (const o of await db.collection('tenantOwners').find({ tenantId: { $in: tenantIds } }, { projection: { userId: 1 } }).toArray()) {
      userIds.add(o.userId);
    }
    for (const s of await db.collection('tenantStaff').find({ tenantId: { $in: tenantIds } }, { projection: { userId: 1 } }).toArray()) {
      userIds.add(s.userId);
    }
  });
  console.log(`people with a shop login (owner + staff): ${userIds.size}`);

  const isId = (id) => mongoose.Types.ObjectId.isValid(id);
  const tenantValues = [...tenantIds, ...tenantIds.filter(isId).map((id) => new mongoose.Types.ObjectId(id))];
  const userValues = [...userIds, ...[...userIds].filter(isId).map((id) => new mongoose.Types.ObjectId(id))];

  // 2. Count (or delete) everything that belongs to them.
  let total = 0;
  await eachDb(async (db, name) => {
    for (const { name: collection } of await db.listCollections().toArray()) {
      if (/audit/i.test(collection) || collection.startsWith('system.')) continue;
      const or = [{ tenantId: { $in: tenantValues } }];
      if (userValues.length) or.push({ userId: { $in: userValues } });
      if (collection === 'users' && userValues.length) or.push({ _id: { $in: userValues } });
      const filter = { $or: or };
      const count = await db.collection(collection).countDocuments(filter);
      if (!count) continue;
      total += count;
      if (doDelete) {
        const r = await db.collection(collection).deleteMany(filter);
        console.log(`${name}.${collection}: deleted ${r.deletedCount}`);
      } else {
        console.log(`${name}.${collection}: would delete ${count}`);
      }
    }
  });
  console.log(`${doDelete ? 'deleted' : 'would delete'} ${total} records in total`);
}

async function main() {
  const [command, arg] = process.argv.slice(2);
  if (command === 'list') return salonReset(false);
  if (command === 'delete') return salonReset(true);
  if (command === 'verify') return verify(arg ?? '');
  throw new Error('usage: list | delete | verify <emails>');
}

main().catch((error) => {
  console.error('ERROR', error.message);
  process.exit(1);
});
