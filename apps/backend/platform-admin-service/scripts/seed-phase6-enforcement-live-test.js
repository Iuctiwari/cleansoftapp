/**
 * ONE-OFF LOCAL SCRIPT — not committed. Phase 6 live verification: seeds real
 * TenantSubscription (SUSPENDED) and TenantModuleAccess (ORDER_MANAGEMENT
 * disabled) documents into the LOCAL platform-admin-service MongoDB so the
 * real /v1/platform-admin/internal/enforcement/:tenantId endpoint can be
 * exercised end-to-end against real data. Run with:
 *   node scripts/seed-phase6-enforcement-live-test.js seed
 *   node scripts/seed-phase6-enforcement-live-test.js cleanup
 */
const fs = require('node:fs');
const path = require('node:path');
const mongoose = require('mongoose');

const envPath = path.join(__dirname, '..', '.env');
for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
  const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
  if (match && !(match[1] in process.env)) process.env[match[1]] = match[2];
}

const SUSPENDED_TENANT_ID = 'phase6-live-suspended-tenant';
const MODULE_DISABLED_TENANT_ID = 'phase6-live-module-disabled-tenant';

const TenantSubscriptionSchema = new mongoose.Schema(
  {
    tenantId: { type: String, required: true, unique: true },
    planKey: String,
    status: String,
    startDate: Date,
    billingCycle: String,
    autoRenew: Boolean,
  },
  { timestamps: true },
);

const TenantModuleAccessSchema = new mongoose.Schema(
  {
    tenantId: String,
    moduleKey: String,
    isEnabled: Boolean,
  },
  { timestamps: true },
);

async function main() {
  const mode = process.argv[2];
  if (mode !== 'seed' && mode !== 'cleanup') {
    console.error('Usage: node seed-phase6-enforcement-live-test.js <seed|cleanup>');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const TenantSubscription = mongoose.model(
    'TenantSubscriptionMongoose',
    TenantSubscriptionSchema,
    'platformTenantSubscriptions',
  );
  const TenantModuleAccess = mongoose.model(
    'TenantModuleAccessMongoose',
    TenantModuleAccessSchema,
    'platformTenantModuleAccess',
  );

  if (mode === 'seed') {
    const subscription = await TenantSubscription.findOneAndUpdate(
      { tenantId: SUSPENDED_TENANT_ID },
      {
        $set: {
          tenantId: SUSPENDED_TENANT_ID,
          planKey: 'PRO',
          status: 'SUSPENDED',
          startDate: new Date(),
          billingCycle: 'MONTHLY',
          autoRenew: false,
        },
      },
      { upsert: true, new: true },
    );
    const moduleAccess = await TenantModuleAccess.findOneAndUpdate(
      { tenantId: MODULE_DISABLED_TENANT_ID, moduleKey: 'ORDER_MANAGEMENT' },
      {
        $set: {
          tenantId: MODULE_DISABLED_TENANT_ID,
          moduleKey: 'ORDER_MANAGEMENT',
          isEnabled: false,
        },
      },
      { upsert: true, new: true },
    );
    console.log(
      JSON.stringify(
        {
          suspendedTenantId: subscription.tenantId,
          suspendedStatus: subscription.status,
          moduleDisabledTenantId: moduleAccess.tenantId,
          moduleDisabledKey: moduleAccess.moduleKey,
          moduleIsEnabled: moduleAccess.isEnabled,
        },
        null,
        2,
      ),
    );
  } else {
    const subResult = await TenantSubscription.deleteOne({ tenantId: SUSPENDED_TENANT_ID });
    const moduleResult = await TenantModuleAccess.deleteMany({
      tenantId: MODULE_DISABLED_TENANT_ID,
    });
    console.log(
      JSON.stringify(
        {
          deletedSubscriptions: subResult.deletedCount,
          deletedModuleAccessRecords: moduleResult.deletedCount,
        },
        null,
        2,
      ),
    );
  }

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
