import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { OrderStatus } from '../enums';

export class OrderHistoryResponseDto {
  @ApiProperty()
  id!: string;
  @ApiProperty()
  orderId!: string;
  @ApiProperty({ enum: OrderStatus })
  previousStatus!: OrderStatus;
  @ApiProperty({ enum: OrderStatus })
  newStatus!: OrderStatus;
  @ApiProperty()
  changedBy!: string;
  @ApiPropertyOptional()
  note?: string;
  @ApiProperty({ format: 'date-time' })
  timestamp!: Date;
}
