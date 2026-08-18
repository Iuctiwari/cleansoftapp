import { Injectable, Logger, type OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';

import {
  CatalogTemplateMongoose,
  ItemCategoryMongoose,
  ServiceCategoryMongoose,
  ServiceMappingMongoose,
  ServiceMongoose,
  ServicePricingMongoose,
} from './catalog.schema';

@Injectable()
export class CatalogIndexService implements OnApplicationBootstrap {
  private readonly logger = new Logger(CatalogIndexService.name);

  constructor(
    private readonly configService: ConfigService,
    @InjectModel(CatalogTemplateMongoose.name)
    private readonly templateModel: Model<CatalogTemplateMongoose>,
    @InjectModel(ItemCategoryMongoose.name)
    private readonly itemCategoryModel: Model<ItemCategoryMongoose>,
    @InjectModel(ServiceCategoryMongoose.name)
    private readonly serviceCategoryModel: Model<ServiceCategoryMongoose>,
    @InjectModel(ServiceMongoose.name)
    private readonly serviceModel: Model<ServiceMongoose>,
    @InjectModel(ServiceMappingMongoose.name)
    private readonly mappingModel: Model<ServiceMappingMongoose>,
    @InjectModel(ServicePricingMongoose.name)
    private readonly pricingModel: Model<ServicePricingMongoose>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (this.configService.get<string>('CATALOG_CREATE_INDEXES', 'false') !== 'true') return;
    await Promise.all([
      this.templateModel.createIndexes(),
      this.itemCategoryModel.createIndexes(),
      this.serviceCategoryModel.createIndexes(),
      this.serviceModel.createIndexes(),
      this.mappingModel.createIndexes(),
      this.pricingModel.createIndexes(),
    ]);
    this.logger.log('Catalog MongoDB indexes created or verified');
  }
}
