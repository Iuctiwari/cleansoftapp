import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';

export class ScheduleJobDto {
  @IsString()
  @IsNotEmpty()
  readonly version!: string;

  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly priority = 0;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly delayMs = 0;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  readonly maxAttempts = 3;

  @IsString()
  @IsNotEmpty()
  readonly idempotencyKey!: string;

  @IsObject()
  readonly metadata: Record<string, string | number | boolean | null> = {};
}

export class RegisterScheduleDto {
  @IsString()
  @IsNotEmpty()
  readonly owner!: string;

  @IsOptional()
  @IsString()
  readonly tenantId?: string;

  @IsString()
  @IsNotEmpty()
  readonly cron!: string;

  @IsString()
  @IsNotEmpty()
  readonly timezone!: string;

  @IsString()
  @IsNotEmpty()
  readonly payloadReference!: string;

  @IsString()
  @IsNotEmpty()
  readonly payloadChecksum!: string;
}
