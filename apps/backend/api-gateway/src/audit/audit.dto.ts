import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import type { AuditClassification } from './audit.types';

export class AuditQueryDto {
  @ApiPropertyOptional({ description: 'Filter by module name', example: 'auth' })
  @IsOptional()
  @IsString()
  readonly module?: string;

  @ApiPropertyOptional({ description: 'Filter by action performed', example: 'login' })
  @IsOptional()
  @IsString()
  readonly action?: string;

  @ApiPropertyOptional({ description: 'Filter by actor (user or service) ID' })
  @IsOptional()
  @IsString()
  readonly actorId?: string;

  @ApiPropertyOptional({ description: 'Filter by target entity ID' })
  @IsOptional()
  @IsString()
  readonly targetId?: string;

  @ApiPropertyOptional({
    description: 'Audit classification level',
    enum: ['security', 'financial', 'operational', 'compliance'],
  })
  @IsOptional()
  @IsIn([
    'security',
    'financial',
    'operational',
    'compliance',
  ] satisfies readonly AuditClassification[])
  readonly classification?: AuditClassification;

  @ApiPropertyOptional({ description: 'Filter by tenant ID (platform operators only)' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiPropertyOptional({ description: 'Page number (1-based)', default: 1, minimum: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly page = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 20, minimum: 1, maximum: 100 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  readonly pageSize = 20;
}

export class AuditExportRequestDto {
  @ApiProperty({ description: 'Audit query filter criteria', type: AuditQueryDto })
  @IsObject()
  readonly filters: AuditQueryDto = new AuditQueryDto();

  @ApiProperty({
    description: 'Client-supplied idempotency key for the export request',
    example: 'export-2026-q1-001',
  })
  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;
}
