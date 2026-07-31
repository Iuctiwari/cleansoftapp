# Database Package

Shared NestJS and Mongoose database foundations for backend applications.

## Public API

- `DatabaseModule`, connection options, lifecycle handling, and `DatabaseHealth`
- `BaseSchema` and `BaseDocument`
- `BASE_SCHEMA_OPTIONS`, `createBaseSchemaOptions`, and `DatabaseSchema`
- `createBaseSchema` for creating a Mongoose schema from a schema class
- Tenant, audit, and soft-delete field types
- Tenant-scoped filter, audit, soft-delete, and restore helpers

## Extending the Base Schema

Future persistence schemas extend `BaseSchema`, decorate their own fields with `@Prop`, and use
`createBaseSchema` to produce the Mongoose schema:

```ts
@DatabaseSchema()
export class ExampleSchema extends BaseSchema {
  @Prop({ required: true, type: String })
  readonly name!: string;
}

export const ExampleMongooseSchema = createBaseSchema(ExampleSchema);
export type ExampleDocument = BaseDocument<ExampleSchema>;
```

The inherited fields are `_id`, `tenantId`, `createdBy`, `updatedBy`, `isDeleted`, `deletedAt`,
`deletedBy`, `createdAt`, `updatedAt`, and `version`. Timestamps are managed automatically by
Mongoose. `tenantId` is required and immutable, and `isDeleted` defaults to `false`.

## Dependency Boundary

This package contains reusable persistence infrastructure only. Business schemas, repositories,
services, controllers, DTOs, APIs, and domain logic belong to their owning modules.
