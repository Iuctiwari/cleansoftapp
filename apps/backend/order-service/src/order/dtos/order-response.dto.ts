import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { OrderPaymentStatus, OrderStatus } from '../enums';
import { OrderAssignmentResponseDto } from './order-assignment-response.dto';
import { OrderItemResponseDto } from './order-item-response.dto';

export class OrderResponseDto {
  @ApiProperty({ description: 'Order identifier used as the receipt orderId.' })
  id!: string;
  @ApiProperty()
  tenantId!: string;
  @ApiProperty()
  branchId!: string;
  @ApiProperty({ example: 'ORD-KTD-000001' })
  orderNumber!: string;
  @ApiProperty()
  customerId!: string;
  @ApiProperty({ type: Object })
  customerSnapshot!: Record<string, unknown>;
  @ApiProperty({ enum: OrderStatus })
  status!: OrderStatus;
  @ApiProperty({ enum: OrderPaymentStatus })
  paymentStatus!: OrderPaymentStatus;
  @ApiProperty({ type: [OrderItemResponseDto] })
  items!: OrderItemResponseDto[];
  @ApiProperty({ minimum: 0 })
  subtotal!: number;
  @ApiProperty({ minimum: 0 })
  discount!: number;

  @ApiProperty({ example: 10, maximum: 100, minimum: 0 })
  discountPercentage!: number;
  @ApiProperty({ minimum: 0 })
  tax!: number;
  @ApiProperty({ minimum: 0 })
  grandTotal!: number;
  @ApiProperty({ minimum: 0, description: 'Payment-owned paid amount projection.' })
  paidAmount!: number;
  @ApiProperty({ minimum: 0, description: 'Backend-calculated outstanding amount projection.' })
  outstandingAmount!: number;
  @ApiPropertyOptional({ format: 'date-time' })
  expectedDeliveryDate?: Date;
  @ApiPropertyOptional({ format: 'date-time' })
  deliveryDate?: Date;
  @ApiPropertyOptional()
  assignedTo?: string;
  @ApiPropertyOptional({
    type: OrderAssignmentResponseDto,
    description: 'Stored assignment details when available.',
  })
  assignment?: OrderAssignmentResponseDto;
  @ApiPropertyOptional()
  cancelReason?: string;
  @ApiProperty()
  createdBy!: string;
  @ApiProperty({ format: 'date-time' })
  createdAt!: Date;
  @ApiProperty({ format: 'date-time' })
  updatedAt!: Date;
  @ApiProperty()
  version!: number;
}

export class OrderPageResponseDto {
  @ApiProperty({ type: [OrderResponseDto] })
  items!: OrderResponseDto[];
  @ApiProperty({ minimum: 0 })
  total!: number;
  @ApiProperty({ minimum: 1 })
  page!: number;
  @ApiProperty({ minimum: 1 })
  limit!: number;
  @ApiProperty({ minimum: 0 })
  totalPages!: number;
}
