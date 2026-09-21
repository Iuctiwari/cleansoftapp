import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class PlatformAdminLoginDto {
  @ApiProperty({ example: 'admin@nexoraa.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'a-strong-password' })
  @IsString()
  @MinLength(1)
  password!: string;
}
