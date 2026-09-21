import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

import { verifyPassword } from './admin-auth.crypto';
import {
  ADMIN_USER_REPOSITORY,
  PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
  PLATFORM_ADMIN_REFRESH_TOKEN_TYPE,
  PLATFORM_ADMIN_TOKEN_AUDIENCE,
  PLATFORM_ADMIN_TOKEN_ISSUER,
  type AdminUserRecord,
  type AdminUserRepository,
  type PlatformAdminAccessTokenClaims,
  type PlatformAdminRefreshTokenClaims,
  type PlatformAdminTokenPair,
} from './admin-auth.types';

const INVALID_CREDENTIALS_MESSAGE = 'Invalid email or password';

@Injectable()
export class AdminAuthService {
  constructor(
    @Inject(ADMIN_USER_REPOSITORY) private readonly adminUserRepository: AdminUserRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(email: string, password: string): Promise<PlatformAdminTokenPair> {
    const admin = await this.adminUserRepository.findByEmail(email);
    if (!admin || !admin.isActive) {
      throw new UnauthorizedException(INVALID_CREDENTIALS_MESSAGE);
    }

    const passwordMatches = verifyPassword(password, admin.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException(INVALID_CREDENTIALS_MESSAGE);
    }

    await this.adminUserRepository.updateLastLogin(admin.id, new Date());

    return this.issueTokenPair(admin);
  }

  async refresh(refreshToken: string): Promise<PlatformAdminTokenPair> {
    const refreshSecret = this.configService.getOrThrow<string>(
      'PLATFORM_ADMIN_REFRESH_TOKEN_SECRET',
    );

    let claims: PlatformAdminRefreshTokenClaims;
    try {
      claims = await this.jwtService.verifyAsync<PlatformAdminRefreshTokenClaims>(refreshToken, {
        secret: refreshSecret,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (claims.type !== PLATFORM_ADMIN_REFRESH_TOKEN_TYPE) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const admin = await this.adminUserRepository.findById(claims.sub);
    if (!admin || !admin.isActive) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    return this.issueTokenPair(admin);
  }

  private async issueTokenPair(admin: AdminUserRecord): Promise<PlatformAdminTokenPair> {
    const accessSecret = this.configService.getOrThrow<string>(
      'PLATFORM_ADMIN_ACCESS_TOKEN_SECRET',
    );
    const refreshSecret = this.configService.getOrThrow<string>(
      'PLATFORM_ADMIN_REFRESH_TOKEN_SECRET',
    );
    const accessTtlSeconds = Number(
      this.configService.getOrThrow<string>('PLATFORM_ADMIN_ACCESS_TOKEN_TTL_SECONDS'),
    );
    const refreshTtlSeconds = Number(
      this.configService.getOrThrow<string>('PLATFORM_ADMIN_REFRESH_TOKEN_TTL_SECONDS'),
    );

    const accessClaims: PlatformAdminAccessTokenClaims = {
      sub: admin.id,
      email: admin.email,
      role: admin.role,
      type: PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
    };
    const refreshClaims: PlatformAdminRefreshTokenClaims = {
      sub: admin.id,
      type: PLATFORM_ADMIN_REFRESH_TOKEN_TYPE,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(accessClaims, {
        secret: accessSecret,
        expiresIn: accessTtlSeconds,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      }),
      this.jwtService.signAsync(refreshClaims, {
        secret: refreshSecret,
        expiresIn: refreshTtlSeconds,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresInSeconds: accessTtlSeconds,
    };
  }
}
