import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ScheduleJobDto {
  @ApiProperty({ example: '1.0.0', description: 'Payload contract version for the scheduled job.' })
  @IsString()
  @IsNotEmpty()
  readonly version!: string;

  @ApiProperty({ example: 'orders.rebuild-index', description: 'Logical job owner or task code.' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({ example: 's3://internal/jobs/orders/rebuild-index.json' })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({ example: 'sha256:0f6b3d7d8426' })
  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;

  @ApiProperty({ example: 0, minimum: 0, default: 0 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly priority = 0;

  @ApiProperty({ example: 30000, minimum: 0, default: 0 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly delayMs = 0;

  @ApiProperty({ example: 3, minimum: 1, maximum: 10, default: 3 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  readonly maxAttempts = 3;

  @ApiProperty({ example: 'job-order-index-tenant-alpha-001' })
  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;

  @ApiProperty({
    type: 'object',
    additionalProperties: {
      anyOf: [{ type: 'string' }, { type: 'number' }, { type: 'boolean' }, { type: 'null' }],
    },
    example: { trigger: 'manual', source: 'api' },
  })
  @IsObject()
  readonly metadata: Record<string, string | number | boolean | null> = {};
}

export class RegisterScheduleDto {
  @ApiProperty({ example: 'orders.rebuild-index' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({ example: '0 */6 * * *', description: 'Cron expression for recurring dispatch.' })
  @IsString()
  @IsNotEmpty()
  readonly cron!: string;

  @ApiProperty({ example: 'Asia/Calcutta' })
  @IsString()
  @IsNotEmpty()
  readonly timezone!: string;

  @ApiProperty({ example: 's3://internal/jobs/orders/rebuild-index.json' })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({ example: 'sha256:0f6b3d7d8426' })
  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;
}

export class ReplayJobDto {
  @ApiProperty({
    example: 'Retry after fixing the upstream timeout.',
    description: 'Operational reason recorded in the audit trail for the replay.',
  })
  @IsString()
  @IsNotEmpty()
  readonly reason!: string;
}
