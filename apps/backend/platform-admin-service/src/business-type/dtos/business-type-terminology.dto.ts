import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class BusinessTypeTerminologyDto {
  @ApiProperty({ required: false, maxLength: 60, example: 'Customer' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  customerLabel?: string;

  @ApiProperty({ required: false, maxLength: 60, example: 'Order' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  orderLabel?: string;

  @ApiProperty({ required: false, maxLength: 60, example: 'Item' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  itemLabel?: string;

  @ApiProperty({ required: false, maxLength: 60, example: 'Delivery' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  deliveryLabel?: string;
}
