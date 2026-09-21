import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard, type PlatformAdminRequest } from '../admin-auth/platform-role.guard';
import { AssignPlanDto } from './dtos/assign-plan.dto';
import { ExtendSubscriptionDto } from './dtos/extend-subscription.dto';
import { UpdateSubscriptionStatusDto } from './dtos/update-status.dto';
import { TenantSubscriptionService } from './tenant-subscription.service';
import type { SubscriptionHistoryRecord, TenantSubscriptionRecord } from './subscription.types';

function actorId(request: PlatformAdminRequest): string {
  if (!request.platformAdmin) throw new Error('PlatformRoleGuard was not applied');
  return request.platformAdmin.id;
}

@ApiTags('Platform Admin Tenant Subscriptions')
@Controller('platform-admin/tenant-subscriptions')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class TenantSubscriptionController {
  constructor(private readonly tenantSubscriptionService: TenantSubscriptionService) {}

  @Get(':tenantId')
  @ApiOperation({ summary: "Get a tenant's current subscription" })
  async getByTenantId(@Param('tenantId') tenantId: string): Promise<TenantSubscriptionRecord> {
    const record = await this.tenantSubscriptionService.getByTenantId(tenantId);
    if (!record) throw new NotFoundException('Tenant has no subscription yet');
    return record;
  }

  @Get(':tenantId/history')
  @ApiOperation({ summary: "List a tenant's subscription history (audit log)" })
  listHistory(@Param('tenantId') tenantId: string): Promise<readonly SubscriptionHistoryRecord[]> {
    return this.tenantSubscriptionService.listHistory(tenantId);
  }

  @Post(':tenantId/assign-plan')
  @ApiOperation({ summary: 'Assign or change a tenant subscription plan' })
  assignPlan(
    @Req() request: PlatformAdminRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: AssignPlanDto,
  ): Promise<TenantSubscriptionRecord> {
    return this.tenantSubscriptionService.assignPlan(tenantId, body, actorId(request));
  }

  @Patch(':tenantId/status')
  @ApiOperation({ summary: 'Change a tenant subscription status' })
  updateStatus(
    @Req() request: PlatformAdminRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: UpdateSubscriptionStatusDto,
  ): Promise<TenantSubscriptionRecord> {
    return this.tenantSubscriptionService.updateStatus(tenantId, body, actorId(request));
  }

  @Patch(':tenantId/extend')
  @ApiOperation({ summary: 'Extend a tenant subscription end date' })
  extend(
    @Req() request: PlatformAdminRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: ExtendSubscriptionDto,
  ): Promise<TenantSubscriptionRecord> {
    return this.tenantSubscriptionService.extend(tenantId, body, actorId(request));
  }
}
