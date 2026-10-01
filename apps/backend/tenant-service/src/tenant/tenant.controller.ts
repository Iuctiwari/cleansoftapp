import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseFilters,
  Req,
  ForbiddenException,
} from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';

import {
  BranchDto,
  CompleteTenantOnboardingDto,
  CompleteTenantOnboardingResponseDto,
  RegisterTenantDto,
  RegisterTenantResponseDto,
  TenantProfileDto,
  UpdateTenantProfileDto,
} from './tenant.dto';
import { TenantExceptionFilter } from './tenant.filter';
import { TenantService } from './tenant.service';
import type { TenantAccessRequest } from './tenant-auth.middleware';

function assertOwnTenant(request: TenantAccessRequest, tenantId: string): void {
  if (request.tenantAccess?.tenantId !== tenantId) {
    throw new ForbiddenException('Tenant access is forbidden');
  }
}

@ApiTags('Tenants')
@UseFilters(TenantExceptionFilter)
@Controller({ path: 'tenants', version: '1' })
export class TenantController {
  constructor(private readonly tenantService: TenantService) {}

  /**
   * POST /api/v1/tenants/register
   *
   * Registers a new business tenant and creates the owner's account.
   * Returns 201 Created with the new tenant identifiers.
   */
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Register a new business tenant',
    description:
      'Creates a tenant account, owner user, head-office branch, and default service catalog entry. ' +
      'The owner email and mobile number must be globally unique. ' +
      'Returns the tenant identifiers immediately — no email verification step.',
  })
  @ApiResponse({
    status: 201,
    description: 'Tenant registered successfully',
    type: RegisterTenantResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or weak password' })
  @ApiResponse({ status: 409, description: 'Email address already registered' })
  async register(@Body() body: RegisterTenantDto): Promise<RegisterTenantResponseDto> {
    return this.tenantService.registerTenant({
      businessName: body.businessName,
      businessType: body.businessType,
      ownerName: body.ownerName,
      email: body.email,
      mobileNumber: body.mobileNumber,
      password: body.password,
      agreedToTerms: body.agreedToTerms,
    });
  }

  /**
   * GET /api/v1/tenants/:tenantId
   *
   * Retrieves the public profile of a tenant by its unique ID.
   */
  @Get(':tenantId')
  @ApiOperation({
    summary: 'Get tenant profile',
    description: 'Returns the full profile of a tenant identified by its unique tenantId.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier (24-char hex)' })
  @ApiResponse({ status: 200, description: 'Tenant profile', type: TenantProfileDto })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async getTenantById(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
  ): Promise<TenantProfileDto> {
    assertOwnTenant(request, tenantId);
    return this.tenantService.getTenantById(tenantId);
  }

  /**
   * GET /api/v1/tenants/:tenantId/branches
   *
   * Lists all branches for the given tenant.
   */
  @Get(':tenantId/branches')
  @ApiOperation({
    summary: 'List tenant branches',
    description:
      'Returns all branches registered under the specified tenant, including the head office.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier' })
  @ApiResponse({ status: 200, description: 'Branch list', type: [BranchDto] })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async listBranches(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
  ): Promise<BranchDto[]> {
    assertOwnTenant(request, tenantId);
    return this.tenantService.listBranches(tenantId);
  }

  /** Saves all tenant onboarding data in one atomic operation. */
  @Patch(':tenantId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Complete tenant onboarding',
    description:
      'Atomically updates the tenant, owner, existing head-office branch, and selected services. ' +
      'The operation is idempotent and does not create duplicate branches or services.',
  })
  @ApiParam({ name: 'tenantId', description: 'Tenant identifier returned by registration' })
  @ApiResponse({
    status: 200,
    description: 'Onboarding data saved successfully',
    type: CompleteTenantOnboardingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Request validation failed' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  @ApiResponse({ status: 409, description: 'Owner email belongs to another tenant' })
  @ApiResponse({ status: 500, description: 'Transactional database update failed' })
  async completeOnboarding(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: CompleteTenantOnboardingDto,
  ): Promise<CompleteTenantOnboardingResponseDto> {
    assertOwnTenant(request, tenantId);
    return this.tenantService.completeOnboarding(tenantId, body);
  }

  /**
   * PATCH /api/v1/tenants/:tenantId/suspend
   *
   * Suspends an active tenant (sets status to 'disabled').
   */
  @Patch(':tenantId/suspend')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Suspend a tenant',
    description:
      'Sets the tenant status to "disabled". ' +
      'Suspended tenants cannot authenticate. Returns 409 if already suspended.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier' })
  @ApiResponse({ status: 204, description: 'Tenant suspended' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  @ApiResponse({ status: 409, description: 'Tenant is already suspended' })
  async suspendTenant(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
  ): Promise<void> {
    assertOwnTenant(request, tenantId);
    await this.tenantService.suspendTenant(tenantId);
  }

  /**
   * PATCH /api/v1/tenants/:tenantId/reactivate
   *
   * Reactivates a suspended tenant (sets status back to 'active').
   */
  @Patch(':tenantId/reactivate')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Reactivate a suspended tenant',
    description:
      'Sets the tenant status back to "active". Returns 409 if the tenant is already active.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier' })
  @ApiResponse({ status: 204, description: 'Tenant reactivated' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  @ApiResponse({ status: 409, description: 'Tenant is already active' })
  async reactivateTenant(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
  ): Promise<void> {
    assertOwnTenant(request, tenantId);
    await this.tenantService.reactivateTenant(tenantId);
  }

  /**
   * PATCH /api/v1/tenants/:tenantId/profile
   *
   * Updates the tenant owner's name and/or phone number.
   */
  @Patch(':tenantId/profile')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update tenant owner profile',
    description: 'Updates ownerName and/or mobileNumber on the tenant record.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier' })
  @ApiResponse({ status: 200, description: 'Profile updated', type: TenantProfileDto })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async updateProfile(
    @Req() request: TenantAccessRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: UpdateTenantProfileDto,
  ): Promise<TenantProfileDto> {
    assertOwnTenant(request, tenantId);
    return this.tenantService.updateProfile(tenantId, body);
  }
}
