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
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { CreateCategorySettingsDto, UpdateCategorySettingsDto } from './dtos/category-settings.dto';
import {
  InitializeTenantSettingsDto,
  InitializeTenantSettingsResponseDto,
} from './dtos/initialize-settings.dto';
import { CreateItemSettingsDto, UpdateItemSettingsDto } from './dtos/item-settings.dto';
import { UpdatePricingSettingsDto } from './dtos/pricing-settings.dto';
import { SettingsQueryDto } from './dtos/query-settings.dto';
import { CreateServiceSettingsDto, UpdateServiceSettingsDto } from './dtos/service-settings.dto';
import {
  BusinessSettingsSummaryResponseDto,
  SettingsCategoryResponseDto,
  SettingsItemResponseDto,
  SettingsPricingResponseDto,
  SettingsServiceResponseDto,
} from './dtos/settings-response.dto';
import { SettingsIdPipe } from './settings-id.pipe';
import { SettingsProvisioningService } from './settings-provisioning.service';
import { PREDEFINED_CATALOG_TEMPLATES, type TemplateRecord } from './settings-template.seed-data';
import { type SettingsRequest, SettingsScopeGuard } from './settings.guard';
import { SettingsService } from './settings.service';
import type {
  BusinessCatalogSettingsSummary,
  SettingsCategoryRecord,
  SettingsItemRecord,
  SettingsPricingRecord,
  SettingsScope,
  SettingsServiceRecord,
} from './settings.types';

function scope(request: SettingsRequest): SettingsScope {
  if (!request.settingsScope) throw new Error('Settings scope guard was not applied');
  return request.settingsScope;
}

@ApiTags('Settings Services')
@Controller('settings-services')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(SettingsScopeGuard)
export class SettingsController {
  constructor(
    private readonly settingsService: SettingsService,
    private readonly provisioningService: SettingsProvisioningService,
  ) {}

  // ─────────────────────────────────────────────────────────────────────────────
  // ONBOARDING INITIALIZATION & TEMPLATES
  // ─────────────────────────────────────────────────────────────────────────────
  @Post('initialize')
  @ApiOperation({
    summary: 'Initialize tenant catalog configuration from selected business template',
  })
  @ApiCreatedResponse({ type: InitializeTenantSettingsResponseDto })
  initializeTenantSettings(
    @Body() body: InitializeTenantSettingsDto,
  ): Promise<InitializeTenantSettingsResponseDto> {
    return this.provisioningService.initializeTenantSettings(body);
  }

