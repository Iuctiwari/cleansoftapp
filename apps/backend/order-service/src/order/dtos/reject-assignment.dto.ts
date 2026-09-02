import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RejectAssignmentDto {
  @ApiPropertyOptional({ maxLength: 500, description: 'Optional worker rejection reason.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
