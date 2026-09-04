import { Body, Controller, Delete, Get, Param, Patch, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';

import type { UserAccessRequest, UserAccessScope } from './user-auth.middleware';
import {
  RegisterStaffDto,
  StaffResponseDto,
  UpdateAvailabilityDto,
  UpdateStaffDto,
} from './user.dto';
import { UserService } from './user.service';

function scopeOf(request: UserAccessRequest): UserAccessScope {
  if (!request.userAccessScope) throw new Error('User authentication middleware was not applied');
  return request.userAccessScope;
}

@ApiTags('Users')
@Controller({ path: 'users', version: '1' })
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current authenticated user profile' })
  @ApiResponse({ status: 200, type: StaffResponseDto })
  async getMe(@Req() request: UserAccessRequest): Promise<StaffResponseDto> {
    return this.userService.getMe(scopeOf(request));
  }

  @Patch('me/availability')
  @ApiOperation({ summary: 'Update current user availability' })
  @ApiResponse({ status: 200, type: StaffResponseDto })
  async updateMyAvailability(
    @Body() dto: UpdateAvailabilityDto,
    @Req() request: UserAccessRequest,
  ): Promise<StaffResponseDto> {
    const scope = scopeOf(request);
    return this.userService.updateAvailability(scope, scope.actorId, dto.availability);
  }

  @Patch(':userId/availability')
  @ApiOperation({ summary: 'Update user availability' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 200, type: StaffResponseDto })
  async updateAvailability(
    @Param('userId') userId: string,
    @Body() dto: UpdateAvailabilityDto,
    @Req() request: UserAccessRequest,
  ): Promise<StaffResponseDto> {
    return this.userService.updateAvailability(scopeOf(request), userId, dto.availability);
  }

  @Get('roles')
  @ApiOperation({ summary: 'Get static system roles and permissions' })
  @ApiResponse({ status: 200 })
  getRoles(@Req() request: UserAccessRequest): unknown {
    return this.userService.getSystemRoles(scopeOf(request));
  }

  @Get('tenant/:tenantId')
  @ApiOperation({ summary: 'List all staff for a tenant' })
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiResponse({ status: 200, type: [StaffResponseDto] })
  async listStaff(
    @Req() request: UserAccessRequest,
    @Param('tenantId') tenantId: string,
  ): Promise<StaffResponseDto[]> {
    return this.userService.listStaff(scopeOf(request), tenantId);
  }

  @Post('tenant/:tenantId/register')
  @ApiOperation({
    summary: 'Register a new staff member with direct credentials',
    description:
      'Creates a user profile AND provisions loginId + password in the auth-service. ' +
      'The employee can immediately log in with loginId + password.',
  })
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiResponse({ status: 201, type: StaffResponseDto })
  async registerStaff(
    @Param('tenantId') tenantId: string,
    @Body() dto: RegisterStaffDto,
    @Req() request: UserAccessRequest,
  ): Promise<StaffResponseDto> {
    return this.userService.registerStaff(scopeOf(request), tenantId, dto);
  }

  @Patch(':userId/suspend')
  @ApiOperation({ summary: 'Suspend a staff member (also disables their login)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async suspendStaff(
    @Req() request: UserAccessRequest,
    @Param('userId') userId: string,
  ): Promise<void> {
    await this.userService.updateStatus(scopeOf(request), userId, 'Suspended');
  }

  @Patch(':userId/reactivate')
  @ApiOperation({ summary: 'Reactivate a suspended staff member (re-enables their login)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async reactivateStaff(
    @Req() request: UserAccessRequest,
    @Param('userId') userId: string,
  ): Promise<void> {
    await this.userService.updateStatus(scopeOf(request), userId, 'Active');
  }

  @Patch(':userId')
  @ApiOperation({ summary: 'Update staff profile (name, email, role, branches, etc)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 200, type: StaffResponseDto })
  async updateStaff(
    @Param('userId') userId: string,
    @Body() dto: UpdateStaffDto,
    @Req() request: UserAccessRequest,
  ): Promise<StaffResponseDto> {
    return this.userService.updateStaff(scopeOf(request), userId, dto);
  }
  @Delete(':userId')
  @ApiOperation({ summary: 'Remove a staff member' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async removeStaff(
    @Req() request: UserAccessRequest,
    @Param('userId') userId: string,
  ): Promise<void> {
    await this.userService.removeStaff(scopeOf(request), userId);
  }
}
