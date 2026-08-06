import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ScheduleJobDto {
  @ApiProperty({ description: 'Payload contract version for the scheduled job.', example: '1.0.0' })
  @IsString()
  @IsNotEmpty()
  readonly version!: string;

  @ApiProperty({ description: 'Logical job owner or task code.', example: 'orders.rebuild-index' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({ description: 'Tenant ID for tenant-scoped jobs', example: 'tenant-alpha' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({
    description: 'Storage reference pointing to the serialized job payload',
    example: 's3://internal/jobs/orders/rebuild-index.json',
  })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({
    description: 'SHA-256 checksum of the payload for integrity validation',
    example: 'sha256:0f6b3d7d8426',
  })
  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;

  @ApiPropertyOptional({
    description: 'Job priority (0 = lowest)',
    default: 0,
    minimum: 0,
    example: 0,
  })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly priority = 0;

  @ApiPropertyOptional({
    description: 'Delay in milliseconds before the job is eligible for processing',
    default: 0,
    minimum: 0,
    example: 30000,
  })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly delayMs = 0;

  @ApiPropertyOptional({
    description: 'Maximum number of retry attempts',
    default: 3,
    minimum: 1,
    maximum: 10,
    example: 3,
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  readonly maxAttempts = 3;

  @ApiProperty({
    description: 'Client-supplied idempotency key — safe to retry if duplicate',
    example: 'job-order-index-tenant-alpha-001',
  })
  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;

  @ApiPropertyOptional({
    description: 'Arbitrary key-value metadata attached to the job',
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
  @ApiProperty({ description: 'Owning service or module', example: 'orders.rebuild-index' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({
    description: 'Tenant ID for tenant-scoped schedules',
    example: 'tenant-alpha',
  })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({ description: 'Cron expression for recurring dispatch.', example: '0 */6 * * *' })
  @IsString()
  @IsNotEmpty()
  readonly cron!: string;

  @ApiProperty({ description: 'IANA timezone', example: 'Asia/Calcutta' })
  @IsString()
  @IsNotEmpty()
  readonly timezone!: string;

  @ApiProperty({
    description: 'Storage reference to the recurring job payload template',
    example: 's3://internal/jobs/orders/rebuild-index.json',
  })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({
    description: 'SHA-256 checksum of the payload template',
    example: 'sha256:0f6b3d7d8426',
  })
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
