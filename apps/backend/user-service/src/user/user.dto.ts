import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
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

  @ApiPropertyOptional({
    description:
      'Initial password (min 8 chars, upper + lower + digit + special). Omit when sendInvite is true — ' +
      'the staff member then sets their own password via Forgot password.',
    minLength: 8,
    maxLength: 256,
  })
  @ValidateIf((o: RegisterStaffDto) => !o.sendInvite || o.password !== undefined)
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(256)
  password?: string;

  @ApiPropertyOptional({
    description: 'Email the staff member an invitation to set their own password (needs email).',
  })
  @IsOptional()
  @IsBoolean()
  sendInvite?: boolean;

  @ApiPropertyOptional({ description: 'Business name shown in the invitation email.' })
  @IsOptional()
  @IsString()
  @MaxLength(160)
  businessName?: string;

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

  @ApiPropertyOptional({
    enum: ['default', 'custom'],
    description: "Owner only. 'custom' gives exactly the listed permissions; 'default' goes back to the role's access.",
  })
  @IsOptional()
  @IsEnum(['default', 'custom'])
  accessMode?: 'default' | 'custom';

  @ApiPropertyOptional({ type: [String], description: 'Modules to allow when accessMode is custom' })
  @IsOptional()
  @IsString({ each: true })
  permissions?: string[];
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
  @ApiPropertyOptional({ description: 'Only on register with sendInvite: whether the email went out' })
  inviteSent?: boolean;
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
  @ApiProperty({ enum: ['default', 'custom'] }) accessMode!: 'default' | 'custom';
  @ApiProperty({ type: [String], description: 'The modules allowed when accessMode is custom' })
  permissions!: string[];
  @ApiProperty() createdAt!: string;
  @ApiProperty() updatedAt!: string;
}
