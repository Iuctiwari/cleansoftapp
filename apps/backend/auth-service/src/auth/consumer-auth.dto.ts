import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class ConsumerRegisterDto {
  @ApiProperty({ example: 'Riya Sharma', minLength: 2, maxLength: 80 })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  fullName!: string;

  @ApiProperty({ example: 'riya@example.com', maxLength: 160 })
  @IsEmail()
  @MaxLength(160)
  email!: string;

  @ApiProperty({ description: 'Indian mobile number', example: '9876543210', maxLength: 20 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  mobileNumber!: string;

  @ApiProperty({ example: 'MyStr0ng!Pass', maxLength: 256 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  password!: string;
}

export class ConsumerVerifyEmailDto {
  @ApiProperty({ example: 'riya@example.com', maxLength: 160 })
  @IsEmail()
  @MaxLength(160)
  email!: string;

  @ApiProperty({ description: '6-digit code sent by email', example: '123456' })
  @Matches(/^\d{6}$/)
  otp!: string;
}

export class ConsumerVerifyPhoneDto {
  @ApiProperty({ example: 'riya@example.com', maxLength: 160 })
  @IsEmail()
  @MaxLength(160)
  email!: string;

  @ApiProperty({ description: 'Firebase ID token the phone received after the SMS code was entered' })
  @IsString()
  @MaxLength(4096)
  idToken!: string;
}

export class ConsumerResendVerificationDto {
  @ApiProperty({ example: 'riya@example.com', maxLength: 160 })
  @IsEmail()
  @MaxLength(160)
  email!: string;
}
