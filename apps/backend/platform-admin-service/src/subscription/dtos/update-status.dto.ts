import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { TenantSubscriptionStatus } from '../subscription.types';

export class UpdateSubscriptionStatusDto {
  @ApiProperty({ enum: TenantSubscriptionStatus })
  @IsEnum(TenantSubscriptionStatus)
  status!: TenantSubscriptionStatus;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  reason?: string;
}
