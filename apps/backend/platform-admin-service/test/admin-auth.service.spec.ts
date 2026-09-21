import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

import { AdminAuthService } from '../src/admin-auth/admin-auth.service';
import { hashPassword } from '../src/admin-auth/admin-auth.crypto';
import {
  AdminRole,
  type AdminUserRecord,
  type AdminUserRepository,
} from '../src/admin-auth/admin-auth.types';

const ACCESS_SECRET = 'a'.repeat(40);
const REFRESH_SECRET = 'b'.repeat(40);

const ENV: Record<string, string> = {
  PLATFORM_ADMIN_ACCESS_TOKEN_SECRET: ACCESS_SECRET,
  PLATFORM_ADMIN_REFRESH_TOKEN_SECRET: REFRESH_SECRET,
  PLATFORM_ADMIN_ACCESS_TOKEN_TTL_SECONDS: '900',
  PLATFORM_ADMIN_REFRESH_TOKEN_TTL_SECONDS: '604800',
};

function buildConfigService(): ConfigService {
  return {
    getOrThrow: (key: string) => {
      const value = ENV[key];
      if (!value) throw new Error(`Missing env ${key}`);
      return value;
    },
  } as unknown as ConfigService;
}

describe('AdminAuthService', () => {
  const password = 'correct-horse-battery-staple';
  const adminRecord: AdminUserRecord = {
    id: '64f0c18f7c4d2f0012ab3401',
    email: 'admin@nexoraa.com',
    passwordHash: hashPassword(password),
    role: AdminRole.SUPER_ADMIN,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  function buildService(repositoryOverrides: Partial<AdminUserRepository> = {}): AdminAuthService {
    const repository: AdminUserRepository = {
      findByEmail: jest.fn().mockResolvedValue(adminRecord),
      findById: jest.fn().mockResolvedValue(adminRecord),
      updateLastLogin: jest.fn().mockResolvedValue(undefined),
      ...repositoryOverrides,
    };

    return new AdminAuthService(repository, new JwtService(), buildConfigService());
  }

  it('(a) succeeds and issues a token pair with correct credentials', async () => {
    const service = buildService();

    const result = await service.login(adminRecord.email, password);

    expect(result.accessToken).toEqual(expect.any(String));
    expect(result.refreshToken).toEqual(expect.any(String));
    expect(result.tokenType).toBe('Bearer');
    expect(result.expiresInSeconds).toBe(900);
  });

  it('(b) fails with an UnauthorizedException on wrong password', async () => {
    const service = buildService();

    await expect(service.login(adminRecord.email, 'wrong-password')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('fails with an UnauthorizedException when the admin does not exist', async () => {
    const service = buildService({ findByEmail: jest.fn().mockResolvedValue(null) });

    await expect(service.login('nobody@nexoraa.com', password)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('fails when the admin account is deactivated', async () => {
    const service = buildService({
      findByEmail: jest.fn().mockResolvedValue({ ...adminRecord, isActive: false }),
    });

    await expect(service.login(adminRecord.email, password)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
