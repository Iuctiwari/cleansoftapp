import 'reflect-metadata';

import { Module, VersioningType, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { OpenAPIObject } from '@nestjs/swagger';
import { createSwaggerDocument, JWT_AUTH_NAME } from '@nexoraa/swagger';
import { ConfigService } from '@nestjs/config';
import { validate } from 'class-validator';

import { AppController } from '../src/app.controller';
import { AppHealth } from '../src/app.service';
import {
  ItemCategoryController,
  ServiceCategoryController,
  ServiceController,
  ServiceMappingController,
} from '../src/catalog/catalog.controller';
import { CatalogScopeGuard } from '../src/catalog/catalog.guard';
import { CatalogIdPipe } from '../src/catalog/catalog-id.pipe';
import { CatalogService } from '../src/catalog/catalog.service';
import { UpdateServiceDto } from '../src/catalog/dtos/update-service.dto';

@Module({
  controllers: [
    AppController,
    ItemCategoryController,
    ServiceCategoryController,
    ServiceController,
    ServiceMappingController,
  ],
  providers: [
    AppHealth,
    {
      provide: ConfigService,
      useValue: {
        getOrThrow: (key: string): string => (key === 'SERVICE_NAME' ? 'service-service' : 'test'),
      },
    },
    CatalogScopeGuard,
    CatalogIdPipe,
    { provide: CatalogService, useValue: {} },
  ],
})
class SwaggerModule {}

describe('Catalog Swagger contract', () => {
  let app: INestApplication;
  let document: OpenAPIObject;
  beforeAll(async () => {
    app = await NestFactory.create(SwaggerModule, { logger: false });
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    document = createSwaggerDocument(app, { title: 'Catalog', useGlobalPrefix: true });
  });
  afterAll(async () => app.close());

  it('documents Order Service dependencies and catalog management APIs', () => {
    for (const [path, method] of [
      ['/api/v1/item-categories', 'get'],
      ['/api/v1/item-categories/{id}', 'get'],
      ['/api/v1/item-categories', 'post'],
      ['/api/v1/services', 'get'],
      ['/api/v1/services/{id}', 'get'],
      ['/api/v1/services/{id}/quote', 'get'],
      ['/api/v1/services/{id}/pricing', 'post'],
      ['/api/v1/services/{id}/pricing/{pricingId}', 'patch'],
      ['/api/v1/service-mappings', 'post'],
    ]) {
      const operation = document.paths[path]?.[method as 'get'];
      expect(operation).toBeDefined();
      expect(operation?.security).toContainEqual({ [JWT_AUTH_NAME]: [] });
      expect(operation?.responses?.['401']).toBeDefined();
      expect(operation?.responses?.['403']).toBeDefined();
    }
  });

  it('exposes the production liveness endpoint configured by Docker', () => {
    expect(document.paths['/api/v1/health/live']?.get).toBeDefined();
  });

  it('rejects null update descriptions and documents them as optional but non-null', async () => {
    const dto = Object.assign(new UpdateServiceDto(), { description: null });
    await expect(validate(dto)).resolves.not.toHaveLength(0);

    const schema = document.components?.schemas?.UpdateServiceDto as
      | { properties?: { description?: { nullable?: boolean } } }
      | undefined;
    expect(schema?.properties?.description?.nullable).not.toBe(true);
  });

  it('documents quote inputs and response schema', () => {
    const quote = document.paths['/api/v1/services/{id}/quote']?.get;
    const names = quote?.parameters
      ?.filter((value): value is Exclude<typeof value, { $ref: string }> => !('$ref' in value))
      .map((value) => value.name);
    expect(names).toEqual(
      expect.arrayContaining([
        'id',
        'itemCategoryId',
        'branchId',
        'quantity',
        'weight',
        'effectiveAt',
      ]),
    );
    expect(quote?.responses?.['200']).toBeDefined();
  });
});
