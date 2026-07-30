import type { Type } from '@nestjs/common';
import { SchemaFactory } from '@nestjs/mongoose';
import type { FilterQuery, IndexDefinition, Schema as MongooseSchema, UpdateQuery } from 'mongoose';

import { BASE_SCHEMA_INDEX_NAME } from './base-schema.constants';
import { applyBaseSchemaOptions } from './base-schema.options';
import type { ActiveTenantFilter, DatabaseIdentifier } from './base-schema.types';
import type { BaseSchema } from './base.schema';

const ACTIVE_TENANT_INDEX: IndexDefinition = {
  tenantId: 1,
  isDeleted: 1,
};

export function createBaseSchema<TSchema extends BaseSchema>(
  schemaClass: Type<TSchema>,
): MongooseSchema<TSchema> {
  const schema = applyBaseSchemaOptions(SchemaFactory.createForClass(schemaClass));
  schema.index(ACTIVE_TENANT_INDEX, {
    name: BASE_SCHEMA_INDEX_NAME,
  });

  return schema;
}

export function createActiveTenantFilter<TSchema extends BaseSchema = BaseSchema>(
  tenantId: DatabaseIdentifier,
  filter: FilterQuery<TSchema> = {},
): ActiveTenantFilter<TSchema> {
  return {
    ...filter,
    isDeleted: false,
    tenantId,
  };
}

export function createSoftDeleteUpdate<TSchema extends BaseSchema = BaseSchema>(
  actorId: DatabaseIdentifier,
  deletedAt: Date = new Date(),
): UpdateQuery<TSchema> {
  return {
    $set: {
      deletedAt,
      deletedBy: actorId,
      isDeleted: true,
      updatedBy: actorId,
    },
  };
}

export function createRestoreUpdate<TSchema extends BaseSchema = BaseSchema>(
  actorId: DatabaseIdentifier,
): UpdateQuery<TSchema> {
  return {
    $set: {
      isDeleted: false,
      updatedBy: actorId,
    },
    $unset: {
      deletedAt: 1,
      deletedBy: 1,
    },
  };
}

export function createAuditFields(actorId: DatabaseIdentifier): Readonly<{
  createdBy: DatabaseIdentifier;
  updatedBy: DatabaseIdentifier;
}> {
  return {
    createdBy: actorId,
    updatedBy: actorId,
  };
}
