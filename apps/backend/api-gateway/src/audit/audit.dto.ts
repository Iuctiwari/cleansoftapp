import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import type { AuditClassification } from './audit.types';

export class AuditQueryDto {
  @IsOptional()
  @IsString()
  readonly module?: string;

  @IsOptional()
  @IsString()
  readonly action?: string;

  @IsOptional()
  @IsString()
  readonly actorId?: string;

  @IsOptional()
  @IsString()
  readonly targetId?: string;

  @IsOptional()
  @IsIn([
    'security',
    'financial',
    'operational',
    'compliance',
  ] satisfies readonly AuditClassification[])
  readonly classification?: AuditClassification;

  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly page = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  readonly pageSize = 20;
}

export class AuditExportRequestDto {
  @IsObject()
  readonly filters: AuditQueryDto = new AuditQueryDto();

  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;
}
