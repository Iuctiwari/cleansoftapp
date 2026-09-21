import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { BillingCycle } from '../../subscription/subscription.types';

export class CreateTenantOrderDto {
  @ApiPropertyOptional({
    enum: BillingCycle,
    description: "Defaults to the tenant subscription's current billing cycle when omitted.",
  })
  @IsOptional()
  @IsEnum(BillingCycle)
  billingCycle?: BillingCycle;
}
