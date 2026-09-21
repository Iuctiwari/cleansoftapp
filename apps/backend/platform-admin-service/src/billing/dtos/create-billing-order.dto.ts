import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { BillingCycle } from '../../subscription/subscription.types';

export class CreateBillingOrderDto {
  @ApiProperty({
    enum: BillingCycle,
    required: false,
    description: "Defaults to the tenant subscription's own billingCycle when omitted",
  })
  @IsOptional()
  @IsEnum(BillingCycle)
  billingCycle?: BillingCycle;
}
