export enum AdminRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  SUPPORT_ADMIN = 'SUPPORT_ADMIN',
}

export const ADMIN_USER_REPOSITORY = Symbol('ADMIN_USER_REPOSITORY');

export interface AdminUserRecord {
  readonly id: string;
  readonly email: string;
  readonly passwordHash: string;
  readonly role: AdminRole;
  readonly isActive: boolean;
  readonly lastLoginAt?: Date;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface AdminUserRepository {
  findByEmail(email: string): Promise<AdminUserRecord | null>;
  findById(id: string): Promise<AdminUserRecord | null>;
  updateLastLogin(id: string, when: Date): Promise<void>;
}

export const PLATFORM_ADMIN_ACCESS_TOKEN_TYPE = 'platform-admin-access';
export const PLATFORM_ADMIN_REFRESH_TOKEN_TYPE = 'platform-admin-refresh';
export const PLATFORM_ADMIN_TOKEN_ISSUER = 'nexoraa-platform-admin-service';
export const PLATFORM_ADMIN_TOKEN_AUDIENCE = 'nexoraa-platform-admin-client';

export interface PlatformAdminAccessTokenClaims {
  readonly sub: string;
  readonly email: string;
  readonly role: AdminRole;
  readonly type: typeof PLATFORM_ADMIN_ACCESS_TOKEN_TYPE;
}

export interface PlatformAdminRefreshTokenClaims {
  readonly sub: string;
  readonly type: typeof PLATFORM_ADMIN_REFRESH_TOKEN_TYPE;
}

export interface PlatformAdminTokenPair {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly tokenType: 'Bearer';
  readonly expiresInSeconds: number;
}

export interface PlatformAdminContext {
  readonly id: string;
  readonly email: string;
  readonly role: AdminRole;
}
