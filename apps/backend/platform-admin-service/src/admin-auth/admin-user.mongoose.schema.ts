import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import { AdminRole } from './admin-auth.types';

/**
 * Deliberately does NOT extend @nexoraa/database's BaseSchema: BaseSchema forces
 * a required tenantId, which does not apply to a platform-level admin identity.
 * @DatabaseSchema still applies the shared timestamps/versionKey conventions.
 */
@DatabaseSchema({ collection: 'platformAdminUsers' })
export class AdminUserMongoose {
  @Prop({ lowercase: true, required: true, trim: true, type: String, unique: true })
  email!: string;

  @Prop({ required: true, select: false, type: String })
  passwordHash!: string;

  @Prop({ default: AdminRole.SUPER_ADMIN, enum: AdminRole, required: true, type: String })
  role!: AdminRole;

  @Prop({ default: true, required: true, type: Boolean })
  isActive!: boolean;

  @Prop({ type: Date })
  lastLoginAt?: Date;
}

export const AdminUserMongooseSchema = SchemaFactory.createForClass(AdminUserMongoose);
AdminUserMongooseSchema.index(
  { email: 1 },
  { name: 'platform_admin_users_email_unique', unique: true },
);
