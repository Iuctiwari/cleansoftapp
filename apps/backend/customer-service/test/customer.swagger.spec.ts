import 'reflect-metadata';

import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { createSwaggerDocument, JWT_AUTH_NAME } from '@nexoraa/swagger';
import type { OpenAPIObject } from '@nestjs/swagger';

import { CustomerController } from '../src/customer/customer.controller';
import { CustomerScopeGuard } from '../src/customer/customer.guard';
import { CustomerService } from '../src/customer/customer.service';

const customerServiceMock = {
  create: jest.fn(),
  delete: jest.fn(),
  getById: jest.fn(),
  list: jest.fn(),
  statistics: jest.fn(),
  update: jest.fn(),
};

@Module({
  controllers: [CustomerController],
  providers: [CustomerScopeGuard, { provide: CustomerService, useValue: customerServiceMock }],
})
class SwaggerTestModule {}

interface SwaggerParameter {
  readonly in: string;
  readonly name: string;
}

interface SwaggerOperation {
  readonly parameters?: readonly SwaggerParameter[];
  readonly requestBody?: unknown;
  readonly responses?: Readonly<Record<string, unknown>>;
  readonly security?: readonly Readonly<Record<string, readonly string[]>>[];
}

interface SwaggerSchema {
  readonly properties?: Readonly<Record<string, unknown>>;
  readonly required?: readonly string[];
}

function operation(document: OpenAPIObject, path: string, method: string): SwaggerOperation {
  const route = document.paths[path];
  const value = route?.[method as keyof typeof route];
  if (!value || typeof value !== 'object' || '$ref' in value) {
    throw new Error(`Missing Swagger operation ${method.toUpperCase()} ${path}`);
  }
  return value as SwaggerOperation;
}

describe('Customer Swagger contract', () => {
  let app: INestApplication;
  let document: OpenAPIObject;

  beforeAll(async () => {
    app = await NestFactory.create(SwaggerTestModule, { logger: false });
    document = createSwaggerDocument(app, { title: 'Customer Swagger Test' });
  });

  afterAll(async () => {
    await app.close();
  });

  it('registers all customer operations with centralized bearer authentication', () => {
    const operations = [
      operation(document, '/customers', 'post'),
      operation(document, '/customers', 'get'),
      operation(document, '/customers/statistics', 'get'),
      operation(document, '/customers/{id}', 'get'),
      operation(document, '/customers/{id}', 'patch'),
      operation(document, '/customers/{id}', 'delete'),
    ];
    expect(operations).toHaveLength(6);
    for (const route of operations) {
      expect(route.security).toContainEqual({ [JWT_AUTH_NAME]: [] });
    }
  });

  it('documents request bodies and typed success responses', () => {
    const create = operation(document, '/customers', 'post');
    const update = operation(document, '/customers/{id}', 'patch');
    expect(create.requestBody).toBeDefined();
    expect(create.responses?.['201']).toBeDefined();
    expect(update.requestBody).toBeDefined();
    expect(update.responses?.['200']).toBeDefined();

    const schemas = document.components?.schemas as Readonly<Record<string, SwaggerSchema>>;
    const createProperties = Object.keys(schemas.CreateCustomerDto.properties ?? {}).sort();
    const updateProperties = Object.keys(schemas.UpdateCustomerDto.properties ?? {}).sort();
    expect(createProperties).toEqual(
      ['address', 'customerType', 'email', 'joiningDate', 'mobile', 'name'].sort(),
    );
    expect(updateProperties).toEqual(createProperties);
    expect(schemas.CreateCustomerDto.required).toEqual(
      expect.arrayContaining(['name', 'customerType']),
    );
    expect(schemas.UpdateCustomerDto.required).toBeUndefined();
    expect(schemas.CustomerResponseDto.properties).toHaveProperty('totalOrders');
    expect(schemas.CustomerPageResponseDto.properties).toHaveProperty('items');
    expect(schemas.CustomerStatisticsResponseDto.properties).toHaveProperty('outstanding');
  });

  it('documents pagination, search, path parameters, and scoped errors', () => {
    const list = operation(document, '/customers', 'get');
    const queryNames = list.parameters?.map((parameter) => parameter.name) ?? [];
    expect(queryNames.sort()).toEqual(['limit', 'page', 'search']);
    expect(list.responses?.['200']).toBeDefined();
    expect(list.responses?.['400']).toBeDefined();

    for (const method of ['get', 'patch', 'delete']) {
      const route = operation(document, '/customers/{id}', method);
      const parameters = route.parameters ?? [];
      expect(parameters).toContainEqual(expect.objectContaining({ in: 'path', name: 'id' }));
      expect(route.responses?.['404']).toBeDefined();
    }

    expect(operation(document, '/customers/{id}', 'delete').responses?.['204']).toBeDefined();
  });
});
