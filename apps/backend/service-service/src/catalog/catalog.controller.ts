import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiInternalServerErrorResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { type CatalogRequest, CatalogScopeGuard } from './catalog.guard';
import { CatalogIdPipe } from './catalog-id.pipe';
import { CatalogService, type QuoteRecord } from './catalog.service';
import type {
  CatalogPage,
  CatalogScope,
  ItemCategoryRecord,
  ServiceCategoryRecord,
  ServiceMappingRecord,
  ServicePricingRecord,
  ServiceRecord,
} from './catalog.types';
import {
  CatalogErrorResponseDto,
  ItemCategoryPageResponseDto,
  ItemCategoryResponseDto,
  QuoteResponseDto,
  ServiceCategoryResponseDto,
  ServiceCategoryPageResponseDto,
  ServiceMappingResponseDto,
  ServicePageResponseDto,
  ServicePricingResponseDto,
  ServiceResponseDto,
} from './dtos/catalog-response.dto';
import { CreateItemCategoryDto } from './dtos/create-item-category.dto';
import { CreateServiceDto } from './dtos/create-service.dto';
import { ItemCategoryQueryDto } from './dtos/item-category-query.dto';
import { QuoteQueryDto } from './dtos/quote-query.dto';
import { CreateServiceCategoryDto, UpdateServiceCategoryDto } from './dtos/service-category.dto';
import {
  CreateServiceMappingDto,
  ServiceMappingQueryDto,
  UpdateServiceMappingDto,
} from './dtos/service-mapping.dto';
import {
  CreateServicePricingDto,
  ServicePricingQueryDto,
  UpdateServicePricingDto,
} from './dtos/service-pricing.dto';
import { ServiceQueryDto } from './dtos/service-query.dto';
import { UpdateItemCategoryDto } from './dtos/update-item-category.dto';
import { UpdateServiceDto } from './dtos/update-service.dto';

function scope(request: CatalogRequest): CatalogScope {
  if (!request.catalogScope) throw new Error('Catalog scope guard was not applied');
  return request.catalogScope;
}

@ApiTags('Item Categories')
@Controller('item-categories')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(CatalogScopeGuard)
@ApiBadRequestResponse({ type: CatalogErrorResponseDto })
@ApiUnauthorizedResponse({ type: CatalogErrorResponseDto })
@ApiForbiddenResponse({ type: CatalogErrorResponseDto })
@ApiNotFoundResponse({ type: CatalogErrorResponseDto })
@ApiConflictResponse({ type: CatalogErrorResponseDto })
@ApiInternalServerErrorResponse({ type: CatalogErrorResponseDto })
export class ItemCategoryController {
  constructor(private readonly catalog: CatalogService) {}
  @Get()
  @ApiOperation({ summary: 'List tenant item categories' })
  @ApiOkResponse({ type: ItemCategoryPageResponseDto })
  list(
    @Req() request: CatalogRequest,
    @Query() query: ItemCategoryQueryDto,
  ): Promise<CatalogPage<ItemCategoryRecord>> {
    return this.catalog.listItemCategories(scope(request), query);
  }
  @Get(':id')
  @ApiOperation({ summary: 'Get an item category and mapped service IDs' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ItemCategoryResponseDto })
  get(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
  ): Promise<ItemCategoryRecord> {
    return this.catalog.getItemCategory(scope(request), id);
  }
  @Post()
  @ApiOperation({ summary: 'Create an item category' })
  @ApiCreatedResponse({ type: ItemCategoryResponseDto })
  create(
    @Req() request: CatalogRequest,
    @Body() body: CreateItemCategoryDto,
  ): Promise<ItemCategoryRecord> {
    return this.catalog.createItemCategory(scope(request), body);
  }
  @Patch(':id')
  @ApiOperation({ summary: 'Update an item category' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ItemCategoryResponseDto })
  update(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Body() body: UpdateItemCategoryDto,
  ): Promise<ItemCategoryRecord> {
    return this.catalog.updateItemCategory(scope(request), id, body);
  }
  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate an item category' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ItemCategoryResponseDto })
  deactivate(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
  ): Promise<ItemCategoryRecord> {
    return this.catalog.deactivateItemCategory(scope(request), id);
  }
}

