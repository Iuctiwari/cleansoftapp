import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsMongoId,
  IsOptional,
} from 'class-validator';

export const BULK_ASSIGN_MAX_ORDERS = 200;
export const BULK_ASSIGN_MAX_WORKERS = 50;

export class BulkAssignDto {
  @ApiProperty({
    enum: ['auto', 'manual'],
    description:
      'auto: spread the orders evenly over workerIds, giving fewer new orders to workers ' +
      'who already have more open work. manual: give every order to the single worker in workerIds.',
  })
  @IsIn(['auto', 'manual'])
  mode!: 'auto' | 'manual';

  @ApiProperty({ type: [String], maxItems: BULK_ASSIGN_MAX_ORDERS })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(BULK_ASSIGN_MAX_ORDERS)
  @ArrayUnique()
  @IsMongoId({ each: true })
  orderIds!: string[];

  @ApiProperty({ type: [String], maxItems: BULK_ASSIGN_MAX_WORKERS })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(BULK_ASSIGN_MAX_WORKERS)
  @ArrayUnique()
  @IsMongoId({ each: true })
  workerIds!: string[];

  @ApiPropertyOptional({
    default: false,
    description: 'Return the plan without assigning anything (for the preview screen).',
  })
  @IsOptional()
  @IsBoolean()
  dryRun?: boolean;
}
