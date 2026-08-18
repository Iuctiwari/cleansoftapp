import { IsMongoId, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

import { ItemCategoryQueryDto } from './item-category-query.dto';

export class ServiceQueryDto extends ItemCategoryQueryDto {
  @ApiPropertyOptional() @IsOptional() @IsMongoId() categoryId?: string;
}
