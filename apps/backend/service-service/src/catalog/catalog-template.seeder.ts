import { Inject, Injectable } from '@nestjs/common';

import { PREDEFINED_CATALOG_TEMPLATES } from './catalog-template.seed-data';
import { CATALOG_REPOSITORY, type CatalogRepository } from './catalog.types';

@Injectable()
export class CatalogTemplateSeeder {
  constructor(@Inject(CATALOG_REPOSITORY) private readonly repository: CatalogRepository) {}

  async seed(): Promise<number> {
    for (const template of PREDEFINED_CATALOG_TEMPLATES) {
      await this.repository.upsertTemplate(template);
    }
    return PREDEFINED_CATALOG_TEMPLATES.length;
  }
}
