import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ScheduleJobDto {
  @ApiProperty({ description: 'Job schema version', example: '1.0' })
  @IsString()
  @IsNotEmpty()
  readonly version!: string;

  @ApiProperty({ description: 'Owning service or module', example: 'notification-service' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({ description: 'Tenant ID for tenant-scoped jobs' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({
    description: 'Storage reference pointing to the serialized job payload',
    example: 's3://nexoraa-jobs/payloads/abc123.json',
  })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({ description: 'SHA-256 checksum of the payload for integrity validation' })
  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;

  @ApiPropertyOptional({ description: 'Job priority (0 = lowest)', default: 0, minimum: 0 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly priority = 0;

  @ApiPropertyOptional({
    description: 'Delay in milliseconds before the job is eligible for processing',
    default: 0,
    minimum: 0,
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
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  readonly maxAttempts = 3;

  @ApiProperty({
    description: 'Client-supplied idempotency key — safe to retry if duplicate',
    example: 'job-send-receipt-order-42',
  })
  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;

  @ApiPropertyOptional({ description: 'Arbitrary key-value metadata attached to the job' })
  @IsObject()
  readonly metadata: Record<string, string | number | boolean | null> = {};
}

export class RegisterScheduleDto {
  @ApiProperty({ description: 'Owning service or module', example: 'report-service' })
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @ApiPropertyOptional({ description: 'Tenant ID for tenant-scoped schedules' })
  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @ApiProperty({ description: 'CRON expression (5-field)', example: '0 8 * * 1-5' })
  @IsString()
  @IsNotEmpty()
  readonly cron!: string;

  @ApiProperty({ description: 'IANA timezone', example: 'Asia/Kolkata' })
  @IsString()
  @IsNotEmpty()
  readonly timezone!: string;

  @ApiProperty({ description: 'Storage reference to the recurring job payload template' })
  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @ApiProperty({ description: 'SHA-256 checksum of the payload template' })
  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;
}
