import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class DeclineRequestDto {
  @ApiProperty({
    maxLength: 500,
    description: 'Why the worker asks to be taken off this order (shown to the owner).',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  reason!: string;
}

export class ResolveDeclineRequestDto {
  @ApiPropertyOptional({
    maxLength: 500,
    description: 'Optional reply from the owner/branch manager, shown to the worker.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
