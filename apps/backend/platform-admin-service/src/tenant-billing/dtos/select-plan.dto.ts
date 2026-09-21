import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

import { BillingCycle, SubscriptionPlanKey } from '../../subscription/subscription.types';

export class SelectPlanDto {
  @ApiProperty({ enum: SubscriptionPlanKey })
  @IsEnum(SubscriptionPlanKey)
  planKey!: SubscriptionPlanKey;

  @ApiProperty({ enum: BillingCycle })
  @IsEnum(BillingCycle)
  billingCycle!: BillingCycle;
}
