export const BASE_SCHEMA_FIELD_NAMES = {
  CREATED_AT: 'createdAt',
  CREATED_BY: 'createdBy',
  DELETED_AT: 'deletedAt',
  DELETED_BY: 'deletedBy',
  IS_DELETED: 'isDeleted',
  TENANT_ID: 'tenantId',
  UPDATED_AT: 'updatedAt',
  UPDATED_BY: 'updatedBy',
  VERSION: 'version',
} as const;

export const BASE_SCHEMA_INDEX_NAME = 'tenant_active_records';
