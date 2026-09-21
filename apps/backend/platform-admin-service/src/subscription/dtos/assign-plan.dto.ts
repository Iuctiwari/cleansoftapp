import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';

import { BillingCycle, SubscriptionPlanKey } from '../subscription.types';

export class AssignPlanDto {
  @ApiProperty({ enum: SubscriptionPlanKey })
  @IsEnum(SubscriptionPlanKey)
  planKey!: SubscriptionPlanKey;

  @ApiProperty({ enum: BillingCycle })
  @IsEnum(BillingCycle)
  billingCycle!: BillingCycle;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  trialEndsAt?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  branchLimit?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  staffLimit?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  monthlyOrderLimit?: number;

  @ApiProperty({ required: false, default: false })
  @IsOptional()
  @IsBoolean()
  autoRenew?: boolean;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
