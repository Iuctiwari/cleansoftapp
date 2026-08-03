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
} from '@nestjs/common';
import {
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import {
  BranchDto,
  RegisterTenantDto,
  RegisterTenantResponseDto,
  TenantProfileDto,
} from './tenant.dto';
import { TenantExceptionFilter } from './tenant.filter';
import { TenantService } from './tenant.service';

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
  @ApiResponse({ status: 201, description: 'Tenant registered successfully', type: RegisterTenantResponseDto })
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
  async getTenantById(@Param('tenantId') tenantId: string): Promise<TenantProfileDto> {
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
    description: 'Returns all branches registered under the specified tenant, including the head office.',
  })
  @ApiParam({ name: 'tenantId', description: 'Unique tenant identifier' })
  @ApiResponse({ status: 200, description: 'Branch list', type: [BranchDto] })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async listBranches(@Param('tenantId') tenantId: string): Promise<BranchDto[]> {
    return this.tenantService.listBranches(tenantId);
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
  async suspendTenant(@Param('tenantId') tenantId: string): Promise<void> {
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
  async reactivateTenant(@Param('tenantId') tenantId: string): Promise<void> {
    await this.tenantService.reactivateTenant(tenantId);
  }
}
