import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { StaffAvailability, UserRole, UserStatus } from './user.types';

export class RegisterStaffDto {
  @ApiProperty({ example: 'John Doe', maxLength: 120 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;

  @ApiProperty({
    description:
      'Unique login username for this employee within the tenant (e.g. john.doe, emp001)',
    example: 'john.doe',
    maxLength: 64,
  })
  @IsString()
  @IsNotEmpty()
  @IsEmail()
  @MaxLength(160)
  loginId!: string;

  @ApiProperty({
    description: 'Initial password for the employee (min 8 chars, upper + lower + digit + special)',
    minLength: 8,
    maxLength: 256,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(256)
  password!: string;

  @ApiPropertyOptional({ example: 'john@example.com', maxLength: 160 })
  @IsOptional()
  @ValidateIf((o, value) => value !== '')
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @ApiPropertyOptional({ example: '+971501234567' })
  @IsOptional()
  @ValidateIf((o, value) => value !== '')
  @IsString()
  @Matches(/^\+?[0-9]{7,15}$/)
  mobileNumber?: string;

  @ApiPropertyOptional({ example: 'Finance' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  department?: string;

  @ApiProperty({ enum: ['Owner', 'Branch Manager', 'Staff', 'Cashier'], example: 'Staff' })
  @IsEnum(['Owner', 'Branch Manager', 'Staff', 'Cashier'])
  role!: UserRole;

  @ApiProperty({
    type: [String],
    description: 'List of Branch IDs',
    example: ['60d5ecb8b392a71500000000'],
  })
  @IsString({ each: true })
  branchIds!: string[];
}

export class UpdateStaffDto {
  @ApiPropertyOptional({ example: 'John Doe', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({ example: 'john@example.com', maxLength: 160 })
  @IsOptional()
  @ValidateIf((o, value) => value !== '')
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @ApiPropertyOptional({ example: '+971501234567' })
  @IsOptional()
  @ValidateIf((o, value) => value !== '')
  @IsString()
  @Matches(/^\+?[0-9]{7,15}$/)
  mobileNumber?: string;

  @ApiPropertyOptional({ example: 'Finance' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  department?: string;

  @ApiPropertyOptional({ enum: ['Owner', 'Branch Manager', 'Staff', 'Cashier'], example: 'Staff' })
  @IsOptional()
  @IsEnum(['Owner', 'Branch Manager', 'Staff', 'Cashier'])
  role?: UserRole;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsString({ each: true })
  branchIds?: string[];
}

export class UpdateAvailabilityDto {
  @ApiProperty({
    enum: ['Available', 'Busy', 'On Break', 'Offline'],
    example: 'Available',
  })
  @IsString()
  @IsNotEmpty()
  @IsEnum(['Available', 'Busy', 'On Break', 'Offline'])
  availability!: StaffAvailability;
}

export class StaffResponseDto {
  @ApiProperty() userId!: string;
  @ApiProperty() tenantId!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ description: 'Login username — read-only after creation' }) loginId!: string;
  @ApiPropertyOptional() email?: string;
  @ApiPropertyOptional() mobileNumber?: string;
  @ApiPropertyOptional() department?: string;
  @ApiProperty({ enum: ['Owner', 'Branch Manager', 'Staff', 'Cashier'] }) role!: UserRole;
  @ApiProperty({ type: [String] }) branchIds!: string[];
  @ApiProperty({ enum: ['Active', 'Suspended'] }) status!: UserStatus;
  @ApiProperty({ enum: ['Available', 'Busy', 'On Break', 'Offline'], example: 'Available' })
  availability!: StaffAvailability;
  @ApiProperty() createdAt!: string;
  @ApiProperty() updatedAt!: string;
}
