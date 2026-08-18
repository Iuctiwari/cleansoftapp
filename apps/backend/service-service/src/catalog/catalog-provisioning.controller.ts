import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';

import { CatalogProvisioningGuard } from './catalog-provisioning.guard';
import {
  CatalogProvisioningService,
  type CatalogProvisioningResult,
} from './catalog-provisioning.service';
import {
  CatalogProvisioningResponseDto,
  ProvisionCatalogDto,
} from './dtos/catalog-provisioning.dto';

@ApiTags('Catalog Provisioning')
@Controller('catalog/provision')
@UseGuards(CatalogProvisioningGuard)
export class CatalogProvisioningController {
  constructor(private readonly provisioning: CatalogProvisioningService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Provision predefined templates into one tenant-owned catalog' })
  @ApiOkResponse({ type: CatalogProvisioningResponseDto })
  @ApiUnauthorizedResponse({ description: 'Trusted Tenant Service credentials are required.' })
  provision(@Body() body: ProvisionCatalogDto): Promise<CatalogProvisioningResult> {
    return this.provisioning.provision(body);
  }
}
