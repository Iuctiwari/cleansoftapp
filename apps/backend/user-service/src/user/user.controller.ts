import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';

import { RegisterStaffDto, StaffResponseDto, UpdateStaffDto } from './user.dto';
import { UserService } from './user.service';

@ApiTags('Users')
@Controller({ path: 'users', version: '1' })
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('roles')
  @ApiOperation({ summary: 'Get static system roles and permissions' })
  @ApiResponse({ status: 200 })
  getRoles(): unknown {
    return this.userService.getSystemRoles();
  }

  @Get('tenant/:tenantId')
  @ApiOperation({ summary: 'List all staff for a tenant' })
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiResponse({ status: 200, type: [StaffResponseDto] })
  async listStaff(@Param('tenantId') tenantId: string): Promise<StaffResponseDto[]> {
    return this.userService.listStaff(tenantId);
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
  ): Promise<StaffResponseDto> {
    return this.userService.registerStaff(tenantId, dto);
  }

  @Patch(':userId/suspend')
  @ApiOperation({ summary: 'Suspend a staff member (also disables their login)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async suspendStaff(@Param('userId') userId: string): Promise<void> {
    await this.userService.updateStatus(userId, 'Suspended');
  }

  @Patch(':userId/reactivate')
  @ApiOperation({ summary: 'Reactivate a suspended staff member (re-enables their login)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async reactivateStaff(@Param('userId') userId: string): Promise<void> {
    await this.userService.updateStatus(userId, 'Active');
  }

  @Patch(':userId')
  @ApiOperation({ summary: 'Update staff profile (name, email, role, branches, etc)' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 200, type: StaffResponseDto })
  async updateStaff(
    @Param('userId') userId: string,
    @Body() dto: UpdateStaffDto,
  ): Promise<StaffResponseDto> {
    return this.userService.updateStaff(userId, dto);
  }
  @Delete(':userId')
  @ApiOperation({ summary: 'Remove a staff member' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 204 })
  async removeStaff(@Param('userId') userId: string): Promise<void> {
    await this.userService.removeStaff(userId);
  }
}

