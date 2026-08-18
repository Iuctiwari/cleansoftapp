import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsMongoId, IsOptional } from 'class-validator';

export class AssignOrderDto {
  @ApiProperty({
    description:
      'Worker identifier stored on the scoped order. User/Staff eligibility validation is deferred.',
  })
  @IsMongoId()
  assignedTo!: string;

  @ApiPropertyOptional({ format: 'date-time' })
  @IsOptional()
  @IsDateString({ strict: true })
  dueDate?: string;
}
