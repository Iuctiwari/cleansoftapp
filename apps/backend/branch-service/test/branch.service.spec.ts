import { Permissions } from '@nexoraa/shared';
import { BranchService } from '../src/branches/branch.service';
import type {
  BranchLimitProvider,
  BranchMetricsGateway,
  BranchRecord,
  BranchRepository,
  ManagerEligibilityService,
  OrdersGateway,
} from '../src/branches/branch.types';
import { TRUSTED_CONTEXT_TOKEN, type TrustedContext } from '../src/platform/platform.types';

describe('BranchService', () => {
  let service: BranchService;
  let mockBranchRepository: jest.Mocked<BranchRepository>;
  let mockManagerEligibilityService: jest.Mocked<ManagerEligibilityService>;
  let mockBranchLimitProvider: jest.Mocked<BranchLimitProvider>;
  let mockOrdersGateway: jest.Mocked<OrdersGateway>;
  let mockBranchMetricsGateway: jest.Mocked<BranchMetricsGateway>;

  const tenantId = '60d5ecb8b392a71500000000';
  const branchId1 = '60d5ecb8b392a71500000001';
  const branchId2 = '60d5ecb8b392a71500000002';

  const ownerContext: TrustedContext = {
    kind: 'tenant',
    actorId: '60d5ecb8b392a71500000099',
    actorType: 'user',
    tenantId,
    roleCode: 'Owner',
    permissions: [Permissions.branchesRead, Permissions.branchesWrite],
    correlationId: 'test-correlation-id',
    causationId: 'test-causation-id',
    requestId: 'test-request-id',
    accessVersion: 1,
    [TRUSTED_CONTEXT_TOKEN]: true,
  };

  const branchManagerContext: TrustedContext = {
    kind: 'tenant',
    actorId: '60d5ecb8b392a71500000088',
    actorType: 'user',
    tenantId,
    branchId: branchId1,
    roleCode: 'Branch Manager',
    permissions: [Permissions.branchesRead],
    correlationId: 'test-correlation-id',
    causationId: 'test-causation-id',
    requestId: 'test-request-id',
    accessVersion: 1,
    [TRUSTED_CONTEXT_TOKEN]: true,
  };

  const sampleBranch1: BranchRecord = {
    branchId: branchId1,
    tenantId,
    code: 'BR-001',
    branchName: 'Main Branch',
    streetAddress: '123 Main St',
    city: 'Dubai',
    state: 'Dubai',
    country: 'UAE',
    postalCode: '00000',
    phone: '+971500000001',
    email: 'main@example.com',
    status: 'active',
    isHeadOffice: false,
    managerId: '60d5ecb8b392a71500000088',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  const sampleBranch2: BranchRecord = {
    branchId: branchId2,
    tenantId,
    code: 'BR-002',
    branchName: 'Secondary Branch',
    streetAddress: '456 Side St',
    city: 'Dubai',
    state: 'Dubai',
    country: 'UAE',
    postalCode: '00000',
    phone: '+971500000002',
    email: 'secondary@example.com',
    status: 'active',
    isHeadOffice: false,
    managerId: undefined,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  beforeEach(() => {
    mockBranchRepository = {
      list: jest.fn(),
      findByBranchIdAndTenant: jest.fn(),
      findByCodeAndTenant: jest.fn(),
      countActiveByTenant: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      listCodesByTenant: jest.fn().mockResolvedValue([]),
    };
    mockManagerEligibilityService = {
      assertEligible: jest.fn(),
    };
    mockBranchLimitProvider = {
      getBranchLimit: jest.fn().mockResolvedValue(5),
    };
    mockOrdersGateway = {
      countNonTerminalByBranch: jest.fn().mockResolvedValue(0),
    };
    mockBranchMetricsGateway = {
      getMetrics: jest.fn().mockImplementation((_tenantId, branchIds: readonly string[]) => {
        const metricsMap = new Map();
        if (branchIds.includes(branchId1)) {
          metricsMap.set(branchId1, { totalStaff: 4, totalOrders: 15, ordersToday: 3 });
        }
        if (branchIds.includes(branchId2)) {
          metricsMap.set(branchId2, { totalStaff: 2, totalOrders: 8, ordersToday: 1 });
        }
        return Promise.resolve(metricsMap);
      }),
      getManagerNames: jest
        .fn()
        .mockResolvedValue(new Map([['60d5ecb8b392a71500000088', 'Alice Manager']])),
    };

    service = new BranchService(
      mockBranchRepository,
      mockManagerEligibilityService,
      mockBranchLimitProvider,
      mockOrdersGateway,
      mockBranchMetricsGateway,
    );
  });

  describe('statistics', () => {
    it('aggregates real staff and order metrics tenant-wide for Owner', async () => {
      mockBranchRepository.list.mockResolvedValue({
        items: [sampleBranch1, sampleBranch2],
        total: 2,
        page: 1,
        pageSize: 10000,
      });

      const stats = await service.statistics(ownerContext, {});

      expect(stats).toEqual({
        totalBranches: 2,
        totalStaff: 6,
        totalOrders: 23,
        ordersToday: 4,
      });
      expect(mockBranchRepository.list).toHaveBeenCalledWith(
        tenantId,
        {},
        { page: 1, pageSize: 10000 },
      );
      expect(mockBranchMetricsGateway.getMetrics).toHaveBeenCalledWith(tenantId, [
        branchId1,
        branchId2,
      ]);
    });

    it('scopes statistics strictly to the assigned branch for Branch Manager', async () => {
      mockBranchRepository.list.mockResolvedValue({
        items: [sampleBranch1],
        total: 1,
        page: 1,
        pageSize: 10000,
      });

      const stats = await service.statistics(branchManagerContext, {});

      expect(stats).toEqual({
        totalBranches: 1,
        totalStaff: 4,
        totalOrders: 15,
        ordersToday: 3,
      });
      expect(mockBranchRepository.list).toHaveBeenCalledWith(
        tenantId,
        { branchId: branchId1 },
        { page: 1, pageSize: 10000 },
      );
    });
  });

  describe('listBranches and getBranch isolation', () => {
    it('enriches branch with manager name and metrics for Owner', async () => {
      mockBranchRepository.findByBranchIdAndTenant.mockResolvedValue(sampleBranch1);

      const branch = await service.getBranch(ownerContext, branchId1);

      expect(branch.branchName).toBe('Main Branch');
      expect(branch.managerName).toBe('Alice Manager');
      expect(branch.totalStaff).toBe(4);
      expect(branch.totalOrders).toBe(15);
    });

    it('denies Branch Manager access to unassigned branch', async () => {
      mockBranchRepository.findByBranchIdAndTenant.mockResolvedValue(sampleBranch2);

      await expect(service.getBranch(branchManagerContext, branchId2)).rejects.toMatchObject({
        code: 'branch.not_found',
      });
    });

    it('scopes listBranches to assigned branch for Branch Manager', async () => {
      mockBranchRepository.list.mockResolvedValue({
        items: [sampleBranch1],
        total: 1,
        page: 1,
        pageSize: 20,
      });

      const result = await service.listBranches(
        branchManagerContext,
        {},
        { page: 1, pageSize: 20 },
      );

      expect(mockBranchRepository.list).toHaveBeenCalledWith(
        tenantId,
        { branchId: branchId1 },
        { page: 1, pageSize: 20 },
      );
      expect(result.items).toHaveLength(1);
      expect(result.items[0].branchId).toBe(branchId1);
    });
  });
});
