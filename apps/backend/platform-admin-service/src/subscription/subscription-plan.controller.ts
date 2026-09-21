import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { CreateSubscriptionPlanDto } from './dtos/create-subscription-plan.dto';
import { UpdateSubscriptionPlanDto } from './dtos/update-subscription-plan.dto';
import { SubscriptionPlanService } from './subscription-plan.service';
import type { SubscriptionPlanRecord } from './subscription.types';

@ApiTags('Platform Admin Subscription Plans')
@Controller('platform-admin/subscription-plans')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class SubscriptionPlanController {
  constructor(private readonly subscriptionPlanService: SubscriptionPlanService) {}

  @Get()
  @ApiOperation({ summary: 'List configured subscription plans' })
  list(): Promise<readonly SubscriptionPlanRecord[]> {
    return this.subscriptionPlanService.list();
  }

  @Get('tenant-counts')
  @ApiOperation({ summary: 'How many tenants are currently on each plan, keyed by planKey' })
  tenantCounts(): Promise<Readonly<Record<string, number>>> {
    return this.subscriptionPlanService.tenantCountsByPlan();
  }

  @Get(':planKey')
  @ApiOperation({ summary: 'Get a single subscription plan by planKey' })
  findOne(@Param('planKey') planKey: string): Promise<SubscriptionPlanRecord> {
    return this.subscriptionPlanService.findByPlanKey(planKey);
  }

  @Post()
  @ApiOperation({ summary: 'Configure a new subscription plan' })
  create(@Body() body: CreateSubscriptionPlanDto): Promise<SubscriptionPlanRecord> {
    return this.subscriptionPlanService.create(body);
  }

  @Patch(':planKey')
  @ApiOperation({ summary: 'Update a configured subscription plan' })
  update(
    @Param('planKey') planKey: string,
    @Body() body: UpdateSubscriptionPlanDto,
  ): Promise<SubscriptionPlanRecord> {
    return this.subscriptionPlanService.update(planKey, body);
  }

  @Delete(':planKey')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Delete a subscription plan (rejected if any tenant is still assigned to it)',
  })
  remove(@Param('planKey') planKey: string): Promise<void> {
    return this.subscriptionPlanService.remove(planKey);
  }
}
