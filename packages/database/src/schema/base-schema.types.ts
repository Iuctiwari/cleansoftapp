import type { FilterQuery, HydratedDocument, Model, Types } from 'mongoose';

import type { BaseSchema } from './base.schema';

export type DatabaseIdentifier = Types.ObjectId | string;

export interface TenantSchemaFields {
  readonly tenantId: Types.ObjectId;
}

export interface AuditSchemaFields {
  readonly createdAt: Date;
  readonly createdBy?: Types.ObjectId;
  readonly updatedAt: Date;
  readonly updatedBy?: Types.ObjectId;
}

export interface SoftDeleteSchemaFields {
  readonly isDeleted: boolean;
  readonly deletedAt?: Date;
  readonly deletedBy?: Types.ObjectId;
}

export type BaseDocument<TSchema extends BaseSchema = BaseSchema> = HydratedDocument<TSchema>;

export type BaseModel<TSchema extends BaseSchema = BaseSchema> = Model<TSchema>;

export type ActiveTenantFilter<TSchema extends BaseSchema> = FilterQuery<TSchema> & {
  readonly isDeleted: false;
  readonly tenantId: DatabaseIdentifier;
};
