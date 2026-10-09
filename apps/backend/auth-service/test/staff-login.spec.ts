import { ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { AuditService } from '../src/audit/audit.service';
import { hashPassword } from '../src/auth/auth.crypto';
import { MongoAuthRepository } from '../src/auth/auth.mongo.repository';
import { AuthService } from '../src/auth/auth.service';
import type { AuthIdentityRecord, AuthRepository, AuthSessionRecord } from '../src/auth/auth.types';
import { TrustedContextFactory } from '../src/platform/platform.context';
import { StaffProvisioningController } from '../src/platform/staff-provisioning.controller';

const ownerPassword = 'Owner@2026Pass';
const staffPassword = 'Staff@2026Pass';
const metadata = { correlationId: 'c', causationId: 'c', requestId: 'r' };

function identity(overrides: Partial<AuthIdentityRecord>): AuthIdentityRecord {
  return {
    userId: 'owner-1',
    kind: 'tenant',
    email: 'shared@example.com',
    displayName: 'Owner',
    passwordHash: hashPassword(ownerPassword),
    roleCode: 'Owner',
    permissions: ['orders:read'],
    status: 'active',
    accessVersion: 1,
    tenantId: 'tenant-owner',
    tenantSlug: 'owner-shop',
    tenantName: 'Owner Shop',
    tenantStatus: 'active',
    branches: [{ branchId: 'b1', branchCode: 'main', branchName: 'Main' }],
    defaultBranchId: 'b1',
    passwordChangedAtUtc: '2026-10-01T00:00:00.000Z',
    ...overrides,
  };
}

const staff = identity({
  userId: 'staff-1',
  roleCode: 'Staff',
  displayName: 'Staff Member',
  passwordHash: hashPassword(staffPassword),
  tenantId: 'tenant-staff',
  tenantSlug: 'staff-shop',
  tenantName: 'Staff Shop',
  loginId: 'shared@example.com',
});

function createService(options: {
  owner?: AuthIdentityRecord | null;
  staff?: AuthIdentityRecord | null;
}) {
  const repository = {
    findIdentity: jest.fn().mockResolvedValue(options.owner ?? null),
    findStaffIdentity: jest.fn().mockResolvedValue(options.staff ?? null),
    getLoginTracker: jest.fn().mockResolvedValue(null),
    saveLoginTracker: jest.fn((tracker: unknown) => Promise.resolve(tracker)),
    resetLoginTracker: jest.fn().mockResolvedValue(undefined),
    listActiveSessionsByUser: jest.fn().mockResolvedValue([]),
    createSession: jest.fn((session: AuthSessionRecord) => Promise.resolve(session)),
  } as unknown as jest.Mocked<AuthRepository>;
  const config = new ConfigService({
    APP_NAME: 'Nexoraa CleanSoft',
    AUTH_ACCESS_TOKEN_SECRET: 'access-secret-that-is-longer-than-thirty-two-characters',
    AUTH_REFRESH_TOKEN_SECRET: 'refresh-secret-that-is-longer-than-thirty-two-characters',
    AUTH_ACCESS_TOKEN_TTL_SECONDS: '900',
    AUTH_REFRESH_TOKEN_TTL_SECONDS: '604800',
    AUTH_LOGIN_MAX_ATTEMPTS: '5',
    AUTH_LOCKOUT_SECONDS: '900',
    AUTH_OTP_TTL_SECONDS: '600',
    AUTH_OTP_MAX_ATTEMPTS: '5',
    AUTH_MAX_ACTIVE_SESSIONS: '3',
    AUTH_ALLOW_MULTI_DEVICE: 'true',
  });
  const audit = { recordAudit: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  return {
    repository,
    service: new AuthService(repository, audit, config, new TrustedContextFactory()),
  };
}

const login = (service: AuthService, password: string) =>
  service.login({ context: 'tenant', identifier: 'shared@example.com', password, metadata });

describe('staff who share an email with a shop owner', () => {
  it('lets the staff member in with their own password and shop', async () => {
    const { service, repository } = createService({ owner: identity({}), staff });

    const response = await login(service, staffPassword);

    expect(response.user.userId).toBe('staff-1');
    expect(response.tenant?.tenantId).toBe('tenant-staff');
    expect(repository.createSession).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'staff-1', tenantId: 'tenant-staff' }),
    );
  });

  it('still logs the owner in with the owner password', async () => {
    const { service } = createService({ owner: identity({}), staff });

    const response = await login(service, ownerPassword);

    expect(response.user.userId).toBe('owner-1');
    expect(response.tenant?.tenantId).toBe('tenant-owner');
  });

  it('refuses a password that matches neither account', async () => {
    const { service } = createService({ owner: identity({}), staff });

    await expect(login(service, 'Wrong@2026Pass')).rejects.toMatchObject({
      code: 'auth.login_denied',
    });
  });

  it('does not look for staff when the owner password is right', async () => {
    const { service, repository } = createService({ owner: identity({}), staff });

    await login(service, ownerPassword);

    expect(repository.findStaffIdentity).not.toHaveBeenCalled();
  });

  it('a staff member who is not an owner signs in as before', async () => {
    const { service } = createService({ owner: staff, staff });

    const response = await login(service, staffPassword);

    expect(response.user.userId).toBe('staff-1');
  });
});

describe('adding staff', () => {
  const dto = {
    userId: 'u1',
    tenantId: 't1',
    tenantSlug: 's',
    tenantName: 'Shop',
    loginId: 'Owner@Example.com',
    displayName: 'New Staff',
    password: 'Staff@2026Pass',
    roleCode: 'Staff',
    branchIds: ['b1'],
    sendInvite: false,
  };

  function createController(isOwner: boolean) {
    const repository = {
      isOwnerLogin: jest.fn().mockResolvedValue(isOwner),
      createStaffIdentity: jest.fn().mockResolvedValue(undefined),
    } as unknown as jest.Mocked<MongoAuthRepository>;
    const config = new ConfigService({ INTERNAL_SERVICE_SECRET: 'secret' });
    return {
      repository,
      controller: new StaffProvisioningController(repository, config, {} as never),
    };
  }

  it('refuses an email that is already a shop owner sign-in', async () => {
    const { controller, repository } = createController(true);

    await expect(controller.provision('secret', dto as never)).rejects.toBeInstanceOf(
      ConflictException,
    );
    expect(repository.createStaffIdentity).not.toHaveBeenCalled();
  });

  it('creates the staff account otherwise', async () => {
    const { controller, repository } = createController(false);

    await controller.provision('secret', dto as never);

    expect(repository.createStaffIdentity).toHaveBeenCalledWith(
      expect.objectContaining({ loginId: 'owner@example.com', userId: 'u1' }),
    );
  });
});

describe('saving a staff password', () => {
  it('writes to the staff table, never the owner table', async () => {
    const calls: string[] = [];
    const model = (name: string) => ({
      updateOne: jest.fn(() => {
        calls.push(name);
        return { exec: () => Promise.resolve({}) };
      }),
    });
    const repository = Object.create(MongoAuthRepository.prototype) as MongoAuthRepository;
    Object.assign(repository, {
      tenantOwnerModel: model('owner'),
      tenantStaffModel: model('staff'),
      platformUserModel: model('platform'),
      consumerAccountModel: model('consumer'),
    });

    await repository.replaceIdentity({ ...staff, passwordHash: 'new-hash' });
    await repository.replaceIdentity(identity({ passwordHash: 'new-hash' }));

    expect(calls).toEqual(['staff', 'owner']);
  });
});
