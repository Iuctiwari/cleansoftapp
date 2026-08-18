import 'reflect-metadata';

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { CatalogTemplateSeeder } from './catalog/catalog-template.seeder';

async function seedCatalogTemplates(): Promise<void> {
  const application = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  try {
    const count = await application.get(CatalogTemplateSeeder).seed();
    new Logger('CatalogTemplateSeed').log(`Upserted ${count} predefined catalog templates`);
  } finally {
    await application.close();
  }
}

void seedCatalogTemplates();
