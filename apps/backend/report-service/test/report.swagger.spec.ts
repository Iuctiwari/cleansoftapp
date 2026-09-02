import 'reflect-metadata';

import { Module, VersioningType, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { OpenAPIObject } from '@nestjs/swagger';
import { createSwaggerDocument, JWT_AUTH_NAME } from '@nexoraa/swagger';

import { ReportController } from '../src/report/report.controller';
import { ReportScopeGuard } from '../src/report/report.guard';
import { ReportService } from '../src/report/report.service';

@Module({
  controllers: [ReportController],
  providers: [ReportScopeGuard, { provide: ReportService, useValue: {} }],
})
class SwaggerTestModule {}

interface Operation {
  readonly parameters?: readonly { readonly name: string }[];
  readonly responses?: Readonly<Record<string, unknown>>;
  readonly security?: readonly Readonly<Record<string, readonly string[]>>[];
}

function operation(document: OpenAPIObject, path: string): Operation {
  const value = document.paths[path]?.get;
  if (!value || '$ref' in value) throw new Error(`Missing GET ${path}`);
  return value as unknown as Operation;
}

describe('Report Swagger contract', () => {
  let app: INestApplication;
  let document: OpenAPIObject;

  beforeAll(async () => {
    app = await NestFactory.create(SwaggerTestModule, { logger: false });
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    document = createSwaggerDocument(app, { title: 'Report API', useGlobalPrefix: true });
  });

  afterAll(async () => app.close());

  it('publishes all report routes through centralized Swagger metadata', () => {
    for (const path of [
      '/api/v1/reports/branch-performance',
      '/api/v1/reports/summary',
      '/api/v1/reports/orders',
      '/api/v1/reports/payments',
      '/api/v1/reports/expenses',
    ]) {
      const route = operation(document, path);
      expect(route.security).toContainEqual({ [JWT_AUTH_NAME]: [] });
      for (const status of ['200', '400', '401', '403', '500']) {
        expect(route.responses?.[status]).toBeDefined();
      }
    }
  });

  it('documents preset and custom periods without tenant or branch overrides', () => {
    expect(
      operation(document, '/api/v1/reports/summary').parameters?.map(({ name }) => name),
    ).toEqual(expect.arrayContaining(['period', 'startDate', 'endDate']));
    expect(
      operation(document, '/api/v1/reports/branch-performance').parameters?.map(({ name }) => name),
    ).toEqual(expect.arrayContaining(['period', 'startDate', 'endDate']));
    for (const path of [
      '/api/v1/reports/orders',
      '/api/v1/reports/payments',
      '/api/v1/reports/expenses',
    ]) {
      const names = operation(document, path).parameters?.map(({ name }) => name);
      expect(names).toEqual(
        expect.arrayContaining(['period', 'page', 'limit', 'startDate', 'endDate']),
      );
      expect(names).not.toEqual(expect.arrayContaining(['tenantId', 'branchId']));
    }
  });

  it('documents the Phase 2 calculated metric objects', () => {
    const schemas = document.components?.schemas ?? {};
    for (const [pageSchema, metricSchema] of [
      ['ReportOrderPageResponseDto', 'ReportOrderMetricsDto'],
      ['ReportPaymentPageResponseDto', 'ReportPaymentMetricsDto'],
      ['ReportExpensePageResponseDto', 'ReportExpenseMetricsDto'],
    ]) {
      const page = schemas[pageSchema] as {
        readonly properties?: Readonly<Record<string, { readonly $ref?: string }>>;
        readonly required?: readonly string[];
      };
      expect(page.properties?.metrics?.$ref).toBe(`#/components/schemas/${metricSchema}`);
      expect(page.required).toContain('metrics');
      expect(schemas[metricSchema]).toBeDefined();
    }
  });
});
