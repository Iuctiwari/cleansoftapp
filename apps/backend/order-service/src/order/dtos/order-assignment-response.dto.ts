import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderAssignmentResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  orderId!: string;

  @ApiProperty()
  assignedTo!: string;

  @ApiProperty()
  assignedBy!: string;

  @ApiPropertyOptional({ format: 'date-time' })
  dueDate?: Date;

  @ApiPropertyOptional()
  note?: string;

  @ApiProperty()
  status!: string;

  @ApiProperty({ format: 'date-time' })
  createdAt!: Date;

  @ApiProperty({ format: 'date-time' })
  updatedAt!: Date;

  @ApiProperty()
  version!: number;
}
