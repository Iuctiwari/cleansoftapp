import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import type { AuditClassification } from './audit.types';

export class AuditQueryDto {
  @ApiPropertyOptional({ example: 'auth' })
  @IsOptional()
  @IsString()
  readonly module?: string;

  @ApiPropertyOptional({ example: 'login_success' })
  @IsOptional()
  @IsString()
  readonly action?: string;

  @ApiPropertyOptional({ example: 'platform-admin-1' })
  @IsOptional()
  @IsString()
  readonly actorId?: string;

  @ApiPropertyOptional({ example: 'session-9d6cb4d6' })
  @IsOptional()
  @IsString()
  readonly targetId?: string;

  @ApiPropertyOptional({
    enum: ['security', 'financial', 'operational', 'compliance'],
    example: 'security',
  })
  @IsOptional()
  @IsIn([
    'security',
    'financial',
    'operational',
    'compliance',
  ] satisfies readonly AuditClassification[])
  readonly classification?: AuditClassification;

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({ example: 1, minimum: 1, default: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly page = 1;

  @ApiProperty({ example: 20, minimum: 1, maximum: 100, default: 20 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  readonly pageSize = 20;
}

export class AuditExportRequestDto {
  @ApiProperty({ type: AuditQueryDto })
  @IsObject()
  readonly filters: AuditQueryDto = new AuditQueryDto();

  @ApiProperty({
    example: 'audit-export-20260803-01',
    description: 'Idempotency key used to deduplicate export requests.',
  })
  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;
}
