// Runs ON THE SERVER (uploaded by marketplace-demo.mjs through AWS SSM).
// Only ever touches demo records: accounts whose email matches the demo
// pattern, and the shops (tenants) owned by them.
//
//   node server-tool.cjs verify  <emailPattern>            mark demo customers' emails verified
//   node server-tool.cjs cleanup <emailPattern> [--delete] list (dry run) or delete all demo data
//
// <emailPattern> is a regular expression and must contain "demo".
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

async function main() {
  const [command, pattern, flag] = process.argv.slice(2);
  if (!pattern || !/demo/i.test(pattern)) throw new Error('the email pattern must contain "demo"');
  const emailRe = new RegExp(pattern, 'i');

  if (command === 'verify') {
    let verified = 0;
    await eachDb(async (db) => {
      const r = await db.collection('consumerAccounts').updateMany(
        { email: emailRe, emailVerified: false },
        {
          $set: { emailVerified: true, emailVerifiedAtUtc: new Date().toISOString() },
          $unset: { verificationOtpHash: '', verificationExpiresAtUtc: '' },
        },
      );
      verified += r.modifiedCount;
    });
    console.log(`verified=${verified}`);
    return;
  }

  if (command !== 'cleanup') throw new Error('usage: verify|cleanup <emailPattern> [--delete]');
  const doDelete = flag === '--delete';

  // 1. Collect every demo id from every database first (accounts and the data
  //    that references them live in different databases).
  const tenantIds = new Set();
  const userIds = new Set();
  const consumerIds = new Set();
  await eachDb(async (db) => {
    for (const t of await db.collection('tenants').find({ ownerEmail: emailRe }, { projection: { tenantId: 1 } }).toArray()) {
      tenantIds.add(t.tenantId);
    }
    for (const o of await db.collection('tenantOwners').find({ email: emailRe }, { projection: { tenantId: 1, userId: 1 } }).toArray()) {
      tenantIds.add(o.tenantId);
      userIds.add(o.userId);
    }
    for (const c of await db.collection('consumerAccounts').find({ email: emailRe }, { projection: { userId: 1 } }).toArray()) {
      consumerIds.add(c.userId);
      userIds.add(c.userId);
    }
  });
  await eachDb(async (db) => {
    for (const s of await db.collection('tenantStaff').find({ tenantId: { $in: [...tenantIds] } }, { projection: { userId: 1 } }).toArray()) {
      userIds.add(s.userId);
    }
  });
  console.log(`demo shops=${tenantIds.size} demo users=${userIds.size} demo customers=${consumerIds.size}`);
  if (tenantIds.size === 0 && consumerIds.size === 0) return;

  const ids = [...tenantIds];
  const tenantValues = [...ids, ...ids.filter((id) => mongoose.Types.ObjectId.isValid(id)).map((id) => new mongoose.Types.ObjectId(id))];
  const userValues = [...userIds, ...[...userIds].filter((id) => mongoose.Types.ObjectId.isValid(id)).map((id) => new mongoose.Types.ObjectId(id))];

  // 2. Delete (or count) everything that belongs to them. The security audit
  //    log is kept on purpose.
  let total = 0;
  await eachDb(async (db, name) => {
    for (const { name: collection } of await db.listCollections().toArray()) {
      if (/audit/i.test(collection) || collection.startsWith('system.')) continue;
      const or = [{ tenantId: { $in: tenantValues } }];
      if (consumerIds.size) or.push({ consumerId: { $in: [...consumerIds] } });
      if (userValues.length) or.push({ userId: { $in: userValues } });
      if (collection === 'users' && userValues.length) or.push({ _id: { $in: userValues } });
      or.push({ email: emailRe }, { ownerEmail: emailRe }, { loginId: emailRe });
      if (/tracker/i.test(collection)) or.push({ trackerKey: emailRe });
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

main().catch((error) => {
  console.error('ERROR', error.message);
  process.exit(1);
});
