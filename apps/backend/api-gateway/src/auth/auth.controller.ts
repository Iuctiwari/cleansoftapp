import { Body, Controller, Post, Req } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformError } from '../platform/platform.errors';
import { TrustedContextFactory } from '../platform/platform.context';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import type { TrustedContext } from '../platform/platform.types';
import {
  AuthChangePasswordDto,
  AuthForgotPasswordDto,
  AuthLoginDto,
  AuthRefreshDto,
  AuthResetPasswordDto,
} from './auth.dto';
import {
  AuthAcknowledgementEnvelopeDto,
  AuthErrorEnvelopeDto,
  AuthLoginResponseEnvelopeDto,
  AuthRefreshResponseEnvelopeDto,
  AuthResetRequestAcknowledgementEnvelopeDto,
} from './auth-response.dto';
import { AuthService } from './auth.service';

@ApiTags('Authentication')
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Post('login')
  @ApiOperation({
    summary: 'Authenticate a platform or tenant user',
    description: 'Validates account credentials and returns access and refresh tokens.',
  })
  @ApiBody({ type: AuthLoginDto })
  @ApiOkResponse({
    description: 'Authentication succeeded and a session was created.',
    type: AuthLoginResponseEnvelopeDto,
  })
  @ApiBadRequestResponse({ description: 'The request is invalid.', type: AuthErrorEnvelopeDto })
  @ApiUnauthorizedResponse({
    description: 'The credentials are invalid or the account cannot sign in.',
    type: AuthErrorEnvelopeDto,
  })
  @ApiTooManyRequestsResponse({
    description: 'The login attempt limit has been exceeded.',
    type: AuthErrorEnvelopeDto,
  })
  async login(
    @Body() body: AuthLoginDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.authService.login({
      ...body,
      metadata: this.getMetadata(request),
    });
  }

  @Post('refresh')
  @ApiOperation({
    summary: 'Rotate refresh credentials',
    description: 'Validates a refresh token, rotates it, and issues a new access token.',
  })
  @ApiBody({ type: AuthRefreshDto })
  @ApiOkResponse({
    description: 'The refresh token was rotated successfully.',
    type: AuthRefreshResponseEnvelopeDto,
  })
  @ApiBadRequestResponse({ description: 'The request is invalid.', type: AuthErrorEnvelopeDto })
  @ApiUnauthorizedResponse({
    description: 'The refresh token or session is invalid, expired, revoked, or reused.',
    type: AuthErrorEnvelopeDto,
  })
  async refresh(
    @Body() body: AuthRefreshDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.authService.refresh({
      refreshToken: body.refreshToken,
      metadata: this.getMetadata(request),
    });
  }

  @Post('logout')
  @ApiBearerAuth(JWT_AUTH_NAME)
  @ApiOperation({
    summary: 'Log out the current session',
    description: 'Revokes the authenticated session represented by the bearer token.',
  })
  @ApiOkResponse({
    description: 'The current session was revoked or was already inactive.',
    type: AuthAcknowledgementEnvelopeDto,
  })
  @ApiUnauthorizedResponse({
    description: 'A valid access token and authenticated session are required.',
    type: AuthErrorEnvelopeDto,
  })
  async logout(@Req() request: RequestWithPlatformContext): Promise<unknown> {
    return this.authService.logout({
      context: this.getAuthorization(request),
      metadata: this.getMetadata(request),
    });
  }

  @Post('logout-all')
  @ApiBearerAuth(JWT_AUTH_NAME)
  @ApiOperation({
    summary: 'Log out all other sessions',
    description:
      'Revokes every active session for the authenticated user except the current session.',
  })
  @ApiOkResponse({
    description: 'All other active sessions were revoked.',
    type: AuthAcknowledgementEnvelopeDto,
  })
  @ApiUnauthorizedResponse({
    description: 'A valid access token and authenticated session are required.',
    type: AuthErrorEnvelopeDto,
  })
  async logoutAll(@Req() request: RequestWithPlatformContext): Promise<unknown> {
    return this.authService.logoutAll({
      context: this.getAuthorization(request),
      exceptSessionId: this.getAuthorization(request).sessionId,
      metadata: this.getMetadata(request),
    });
  }

  @Post('forgot-password')
  @ApiOperation({
    summary: 'Request a password reset',
    description:
      'Accepts an account locator and returns a neutral acknowledgement to prevent account enumeration.',
  })
  @ApiBody({ type: AuthForgotPasswordDto })
  @ApiOkResponse({
    description: 'The password-reset request was accepted.',
    type: AuthResetRequestAcknowledgementEnvelopeDto,
  })
  @ApiBadRequestResponse({ description: 'The request is invalid.', type: AuthErrorEnvelopeDto })
  async forgotPassword(
    @Body() body: AuthForgotPasswordDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.authService.forgotPassword({
      ...body,
      metadata: this.getMetadata(request),
    });
  }

  @Post('reset-password')
  @ApiOperation({
    summary: 'Reset a forgotten password',
    description: 'Validates the one-time password and replaces the account password.',
  })
  @ApiBody({ type: AuthResetPasswordDto })
  @ApiOkResponse({
    description: 'The password was reset and existing sessions were revoked.',
    type: AuthAcknowledgementEnvelopeDto,
  })
  @ApiBadRequestResponse({
    description: 'The reset proof, password, or request is invalid.',
    type: AuthErrorEnvelopeDto,
  })
  @ApiTooManyRequestsResponse({
    description: 'The reset-code attempt limit has been exceeded.',
    type: AuthErrorEnvelopeDto,
  })
  async resetPassword(
    @Body() body: AuthResetPasswordDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.authService.resetPassword({
      ...body,
      metadata: this.getMetadata(request),
    });
  }

  @Post('change-password')
  @ApiBearerAuth(JWT_AUTH_NAME)
  @ApiOperation({
    summary: 'Change the current password',
    description:
      'Verifies the current password, replaces it, and revokes the user’s other sessions.',
  })
  @ApiBody({ type: AuthChangePasswordDto })
  @ApiOkResponse({
    description: 'The password was changed and other sessions were revoked.',
    type: AuthAcknowledgementEnvelopeDto,
  })
  @ApiBadRequestResponse({
    description: 'The current password, new password, or request is invalid.',
    type: AuthErrorEnvelopeDto,
  })
  @ApiUnauthorizedResponse({
    description: 'A valid access token and authenticated session are required.',
    type: AuthErrorEnvelopeDto,
  })
  async changePassword(
    @Body() body: AuthChangePasswordDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.authService.changePassword({
      context: this.getAuthorization(request),
      currentPassword: body.currentPassword,
      newPassword: body.newPassword,
      metadata: this.getMetadata(request),
    });
  }

  private getAuthorization(request: RequestWithPlatformContext): TrustedContext {
    if (!request.trustedContext) {
      throw new PlatformError({
        code: 'platform.unauthenticated',
        category: 'unauthenticated',
        messageKey: 'errors.unauthenticated',
      });
    }

    return this.trustedContextFactory.assertTrustedContext(request.trustedContext);
  }

  private getMetadata(request: RequestWithPlatformContext): {
    readonly correlationId: string;
    readonly causationId: string;
    readonly requestId: string;
    readonly ipAddress?: string;
    readonly userAgent?: string;
  } {
    const requestId =
      this.resolveHeaderValue(request.headers['x-request-id']) ??
      request.correlationId ??
      'request-id';
    return {
      correlationId: request.correlationId ?? requestId,
      causationId: requestId,
      requestId,
      ipAddress: this.resolveHeaderValue(request.headers['x-forwarded-for']) ?? undefined,
      userAgent: this.resolveHeaderValue(request.headers['user-agent']) ?? undefined,
    };
  }

  private resolveHeaderValue(value: string | string[] | undefined): string | undefined {
    return Array.isArray(value) ? value[0] : value;
  }
}