@ApiTags('Services')
@Controller('services')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(CatalogScopeGuard)
@ApiBadRequestResponse({ type: CatalogErrorResponseDto })
@ApiUnauthorizedResponse({ type: CatalogErrorResponseDto })
@ApiForbiddenResponse({ type: CatalogErrorResponseDto })
@ApiNotFoundResponse({ type: CatalogErrorResponseDto })
@ApiConflictResponse({ type: CatalogErrorResponseDto })
@ApiInternalServerErrorResponse({ type: CatalogErrorResponseDto })
export class ServiceController {
  constructor(private readonly catalog: CatalogService) {}
  @Get()
  @ApiOperation({ summary: 'List tenant services' })
  @ApiOkResponse({ type: ServicePageResponseDto })
  list(
    @Req() request: CatalogRequest,
    @Query() query: ServiceQueryDto,
  ): Promise<CatalogPage<ServiceRecord>> {
    return this.catalog.listServices(scope(request), query);
  }
  @Get(':id')
  @ApiOperation({ summary: 'Get a service and mapped item-category IDs' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceResponseDto })
  get(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
  ): Promise<ServiceRecord> {
    return this.catalog.getService(scope(request), id);
  }
  @Post()
  @ApiOperation({ summary: 'Create service metadata' })
  @ApiCreatedResponse({ type: ServiceResponseDto })
  create(@Req() request: CatalogRequest, @Body() body: CreateServiceDto): Promise<ServiceRecord> {
    return this.catalog.createService(scope(request), body);
  }
  @Patch(':id')
  @ApiOperation({ summary: 'Update service metadata, not historical prices' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceResponseDto })
  update(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Body() body: UpdateServiceDto,
  ): Promise<ServiceRecord> {
    return this.catalog.updateService(scope(request), id, body);
  }
  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a service' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceResponseDto })
  deactivate(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
  ): Promise<ServiceRecord> {
    return this.catalog.deactivateService(scope(request), id);
  }
  @Post(':id/pricing')
  @ApiOperation({ summary: 'Create a non-overlapping effective pricing version' })
  @ApiParam({ name: 'id' })
  @ApiCreatedResponse({ type: ServicePricingResponseDto })
  createPricing(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Body() body: CreateServicePricingDto,
  ): Promise<ServicePricingRecord> {
    return this.catalog.createPricing(scope(request), id, body);
  }
  @Get(':id/pricing')
  @ApiOperation({ summary: 'List immutable pricing history' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: [ServicePricingResponseDto] })
  pricing(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Query() query: ServicePricingQueryDto,
  ): Promise<readonly ServicePricingRecord[]> {
    return this.catalog.listPricing(scope(request), id, query.itemCategoryId);
  }
  @Patch(':id/pricing/:pricingId')
  @ApiOperation({ summary: 'Close or deactivate an immutable pricing version' })
  @ApiParam({ name: 'id' })
  @ApiParam({ name: 'pricingId' })
  @ApiOkResponse({ type: ServicePricingResponseDto })
  updatePricing(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Param('pricingId', CatalogIdPipe) pricingId: string,
    @Body() body: UpdateServicePricingDto,
  ): Promise<ServicePricingRecord> {
    return this.catalog.updatePricing(scope(request), id, pricingId, body);
  }
  @Get(':id/quote')
  @ApiOperation({ summary: 'Resolve authoritative effective pricing for Order Service' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: QuoteResponseDto })
  quote(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Query() query: QuoteQueryDto,
  ): Promise<QuoteRecord> {
    return this.catalog.quote(scope(request), id, query);
  }
}

@ApiTags('Service Categories')
@Controller('services/categories')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(CatalogScopeGuard)
@ApiBadRequestResponse({ type: CatalogErrorResponseDto })
@ApiUnauthorizedResponse({ type: CatalogErrorResponseDto })
@ApiForbiddenResponse({ type: CatalogErrorResponseDto })
@ApiNotFoundResponse({ type: CatalogErrorResponseDto })
@ApiConflictResponse({ type: CatalogErrorResponseDto })
@ApiInternalServerErrorResponse({ type: CatalogErrorResponseDto })
export class ServiceCategoryController {
  constructor(private readonly catalog: CatalogService) {}
  @Get()
  @ApiOperation({ summary: 'List service categories' })
  @ApiOkResponse({ type: ServiceCategoryPageResponseDto })
  list(
    @Req() request: CatalogRequest,
    @Query() query: ItemCategoryQueryDto,
  ): Promise<CatalogPage<ServiceCategoryRecord>> {
    return this.catalog.listServiceCategories(scope(request), query);
  }
  @Post()
  @ApiOperation({ summary: 'Create a service category' })
  @ApiCreatedResponse({ type: ServiceCategoryResponseDto })
  create(
    @Req() request: CatalogRequest,
    @Body() body: CreateServiceCategoryDto,
  ): Promise<ServiceCategoryRecord> {
    return this.catalog.createServiceCategory(scope(request), body);
  }
  @Patch(':id')
  @ApiOperation({ summary: 'Update or deactivate a service category' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceCategoryResponseDto })
  update(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Body() body: UpdateServiceCategoryDto,
  ): Promise<ServiceCategoryRecord> {
    return this.catalog.updateServiceCategory(scope(request), id, body);
  }
}

@ApiTags('Service Mappings')
@Controller('service-mappings')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(CatalogScopeGuard)
@ApiBadRequestResponse({ type: CatalogErrorResponseDto })
@ApiUnauthorizedResponse({ type: CatalogErrorResponseDto })
@ApiForbiddenResponse({ type: CatalogErrorResponseDto })
@ApiNotFoundResponse({ type: CatalogErrorResponseDto })
@ApiConflictResponse({ type: CatalogErrorResponseDto })
@ApiInternalServerErrorResponse({ type: CatalogErrorResponseDto })
export class ServiceMappingController {
  constructor(private readonly catalog: CatalogService) {}
  @Get()
  @ApiOperation({ summary: 'List category/service mappings' })
  @ApiOkResponse({ type: [ServiceMappingResponseDto] })
  list(
    @Req() request: CatalogRequest,
    @Query() query: ServiceMappingQueryDto,
  ): Promise<readonly ServiceMappingRecord[]> {
    return this.catalog.listMappings(scope(request), query);
  }
  @Post()
  @ApiOperation({ summary: 'Map an item category to a service' })
  @ApiCreatedResponse({ type: ServiceMappingResponseDto })
  create(
    @Req() request: CatalogRequest,
    @Body() body: CreateServiceMappingDto,
  ): Promise<ServiceMappingRecord> {
    return this.catalog.createMapping(scope(request), body);
  }
  @Patch(':id')
  @ApiOperation({ summary: 'Activate or deactivate a service mapping' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceMappingResponseDto })
  update(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
    @Body() body: UpdateServiceMappingDto,
  ): Promise<ServiceMappingRecord> {
    return this.catalog.updateMapping(scope(request), id, body);
  }
  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a service mapping' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: ServiceMappingResponseDto })
  deactivate(
    @Req() request: CatalogRequest,
    @Param('id', CatalogIdPipe) id: string,
  ): Promise<ServiceMappingRecord> {
    return this.catalog.deactivateMapping(scope(request), id);
  }
}
