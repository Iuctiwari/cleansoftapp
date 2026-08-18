import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CancelOrderDto {
  @ApiProperty({ maxLength: 500, description: 'Mandatory cancellation reason.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  reason!: string;
}
