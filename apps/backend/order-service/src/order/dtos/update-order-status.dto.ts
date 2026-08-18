import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

import { OrderStatus } from '../enums';

export class UpdateOrderStatusDto {
  @ApiProperty({
    enum: OrderStatus,
    description:
      'Existing Order status. Ready may transition directly to Delivered while Delivery integration is deferred.',
  })
  @IsEnum(OrderStatus)
  status!: OrderStatus;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
