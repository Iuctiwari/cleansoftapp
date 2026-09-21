import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';
import { Schema as MongooseSchema } from 'mongoose';

import { ModuleKey } from './module-key.enum';

/**
 * Platform-level configuration keyed by tenantId (tenant-service's own string
 * identifier, not this collection's _id) — does not extend BaseSchema, same
 * rationale as admin-user/business-type schemas.
 */
@DatabaseSchema({ collection: 'platformTenantModuleAccess' })
export class TenantModuleAccessMongoose {
  @Prop({ required: true, trim: true, type: String })
  tenantId!: string;

  @Prop({ enum: ModuleKey, required: true, type: String })
  moduleKey!: ModuleKey;

  @Prop({ default: true, required: true, type: Boolean })
  isEnabled!: boolean;

  @Prop({ type: MongooseSchema.Types.Mixed })
  customLimit?: unknown;

  @Prop({ type: String })
  overriddenByAdminUserId?: string;
}

export const TenantModuleAccessMongooseSchema = SchemaFactory.createForClass(
  TenantModuleAccessMongoose,
);
TenantModuleAccessMongooseSchema.index(
  { tenantId: 1, moduleKey: 1 },
  { name: 'platform_tenant_module_access_tenant_module_unique', unique: true },
);
