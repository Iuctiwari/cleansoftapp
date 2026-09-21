import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class PlatformAdminRefreshTokenDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  refreshToken!: string;
}
