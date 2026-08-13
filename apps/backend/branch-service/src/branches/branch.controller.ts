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
  Query,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';

import { TrustedContextFactory } from '../platform/platform.context';
import { PlatformError } from '../platform/platform.errors';
import { ApiEnvelopeResponse } from '../platform/platform.swagger';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import type { TrustedContext } from '../platform/platform.types';
import { BranchQueryDto, CreateBranchDto, UpdateBranchDto } from './branch.dto';
import { BranchDto } from './branch.swagger';
import { BranchService } from './branch.service';
import type { BranchRecord } from './branch.types';

@ApiTags('Branches')
@ApiBearerAuth('access-token')
@Controller({ path: 'branches', version: '1' })
export class BranchController {
  constructor(
    private readonly branchService: BranchService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'List branches accessible to the authenticated user',
    description:
      'Owners see every branch in their tenant. Branch Managers only see branches assigned to them. ' +
      'Tenant isolation is always enforced from the authenticated context, never from a query parameter.',
  })
  @ApiEnvelopeResponse(BranchDto, {
    description: 'Branches matching the requested filters.',
    isArray: true,
  })
  async listBranches(
    @Query() query: BranchQueryDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.branchService.listBranches(
      this.getContext(request),
      { status: query.status === 'closed' ? undefined : query.status },
      { page: query.page, pageSize: query.pageSize },
    );
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a branch',
    description:
      'Owner only. tenantId is taken from the authenticated context, never from the request body. ' +
      'Enforces the subscription branchLimit and branch-code uniqueness within the tenant.',
  })
  @ApiEnvelopeResponse(BranchDto, { description: 'The created branch.', status: 'created' })
  async createBranch(
    @Body() body: CreateBranchDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<BranchRecord> {
    const context = this.getContext(request);
    return this.branchService.createBranch(context, {
      branchName: body.branchName,
      code: body.code,
      streetAddress: body.streetAddress,
      city: body.city,
      state: body.state,
      country: body.country,
      postalCode: body.postalCode,
      phone: body.phone,
      email: body.email,
      openingTime: body.openingTime,
      closingTime: body.closingTime,
      managerId: body.managerId,
    });
  }

  @Patch(':branchId')
  @ApiOperation({
    summary: 'Update a branch',
    description:
      'Owner only. Allows changing branch details, the assigned manager, and status. ' +
      'Tenant isolation and authorization are enforced server-side.',
  })
  @ApiParam({ name: 'branchId', description: 'Unique branch identifier' })
  @ApiEnvelopeResponse(BranchDto, { description: 'The updated branch.' })
  async updateBranch(
    @Param('branchId') branchId: string,
    @Body() body: UpdateBranchDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<BranchRecord> {
    return this.branchService.updateBranch(this.getContext(request), branchId, {
      branchName: body.branchName,
      code: body.code,
      streetAddress: body.streetAddress,
      city: body.city,
      state: body.state,
      country: body.country,
      postalCode: body.postalCode,
      phone: body.phone,
      email: body.email,
      openingTime: body.openingTime,
      closingTime: body.closingTime,
      managerId: body.managerId,
      status: body.status,
    });
  }

  @Delete(':branchId')
  @ApiOperation({
    summary: 'Deactivate a branch',
    description:
      'Owner only. Soft-deactivates the branch (status set to "inactive") — it is never physically deleted. ' +
      "Rejected if the branch has unresolved orders or is the tenant's last active branch.",
  })
  @ApiParam({ name: 'branchId', description: 'Unique branch identifier' })
  @ApiEnvelopeResponse(BranchDto, { description: 'The deactivated branch.' })
  async deactivateBranch(
    @Param('branchId') branchId: string,
    @Req() request: RequestWithPlatformContext,
  ): Promise<BranchRecord> {
    return this.branchService.deactivateBranch(this.getContext(request), branchId);
  }

  private getContext(request: RequestWithPlatformContext): TrustedContext {
    if (!request.trustedContext) {
      throw new PlatformError({
        code: 'platform.unauthenticated',
        category: 'unauthenticated',
        messageKey: 'errors.unauthenticated',
      });
    }

    return this.trustedContextFactory.assertTrustedContext(request.trustedContext);
  }
}
