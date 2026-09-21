import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class SetModuleAccessDto {
  @ApiProperty()
  @IsBoolean()
  isEnabled!: boolean;

  @ApiProperty({ required: false, description: 'Free-form per-module limit, future use' })
  @IsOptional()
  customLimit?: unknown;
}
