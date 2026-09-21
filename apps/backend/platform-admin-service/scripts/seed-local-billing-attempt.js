/**
 * ONE-OFF LOCAL SCRIPT — not committed. Inserts a BillingAttempt document
 * directly, standing in for what create-order would normally write, so the
 * Razorpay webhook path can be exercised end-to-end without real API keys.
 * Run with: node scripts/seed-local-billing-attempt.js
 */
const fs = require('node:fs');
const path = require('node:path');
const mongoose = require('mongoose');

const envPath = path.join(__dirname, '..', '.env');
for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
  const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
  if (match && !(match[1] in process.env)) process.env[match[1]] = match[2];
}

const TENANT_ID = process.argv[2] || 'bil4b9e3c5d371a39be8977';
const ORDER_ID = process.argv[3] || 'order_LIVEtest0000001';

const BillingAttemptSchema = new mongoose.Schema(
  {
    tenantId: String,
    razorpayOrderId: { type: String, unique: true },
    razorpayPaymentId: String,
    amountInPaise: Number,
    currency: String,
    billingCycle: String,
    planKeyAtCreation: String,
    status: String,
  },
  { timestamps: true },
);

async function main() {
  await mongoose.connect(process.env.MONGODB_URI);
  const BillingAttempt = mongoose.model(
    'BillingAttemptMongoose',
    BillingAttemptSchema,
    'platformBillingAttempts',
  );

  const result = await BillingAttempt.findOneAndUpdate(
    { razorpayOrderId: ORDER_ID },
    {
      $set: {
        tenantId: TENANT_ID,
        amountInPaise: 99900,
        currency: 'INR',
        billingCycle: 'MONTHLY',
        planKeyAtCreation: 'PRO',
        status: 'CREATED',
      },
    },
    { upsert: true, new: true },
  );

  console.log(JSON.stringify({ id: result._id.toString(), tenantId: result.tenantId, razorpayOrderId: result.razorpayOrderId }, null, 2));
  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
