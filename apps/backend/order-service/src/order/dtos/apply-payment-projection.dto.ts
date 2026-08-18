import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsMongoId, Min } from 'class-validator';

export class ApplyPaymentProjectionDto {
  @ApiProperty({ description: 'Immutable Payment Management ledger identifier.' })
  @IsMongoId()
  paymentId!: string;

  @ApiProperty({ description: 'Successful payment amount in minor currency units.', minimum: 1 })
  @IsInt()
  @Min(1)
  amountMinor!: number;
}
