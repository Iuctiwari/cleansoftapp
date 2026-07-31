import { Prop } from '@nestjs/mongoose';
import { Schema as MongooseSchema, Types } from 'mongoose';

import { DatabaseSchema } from './base-schema.options';
import type {
  AuditSchemaFields,
  SoftDeleteSchemaFields,
  TenantSchemaFields,
} from './base-schema.types';

@DatabaseSchema()
export abstract class BaseSchema
  implements TenantSchemaFields, AuditSchemaFields, SoftDeleteSchemaFields
{
  readonly _id!: Types.ObjectId;

  @Prop({
    immutable: true,
    required: true,
    type: MongooseSchema.Types.ObjectId,
  })
  readonly tenantId!: Types.ObjectId;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  readonly createdBy?: Types.ObjectId;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  readonly updatedBy?: Types.ObjectId;

  @Prop({ default: false, required: true, type: Boolean })
  readonly isDeleted!: boolean;

  @Prop({ type: Date })
  readonly deletedAt?: Date;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  readonly deletedBy?: Types.ObjectId;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
  readonly version!: number;
}
