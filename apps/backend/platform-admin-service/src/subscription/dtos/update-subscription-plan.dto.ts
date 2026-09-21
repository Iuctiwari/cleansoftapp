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

export class UpdateSubscriptionPlanDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  monthlyPriceInPaise?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  annualPriceInPaise?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxBranches?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxStaff?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxMonthlyOrders?: number;

  @ApiProperty({ required: false, description: 'Free-trial length in days.' })
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

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
