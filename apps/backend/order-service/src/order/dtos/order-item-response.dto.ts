import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderItemResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  itemCategoryId!: string;

  @ApiProperty({ type: Object })
  itemCategorySnapshot!: Record<string, unknown>;

  @ApiProperty()
  serviceId!: string;

  @ApiProperty({ type: Object })
  serviceSnapshot!: Record<string, unknown>;

  @ApiPropertyOptional()
  quantity?: number;

  @ApiPropertyOptional()
  weight?: number;

  @ApiProperty({ minimum: 0 })
  unitPrice!: number;

  @ApiProperty({ minimum: 0 })
  discount!: number;

  @ApiProperty({ minimum: 0 })
  tax!: number;

  @ApiProperty({ minimum: 0 })
  lineTotal!: number;

  @ApiPropertyOptional()
  processingStatus?: string;

  @ApiPropertyOptional()
  notes?: string;
}
