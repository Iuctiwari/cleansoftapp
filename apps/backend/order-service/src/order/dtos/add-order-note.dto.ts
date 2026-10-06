import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

import { ORDER_NOTE_KINDS, type OrderNoteKind } from '../order.types';

export class AddOrderNoteDto {
  @ApiProperty({ maxLength: 1000, example: 'Blue shirt has a torn sleeve.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;

  @ApiPropertyOptional({
    enum: ORDER_NOTE_KINDS,
    default: 'General',
    description: 'Damage notes are highlighted and counted on the owner Worker Tasks screen.',
  })
  @IsOptional()
  @IsIn(ORDER_NOTE_KINDS)
  kind?: OrderNoteKind;

  @ApiPropertyOptional({ description: 'Order line item the note is about, if any.' })
  @IsOptional()
  @IsMongoId()
  itemId?: string;
}
