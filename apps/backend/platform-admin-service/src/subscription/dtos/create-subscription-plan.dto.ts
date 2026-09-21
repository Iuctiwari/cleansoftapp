import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

import { ModuleKey } from '../../module-access/module-key.enum';
import { SubscriptionPlanKey } from '../subscription.types';

export class CreateSubscriptionPlanDto {
  @ApiProperty({ enum: SubscriptionPlanKey })
  @IsEnum(SubscriptionPlanKey)
  planKey!: SubscriptionPlanKey;

  @ApiProperty()
  @IsString()
  displayName!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  monthlyPriceInPaise!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  annualPriceInPaise!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  maxBranches!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  maxStaff!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  maxMonthlyOrders!: number;

  @ApiProperty({ required: false, default: 0, description: 'Free-trial length in days.' })
  @IsOptional()
  @IsInt()
  @Min(0)
  trialDays?: number;

  @ApiProperty({ enum: ModuleKey, isArray: true, required: false })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsEnum(ModuleKey, { each: true })
  includedModuleKeys?: ModuleKey[];

  @ApiProperty({ required: false, default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