  @Get('templates')
  @ApiOperation({ summary: 'List supported business catalog templates and predefined services' })
  getTemplates(): readonly TemplateRecord[] {
    return PREDEFINED_CATALOG_TEMPLATES;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FULL BUSINESS CATALOG CONFIGURATION
  // ─────────────────────────────────────────────────────────────────────────────
  @Get()
  @ApiOperation({ summary: "Get authenticated tenant's business catalog configuration" })
  @ApiOkResponse({ type: BusinessSettingsSummaryResponseDto })
  getBusinessCatalogSettings(
    @Req() request: SettingsRequest,
  ): Promise<BusinessCatalogSettingsSummary> {
    return this.settingsService.getBusinessCatalogSettings(scope(request));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────────────────────
  @Get('services')
  @ApiOperation({ summary: 'List tenant configured services' })
  @ApiOkResponse({ type: [SettingsServiceResponseDto] })
  listServices(
    @Req() request: SettingsRequest,
    @Query() query: SettingsQueryDto,
  ): Promise<readonly SettingsServiceRecord[]> {
    return this.settingsService.listServices(scope(request), query);
  }

  @Post('services')
  @ApiOperation({ summary: 'Add a service for the authenticated tenant' })
  @ApiCreatedResponse({ type: SettingsServiceResponseDto })
  createService(
    @Req() request: SettingsRequest,
    @Body() body: CreateServiceSettingsDto,
  ): Promise<SettingsServiceRecord> {
    return this.settingsService.createService(scope(request), body);
  }

  @Patch('services/:id')
  @ApiOperation({ summary: 'Update tenant service configuration' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsServiceResponseDto })
  updateService(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
    @Body() body: UpdateServiceSettingsDto,
  ): Promise<SettingsServiceRecord> {
    return this.settingsService.updateService(scope(request), id, body);
  }

  @Delete('services/:id')
  @ApiOperation({ summary: 'Safely disable/remove service from future use' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsServiceResponseDto })
  deleteService(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
  ): Promise<SettingsServiceRecord> {
    return this.settingsService.deleteService(scope(request), id);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────────────────────────
  @Get('items')
  @ApiOperation({ summary: 'List tenant configured items' })
  @ApiOkResponse({ type: [SettingsItemResponseDto] })
  listItems(
    @Req() request: SettingsRequest,
    @Query() query: SettingsQueryDto,
  ): Promise<readonly SettingsItemRecord[]> {
    return this.settingsService.listItems(scope(request), query);
  }

  @Post('items')
  @ApiOperation({ summary: 'Create an item for the authenticated tenant' })
  @ApiCreatedResponse({ type: SettingsItemResponseDto })
  createItem(
    @Req() request: SettingsRequest,
    @Body() body: CreateItemSettingsDto,
  ): Promise<SettingsItemRecord> {
    return this.settingsService.createItem(scope(request), body);
  }

  @Patch('items/:id')
  @ApiOperation({ summary: 'Update tenant item configuration' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsItemResponseDto })
  updateItem(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
    @Body() body: UpdateItemSettingsDto,
  ): Promise<SettingsItemRecord> {
    return this.settingsService.updateItem(scope(request), id, body);
  }

  @Delete('items/:id')
  @ApiOperation({ summary: 'Safely disable/remove item from future use' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsItemResponseDto })
  deleteItem(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
  ): Promise<SettingsItemRecord> {
    return this.settingsService.deleteItem(scope(request), id);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────────
  @Get('categories')
  @ApiOperation({ summary: 'List tenant categories' })
  @ApiOkResponse({ type: [SettingsCategoryResponseDto] })
  listCategories(
    @Req() request: SettingsRequest,
    @Query() query: SettingsQueryDto,
  ): Promise<readonly SettingsCategoryRecord[]> {
    return this.settingsService.listCategories(scope(request), query);
  }

  @Post('categories')
  @ApiOperation({ summary: 'Create a custom category for the authenticated tenant' })
  @ApiCreatedResponse({ type: SettingsCategoryResponseDto })
  createCategory(
    @Req() request: SettingsRequest,
    @Body() body: CreateCategorySettingsDto,
  ): Promise<SettingsCategoryRecord> {
    return this.settingsService.createCategory(scope(request), body);
  }

  @Patch('categories/:id')
  @ApiOperation({ summary: 'Update category configuration' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsCategoryResponseDto })
  updateCategory(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
    @Body() body: UpdateCategorySettingsDto,
  ): Promise<SettingsCategoryRecord> {
    return this.settingsService.updateCategory(scope(request), id, body);
  }

  @Delete('categories/:id')
  @ApiOperation({ summary: 'Safely disable/remove category from future use' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsCategoryResponseDto })
  deleteCategory(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
  ): Promise<SettingsCategoryRecord> {
    return this.settingsService.deleteCategory(scope(request), id);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PRICING
  // ─────────────────────────────────────────────────────────────────────────────
  @Get('pricing')
  @ApiOperation({ summary: 'List tenant pricing configuration' })
  @ApiOkResponse({ type: [SettingsPricingResponseDto] })
  listPricing(
    @Req() request: SettingsRequest,
    @Query('serviceId') serviceId?: string,
    @Query('itemCategoryId') itemCategoryId?: string,
    @Query('branchId') branchId?: string,
  ): Promise<readonly SettingsPricingRecord[]> {
    return this.settingsService.listPricing(scope(request), {
      serviceId,
      itemCategoryId,
      branchId,
    });
  }

  @Patch('pricing/:id')
  @ApiOperation({ summary: 'Update pricing for relevant service/item configuration' })
  @ApiParam({ name: 'id' })
  @ApiOkResponse({ type: SettingsPricingResponseDto })
  updatePricing(
    @Req() request: SettingsRequest,
    @Param('id', SettingsIdPipe) id: string,
    @Body() body: UpdatePricingSettingsDto,
  ): Promise<SettingsPricingRecord> {
    return this.settingsService.updatePricing(scope(request), id, body);
  }
}
