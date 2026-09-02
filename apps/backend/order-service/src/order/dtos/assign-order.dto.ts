import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsMongoId, IsOptional, IsString } from 'class-validator';

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

  @ApiPropertyOptional({ maxLength: 500, description: 'Optional assignment instructions or note.' })
  @IsOptional()
  @IsString()
  note?: string;
}

export class RejectAssignmentDto {
  @ApiPropertyOptional({ maxLength: 500, description: 'Optional assignment rejection reason.' })
  @IsOptional()
  reason?: string;
}
