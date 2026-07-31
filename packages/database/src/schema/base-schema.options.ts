import { Schema as NestSchema } from '@nestjs/mongoose';
import type { Schema as MongooseSchema, SchemaOptions } from 'mongoose';

import { BASE_SCHEMA_FIELD_NAMES } from './base-schema.constants';

export const BASE_SCHEMA_OPTIONS = Object.freeze({
  optimisticConcurrency: true,
  timestamps: {
    createdAt: BASE_SCHEMA_FIELD_NAMES.CREATED_AT,
    updatedAt: BASE_SCHEMA_FIELD_NAMES.UPDATED_AT,
  },
  versionKey: BASE_SCHEMA_FIELD_NAMES.VERSION,
}) satisfies Readonly<SchemaOptions>;

export function createBaseSchemaOptions(options: SchemaOptions = {}): SchemaOptions {
  return {
    ...BASE_SCHEMA_OPTIONS,
    ...options,
    timestamps: BASE_SCHEMA_OPTIONS.timestamps,
  };
}

export function DatabaseSchema(options: SchemaOptions = {}): ClassDecorator {
  return NestSchema(createBaseSchemaOptions(options));
}

export function applyBaseSchemaOptions<TSchema>(
  schema: MongooseSchema<TSchema>,
): MongooseSchema<TSchema> {
  if (!schema.get('timestamps')) {
    schema.set('timestamps', BASE_SCHEMA_OPTIONS.timestamps);
  }

  schema.set('optimisticConcurrency', BASE_SCHEMA_OPTIONS.optimisticConcurrency);
  schema.set('versionKey', BASE_SCHEMA_OPTIONS.versionKey);

  return schema;
}
