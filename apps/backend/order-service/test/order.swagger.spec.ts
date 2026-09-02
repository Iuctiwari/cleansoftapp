import 'reflect-metadata';

import { Module, VersioningType, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { createSwaggerDocument, JWT_AUTH_NAME } from '@nexoraa/swagger';
import type { OpenAPIObject } from '@nestjs/swagger';

import { OrderController } from '../src/order/order.controller';
import { OrderScopeGuard } from '../src/order/order.guard';
import { OrderService } from '../src/order/order.service';

@Module({
  controllers: [OrderController],
  providers: [
    OrderScopeGuard,
    {
      provide: ConfigService,
      useValue: { get: (): string => 'test-payment-key' },
    },
    { provide: OrderService, useValue: {} },
  ],
})
class SwaggerTestModule {}

interface Operation {
  readonly parameters?: readonly { readonly in: string; readonly name: string }[];
  readonly requestBody?: unknown;
  readonly responses?: Readonly<Record<string, unknown>>;
  readonly security?: readonly Readonly<Record<string, readonly string[]>>[];
}

function operation(document: OpenAPIObject, path: string, method: string): Operation {
  const route = document.paths[path];
  const value = route?.[method as keyof typeof route];
  if (!value || typeof value !== 'object' || '$ref' in value) {
    throw new Error(`Missing ${method.toUpperCase()} ${path}`);
  }
  return value as Operation;
}

describe('Order Swagger contract', () => {
  let app: INestApplication;
  let document: OpenAPIObject;

  beforeAll(async () => {
    app = await NestFactory.create(SwaggerTestModule, { logger: false });
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    document = createSwaggerDocument(app, { title: 'Order API', useGlobalPrefix: true });
  });

  afterAll(async () => app.close());

  it('registers the public operations plus the protected payment projection', () => {
    const operations = [
      operation(document, '/api/v1/orders', 'post'),
      operation(document, '/api/v1/orders', 'get'),
      operation(document, '/api/v1/orders/{id}', 'get'),
      operation(document, '/api/v1/orders/{id}', 'patch'),
      operation(document, '/api/v1/orders/{id}/status', 'patch'),
      operation(document, '/api/v1/orders/{id}/assign', 'post'),
      operation(document, '/api/v1/orders/{id}/assignment/accept', 'post'),
      operation(document, '/api/v1/orders/{id}/assignment/reject', 'post'),
      operation(document, '/api/v1/orders/{id}/cancel', 'post'),
      operation(document, '/api/v1/orders/{id}/history', 'get'),
      operation(document, '/api/v1/orders/{id}/payment-projection', 'post'),
    ];
    expect(operations).toHaveLength(11);
    for (const route of operations) {
      expect(route.security).toContainEqual({ [JWT_AUTH_NAME]: [] });
      expect(route.responses?.['401']).toBeDefined();
      expect(route.responses?.['403']).toBeDefined();
      expect(route.responses?.['500']).toBeDefined();
    }
  });

  it('documents bodies, query parameters, path parameters, and conflicts', () => {
    for (const [path, method] of [
      ['/api/v1/orders', 'post'],
      ['/api/v1/orders/{id}', 'patch'],
      ['/api/v1/orders/{id}/status', 'patch'],
      ['/api/v1/orders/{id}/assign', 'post'],
      ['/api/v1/orders/{id}/assignment/reject', 'post'],
      ['/api/v1/orders/{id}/cancel', 'post'],
    ]) {
      expect(operation(document, path, method).requestBody).toBeDefined();
    }

    const queryNames = operation(document, '/api/v1/orders', 'get').parameters?.map(
      (parameter) => parameter.name,
    );
    expect(queryNames).toEqual(
      expect.arrayContaining([
        'page',
        'limit',
        'search',
        'status',
        'paymentStatus',
        'branchId',
        'customerId',
        'sortBy',
        'sortDirection',
      ]),
    );

    for (const path of [
      '/api/v1/orders/{id}',
      '/api/v1/orders/{id}/status',
      '/api/v1/orders/{id}/assign',
      '/api/v1/orders/{id}/assignment/accept',
      '/api/v1/orders/{id}/assignment/reject',
      '/api/v1/orders/{id}/cancel',
      '/api/v1/orders/{id}/history',
    ]) {
      const methods = Object.keys(document.paths[path] ?? {});
      for (const method of methods) {
        const route = operation(document, path, method);
        expect(route.parameters).toContainEqual(
          expect.objectContaining({ in: 'path', name: 'id' }),
        );
      }
    }
    expect(
      operation(document, '/api/v1/orders/{id}/status', 'patch').responses?.['409'],
    ).toBeDefined();
  });

  it('documents receipt-ready order details and complete pagination metadata', () => {
    const orderSchema = document.components?.schemas?.OrderResponseDto as
      | { properties?: Readonly<Record<string, unknown>> }
      | undefined;
    const pageSchema = document.components?.schemas?.OrderPageResponseDto as
      | { properties?: Readonly<Record<string, unknown>> }
      | undefined;

    expect(Object.keys(orderSchema?.properties ?? {})).toEqual(
      expect.arrayContaining([
        'id',
        'orderNumber',
        'customerSnapshot',
        'items',
        'subtotal',
        'discount',
        'tax',
        'grandTotal',
        'paidAmount',
        'outstandingAmount',
        'paymentStatus',
        'status',
        'assignment',
        'createdAt',
      ]),
    );
    expect(Object.keys(pageSchema?.properties ?? {})).toEqual(
      expect.arrayContaining(['items', 'page', 'limit', 'total', 'totalPages']),
    );
  });

  it('documents assignment, timeline, and status error contracts', () => {
    const assignment = operation(document, '/api/v1/orders/{id}/assign', 'post');
    const status = operation(document, '/api/v1/orders/{id}/status', 'patch');
    const history = operation(document, '/api/v1/orders/{id}/history', 'get');

    for (const route of [assignment, status]) {
      expect(route.requestBody).toBeDefined();
      for (const code of ['400', '401', '403', '404', '409', '500']) {
        expect(route.responses?.[code]).toBeDefined();
      }
    }
    for (const code of ['400', '401', '403', '404', '500']) {
      expect(history.responses?.[code]).toBeDefined();
    }
  });
});
