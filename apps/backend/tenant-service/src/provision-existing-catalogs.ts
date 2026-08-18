import 'reflect-metadata';

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { TenantService } from './tenant/tenant.service';

async function provisionExistingCatalogs(): Promise<void> {
  const application = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  try {
    const count = await application.get(TenantService).provisionExistingCatalogs();
    new Logger('ExistingTenantCatalogProvisioning').log(
      `Provisioned catalog templates for ${count} existing tenants`,
    );
  } finally {
    await application.close();
  }
}

void provisionExistingCatalogs();
