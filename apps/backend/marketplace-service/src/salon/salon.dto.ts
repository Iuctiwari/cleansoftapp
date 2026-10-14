import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { SLOT_LENGTHS } from './salon.logic';

export class SalonMenuItemDto {
  @ApiPropertyOptional({
    description: 'Keep the id of an existing item so old bookings still match',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  serviceId?: string;

  @ApiProperty({ example: 'Haircut' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name!: string;

  @ApiProperty({ example: 300, description: 'Price in rupees' })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  price!: number;

  @ApiProperty({ example: 30, description: 'How long the service takes, in minutes' })
  @IsInt()
  @Min(5)
  @Max(480)
  durationMinutes!: number;

  @ApiProperty({
    example: 'Hair Stylist',
    description: 'The kind of staff who do this service (must match a role on your team)',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  role!: string;

  @ApiPropertyOptional({ description: 'Price-list service this item is billed as' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  catalogServiceId?: string;

  @ApiPropertyOptional({ description: 'Price-list item this item is billed as' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  catalogItemCategoryId?: string;
}

export class SalonStaffDto {
  @ApiPropertyOptional({ description: 'Keep the id of an existing person so bookings still match' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  staffId?: string;

  @ApiProperty({ example: 'Priya' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name!: string;

  @ApiProperty({ example: 'Makeup Artist' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  role!: string;
}

/** The salon's online-booking setup: a full replace on every save. */
export class SaveSalonConfigDto {
  @ApiProperty({ enum: SLOT_LENGTHS, example: 30 })
  @IsIn(SLOT_LENGTHS)
  slotMinutes!: number;

  @ApiProperty({ type: [SalonStaffDto], description: 'The team, each with a role' })
  @ArrayMaxSize(40)
  @ValidateNested({ each: true })
  @Type(() => SalonStaffDto)
  staff!: SalonStaffDto[];

  @ApiProperty({ type: [SalonMenuItemDto] })
  @ArrayMaxSize(60)
  @ValidateNested({ each: true })
  @Type(() => SalonMenuItemDto)
  menu!: SalonMenuItemDto[];
}

const DATE = /^\d{4}-\d{2}-\d{2}$/;

export class SalonSlotsQueryDto {
  @ApiProperty({ example: '2026-10-16' })
  @Matches(DATE, { message: 'date must be YYYY-MM-DD' })
  date!: string;

  @ApiPropertyOptional({ description: 'Comma-separated menu service ids the customer chose' })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.split(',').filter(Boolean) : value,
  )
  @IsString({ each: true })
  serviceIds?: string[];
}

export class SalonScheduleQueryDto {
  @ApiProperty({ example: '2026-10-16' })
  @Matches(DATE, { message: 'date must be YYYY-MM-DD' })
  date!: string;
}

export class AssignedStaffDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  serviceId!: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  staffId!: string;
}

export class AssignSalonStaffDto {
  @ApiProperty({ type: [AssignedStaffDto], description: 'Who does which service' })
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => AssignedStaffDto)
  assignments!: AssignedStaffDto[];
}

export class SalonWalkInDto {
  @ApiProperty({ description: 'The shop customer (customer-service id) who walked in' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  customerId!: string;

  @ApiProperty({ type: [String], description: 'Menu service ids the customer wants' })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(10)
  @IsString({ each: true })
  serviceIds!: string[];
}
