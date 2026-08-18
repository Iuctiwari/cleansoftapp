import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsMongoId, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class QuoteQueryDto {
  @ApiProperty() @IsMongoId() itemCategoryId!: string;
  @ApiPropertyOptional({ description: 'Must match the authenticated branch when supplied.' })
  @IsOptional()
  @IsString()
  branchId?: string;
  @ApiPropertyOptional({ minimum: 0.000001 })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsNumber()
  @Min(0.000001)
  quantity?: number;
  @ApiPropertyOptional({ minimum: 0.000001 })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsNumber()
  @Min(0.000001)
  weight?: number;
  @ApiPropertyOptional({ description: 'UTC effective timestamp; defaults to now.' })
  @IsOptional()
  @IsDateString()
  effectiveAt?: string;
}
