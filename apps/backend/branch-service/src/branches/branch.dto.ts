import { Type } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// Accept standard 24-hour values and common 12-hour business-time values.
// Invalid hours/minutes are still rejected at the API boundary.
const TIME_PATTERN = /^(?:([01]\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2]):[0-5]\d\s?(?:AM|PM))$/i;

export class CreateBranchDto {
  @ApiProperty({ description: 'Display name of the branch', example: 'Kothrud Branch' })
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  branchName!: string;

  @ApiPropertyOptional({
    description:
      'Optional legacy override. When omitted, the backend generates a tenant-unique NX-### code.',
    example: 'NX-001',
    maxLength: 16,
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(16)
  @Matches(/^[A-Za-z0-9-_]+$/)
  code?: string;

  @ApiPropertyOptional({ example: 'Paud Road, Kothrud' })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  streetAddress?: string;

  @ApiPropertyOptional({ example: 'Pune' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  @ApiPropertyOptional({ example: 'Maharashtra' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  state?: string;

  @ApiPropertyOptional({ example: 'India' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  country?: string;

  @ApiPropertyOptional({ example: '411038' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  postalCode?: string;

  @ApiProperty({ description: '10-digit mobile number', example: '9876543212' })
  @IsString()
  @Matches(/^\d{10}$/)
  phone!: string;

  @ApiProperty({ example: 'kothrud-branch@business.com' })
  @IsEmail()
  @MaxLength(160)
  email!: string;

  @ApiPropertyOptional({ description: 'Valid business time', example: '9:00 AM' })
  @IsOptional()
  @IsString()
  @Matches(TIME_PATTERN)
  openingTime?: string;

  @ApiPropertyOptional({ description: 'Valid business time', example: '9:00 PM' })
  @IsOptional()
  @IsString()
  @Matches(TIME_PATTERN)
  closingTime?: string;

  @ApiPropertyOptional({
    description: 'Existing tenant user to assign as branch manager',
    example: '64f1c2a9b1d4e2a1c8f9a123',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  managerId?: string;
}

export class UpdateBranchDto {
  @ApiPropertyOptional({ example: 'Kothrud Branch' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  branchName?: string;

  @ApiPropertyOptional({ example: 'KTD', maxLength: 16 })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(16)
  @Matches(/^[A-Za-z0-9-_]+$/)
  code?: string;

  @ApiPropertyOptional({ example: 'Paud Road, Kothrud' })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  streetAddress?: string;

  @ApiPropertyOptional({ example: 'Pune' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  @ApiPropertyOptional({ example: 'Maharashtra' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  state?: string;

  @ApiPropertyOptional({ example: 'India' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  country?: string;

  @ApiPropertyOptional({ example: '411038' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  postalCode?: string;

  @ApiPropertyOptional({ description: '10-digit mobile number', example: '9876543212' })
  @IsOptional()
  @IsString()
  @Matches(/^\d{10}$/)
  phone?: string;

  @ApiPropertyOptional({ example: 'kothrud-branch@business.com' })
  @IsOptional()
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @ApiPropertyOptional({ description: 'Valid business time', example: '9:00 AM' })
  @IsOptional()
  @IsString()
  @Matches(TIME_PATTERN)
  openingTime?: string;

  @ApiPropertyOptional({ description: 'Valid business time', example: '9:00 PM' })
  @IsOptional()
  @IsString()
  @Matches(TIME_PATTERN)
  closingTime?: string;

  @ApiPropertyOptional({
    description:
      'Existing tenant user to assign as branch manager. Pass null to unassign the current manager.',
    example: '64f1c2a9b1d4e2a1c8f9a123',
    nullable: true,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  managerId?: string | null;

  @ApiPropertyOptional({ enum: ['active', 'inactive'], example: 'active' })
  @IsOptional()
  @IsIn(['active', 'inactive'])
  status?: 'active' | 'inactive';
}

export class BranchQueryDto {
  @ApiPropertyOptional({ enum: ['active', 'inactive', 'closed'] })
  @IsOptional()
  @IsIn(['active', 'inactive', 'closed'])
  readonly status?: 'active' | 'inactive' | 'closed';

  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly page = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  readonly pageSize = 20;
}
