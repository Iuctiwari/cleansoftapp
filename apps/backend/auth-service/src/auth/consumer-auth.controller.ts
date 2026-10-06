import { Body, Controller, Get, HttpCode, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';

import type { RequestWithPlatformContext } from '../platform/platform.request';
import {
  ConsumerRegisterDto,
  ConsumerResendVerificationDto,
  ConsumerVerifyEmailDto,
} from './consumer-auth.dto';
import { ConsumerAuthService } from './consumer-auth.service';

/**
 * Marketplace customer sign-up. After verifying the email, the app signs in
 * with POST /v1/auth/login { context: "consumer", identifier, password }.
 */
@ApiTags('Consumer authentication')
@Controller({ path: 'auth/consumer', version: '1' })
export class ConsumerAuthController {
  constructor(private readonly consumerAuthService: ConsumerAuthService) {}

  @Post('register')
  @HttpCode(201)
  @ApiOperation({ summary: 'Create a customer account and email a 6-digit verification code' })
  async register(@Body() body: ConsumerRegisterDto): Promise<unknown> {
    return this.consumerAuthService.register(body);
  }

  @Post('verify-email')
  @HttpCode(200)
  @ApiOperation({ summary: 'Verify the customer email with the 6-digit code' })
  async verifyEmail(@Body() body: ConsumerVerifyEmailDto): Promise<unknown> {
    return this.consumerAuthService.verifyEmail(body);
  }

  @Post('resend-verification')
  @HttpCode(200)
  @ApiOperation({ summary: 'Send a new verification code (at most once a minute)' })
  async resendVerification(@Body() body: ConsumerResendVerificationDto): Promise<unknown> {
    return this.consumerAuthService.resendVerification(body);
  }

  @Get('context')
  @ApiBearerAuth('access-token')
  @ApiOperation({
    summary: 'Resolve the signed-in customer (used by marketplace-service to authenticate)',
  })
  @ApiOkResponse({ description: 'The signed-in customer profile.' })
  async context(@Req() request: RequestWithPlatformContext): Promise<unknown> {
    return this.consumerAuthService.profile(request.trustedContext);
  }
}
