/**
 * ONE-OFF LOCAL SCRIPT — not committed, not referenced by any npm script.
 * Inserts (or updates) a single AdminUser document directly via Mongoose for
 * manual local testing of POST /platform-admin/auth/login and /refresh.
 * Run with: node scripts/seed-local-admin.js
 */
const { randomBytes, scryptSync } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const mongoose = require('mongoose');

// Minimal .env loader (avoids adding a dotenv dependency for a one-off script).
const envPath = path.join(__dirname, '..', '.env');
for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
  const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
  if (match && !(match[1] in process.env)) process.env[match[1]] = match[2];
}

const EMAIL = process.env.SEED_ADMIN_EMAIL || 'owner@nexoraa.com';
const PASSWORD = process.env.SEED_ADMIN_PASSWORD || 'ChangeMe123!Local';

function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

const AdminUserSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    role: { type: String, required: true, enum: ['SUPER_ADMIN', 'SUPPORT_ADMIN'] },
    isActive: { type: Boolean, required: true, default: true },
    lastLoginAt: { type: Date },
  },
  { timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' } },
);

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set (expected in .env)');

  await mongoose.connect(uri);
  const AdminUser = mongoose.model('AdminUserMongoose', AdminUserSchema, 'platformAdminUsers');

  const passwordHash = hashPassword(PASSWORD);
  const result = await AdminUser.findOneAndUpdate(
    { email: EMAIL.toLowerCase() },
    { $set: { passwordHash, role: 'SUPER_ADMIN', isActive: true } },
    { upsert: true, new: true },
  );

  console.log(JSON.stringify({ id: result._id.toString(), email: result.email, role: result.role }, null, 2));
  console.log(`Seeded/updated admin: ${EMAIL} / ${PASSWORD}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
