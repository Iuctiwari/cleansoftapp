import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { CatalogStatus } from '../enums';

export class SettingsQueryDto {
  @ApiPropertyOptional({ description: 'Search term by name or code' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;

  @ApiPropertyOptional({ description: 'Branch filter' })
  @IsOptional()
  @IsString()
  branchId?: string;
}
