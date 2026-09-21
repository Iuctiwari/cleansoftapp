import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { BusinessTypeService } from './business-type.service';
import type { BusinessTypeRecord } from './business-type.types';
import { CreateBusinessTypeDto } from './dtos/create-business-type.dto';
import { UpdateBusinessTypeDto } from './dtos/update-business-type.dto';

@ApiTags('Platform Admin Business Types')
@Controller('platform-admin/business-types')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class BusinessTypeController {
  constructor(private readonly businessTypeService: BusinessTypeService) {}

  @Get()
  @ApiOperation({ summary: 'List configured business types' })
  list(): Promise<readonly BusinessTypeRecord[]> {
    return this.businessTypeService.list();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single business type by id' })
  findOne(@Param('id') id: string): Promise<BusinessTypeRecord> {
    return this.businessTypeService.findById(id);
  }

  @Post()
  @ApiOperation({ summary: 'Configure a new business type (references TenantBusinessType)' })
  create(@Body() body: CreateBusinessTypeDto): Promise<BusinessTypeRecord> {
    return this.businessTypeService.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a configured business type' })
  update(
    @Param('id') id: string,
    @Body() body: UpdateBusinessTypeDto,
  ): Promise<BusinessTypeRecord> {
    return this.businessTypeService.update(id, body);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remove a configured business type' })
  remove(@Param('id') id: string): Promise<void> {
    return this.businessTypeService.remove(id);
  }
}
