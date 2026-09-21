import { Body, Controller, Post } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AdminAuthService } from './admin-auth.service';
import { PlatformAdminLoginDto } from './dtos/login.dto';
import { PlatformAdminRefreshTokenDto } from './dtos/refresh-token.dto';
import type { PlatformAdminTokenPair } from './admin-auth.types';

@ApiTags('Platform Admin Auth')
@Controller('platform-admin/auth')
export class AdminAuthController {
  constructor(private readonly adminAuthService: AdminAuthService) {}

  @Post('login')
  @ApiOperation({ summary: 'Authenticate a Nexoraa platform admin and issue a token pair' })
  @ApiOkResponse({ description: 'Access and refresh token pair for the platform admin' })
  login(@Body() body: PlatformAdminLoginDto): Promise<PlatformAdminTokenPair> {
    return this.adminAuthService.login(body.email, body.password);
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Exchange a valid platform admin refresh token for a new token pair' })
  @ApiOkResponse({ description: 'New access and refresh token pair for the platform admin' })
  refresh(@Body() body: PlatformAdminRefreshTokenDto): Promise<PlatformAdminTokenPair> {
    return this.adminAuthService.refresh(body.refreshToken);
  }
}
