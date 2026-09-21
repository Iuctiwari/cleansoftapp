import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

import { TenantBusinessType } from '../business-type.enum';
import { BusinessTypeTerminologyDto } from './business-type-terminology.dto';

export class CreateBusinessTypeDto {
  @ApiProperty({ enum: TenantBusinessType })
  @IsEnum(TenantBusinessType)
  value!: TenantBusinessType;

  @ApiProperty({ maxLength: 120 })
  @IsString()
  @MaxLength(120)
  label!: string;

  @ApiProperty({ required: false, maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ required: false, default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiProperty({ required: false, type: BusinessTypeTerminologyDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => BusinessTypeTerminologyDto)
  defaultTerminology?: BusinessTypeTerminologyDto;

  @ApiProperty({
    required: false,
    type: [String],
    example: ['Received', 'In Progress', 'Ready', 'Delivered'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  defaultOrderStatuses?: string[];

  @ApiProperty({ required: false, type: [String], example: ['Wash & Fold', 'Dry Clean'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  defaultServices?: string[];

  @ApiProperty({ required: false, type: [String], example: ['Shirts', 'Trousers'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  defaultItemCategories?: string[];

  @ApiProperty({ required: false, type: [String], example: ['Detergent', 'Electricity'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  defaultExpenseCategories?: string[];
}
