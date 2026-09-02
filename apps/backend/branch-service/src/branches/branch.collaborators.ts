import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, Types } from 'mongoose';

import { PlatformError } from '../platform/platform.errors';
import { ManagerCandidateMongoose } from './branch.mongoose.schema';
import {
  BRANCH_MANAGER_ROLE_CODE,
  OWNER_ROLE_CODE,
  type BranchLimitProvider,
  type BranchMetrics,
  type BranchMetricsGateway,
  type ManagerEligibilityService,
  type OrdersGateway,
} from './branch.types';

interface StaffCountAggregation {
  readonly _id: string;
  readonly count: number;
}

interface OrderCountAggregation {
  readonly _id: string;
  readonly ordersToday: number;
  readonly totalOrders: number;
}

@Injectable()
export class MongoBranchMetricsGateway implements BranchMetricsGateway, OrdersGateway {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  async getMetrics(
    tenantId: string,
    branchIds: readonly string[],
  ): Promise<ReadonlyMap<string, BranchMetrics>> {
    const result = new Map<string, BranchMetrics>(
      branchIds.map((branchId) => [branchId, { ordersToday: 0, totalOrders: 0, totalStaff: 0 }]),
    );
    if (!Types.ObjectId.isValid(tenantId) || branchIds.length === 0) return result;

    const tenantObjectId = new Types.ObjectId(tenantId);
    const branchObjectIds = branchIds
      .filter((branchId) => Types.ObjectId.isValid(branchId))
      .map((branchId) => new Types.ObjectId(branchId));
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const staffPromise =
      branchObjectIds.length === 0
        ? Promise.resolve<StaffCountAggregation[]>([])
        : this.connection
            .collection('users')
            .aggregate<StaffCountAggregation>([
              {
                $match: {
                  tenantId: tenantObjectId,
                  branchIds: { $in: branchObjectIds },
                  isDeleted: false,
                },
              },
              { $unwind: '$branchIds' },
              { $match: { branchIds: { $in: branchObjectIds } } },
              { $group: { _id: { $toString: '$branchIds' }, count: { $sum: 1 } } },
            ])
            .toArray();
    const ordersPromise = this.connection
      .collection('orders')
      .aggregate<OrderCountAggregation>([
        { $match: { tenantId: tenantObjectId, branchId: { $in: [...branchIds] } } },
        {
          $group: {
            _id: '$branchId',
            totalOrders: { $sum: 1 },
            ordersToday: {
              $sum: { $cond: [{ $gte: ['$createdAt', startOfToday] }, 1, 0] },
            },
          },
        },
      ])
      .toArray();
    const [staffCounts, orderCounts] = await Promise.all([staffPromise, ordersPromise]);

    for (const item of staffCounts) {
      const current = result.get(item._id);
      if (current) result.set(item._id, { ...current, totalStaff: item.count });
    }
    for (const item of orderCounts) {
      const current = result.get(item._id);
      if (current) {
        result.set(item._id, {
          ...current,
          ordersToday: item.ordersToday,
          totalOrders: item.totalOrders,
        });
      }
    }
    return result;
  }

  async getManagerNames(
    tenantId: string,
    managerIds: readonly string[],
  ): Promise<ReadonlyMap<string, string>> {
    const names = new Map<string, string>();
    const uniqueIds = [...new Set(managerIds.filter(Boolean))];
    if (uniqueIds.length === 0) return names;

    const objectIds = uniqueIds
      .filter((id) => Types.ObjectId.isValid(id))
      .map((id) => new Types.ObjectId(id));
    const userPromise =
      Types.ObjectId.isValid(tenantId) && objectIds.length > 0
        ? this.connection
            .collection('users')
            .find(
              { _id: { $in: objectIds }, tenantId: new Types.ObjectId(tenantId), isDeleted: false },
              { projection: { name: 1 } },
            )
            .toArray()
        : Promise.resolve([]);
    const ownerPromise = this.connection
      .collection('tenantOwners')
      .find({ userId: { $in: uniqueIds }, tenantId }, { projection: { displayName: 1, userId: 1 } })
      .toArray();
    const [users, owners] = await Promise.all([userPromise, ownerPromise]);
    for (const user of users) {
      if (typeof user.name === 'string' && user.name.trim()) {
        names.set(String(user._id), user.name.trim());
      }
    }
    for (const owner of owners) {
      if (
        typeof owner.userId === 'string' &&
        typeof owner.displayName === 'string' &&
        owner.displayName.trim()
      ) {
        names.set(owner.userId, owner.displayName.trim());
      }
    }
    return names;
  }

  async countNonTerminalByBranch(tenantId: string, branchId: string): Promise<number> {
    if (!Types.ObjectId.isValid(tenantId)) return 0;
    return this.connection.collection('orders').countDocuments({
      tenantId: new Types.ObjectId(tenantId),
      branchId,
      status: { $nin: ['Delivered', 'Cancelled'] },
    });
  }
}

const ELIGIBLE_MANAGER_ROLE_CODES: readonly string[] = [OWNER_ROLE_CODE, BRANCH_MANAGER_ROLE_CODE];

/**
 * Validates a manager assignment against the tenantOwners read model. See the
 * comment on ManagerCandidateMongoose — until User Management exists, this is
 * the only queryable tenant-user directory, so only tenant owners are
 * actually assignable today. Mirrors the eligibility contract described in
 * implementation_guide/phases/phase-05-branch/02-prompt.md §3.2.
 */
@Injectable()
export class MongoManagerEligibilityService implements ManagerEligibilityService {
  constructor(
    @InjectModel(ManagerCandidateMongoose.name)
    private readonly candidateModel: Model<ManagerCandidateMongoose>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async assertEligible(userId: string, tenantId: string): Promise<void> {
    const [ownerCandidate, userCandidate] = await Promise.all([
      this.candidateModel.findOne({ userId }).lean().exec(),
      Types.ObjectId.isValid(userId) && Types.ObjectId.isValid(tenantId)
        ? this.connection.collection('users').findOne({
            _id: new Types.ObjectId(userId),
            tenantId: new Types.ObjectId(tenantId),
            isDeleted: false,
          })
        : Promise.resolve(null),
    ]);
    const candidate = ownerCandidate
      ? {
          roleCode: ownerCandidate.roleCode,
          status: ownerCandidate.status === 'active' ? 'Active' : 'Inactive',
          tenantMatches: ownerCandidate.tenantId === tenantId,
        }
      : userCandidate
        ? {
            roleCode: userCandidate.role as string,
            status: userCandidate.status as string,
            tenantMatches: true,
          }
        : null;

    if (!candidate || !candidate.tenantMatches) {
      // Never distinguish "not found" from "belongs to another tenant" — both
      // read as the same client-facing error so we don't leak cross-tenant existence.
      throw new PlatformError({
        code: 'branch.manager_not_found',
        category: 'validation',
        messageKey: 'errors.branch.manager_not_found',
        fields: [{ field: 'managerId', code: 'branch.manager_not_found' }],
      });
    }

    if (candidate.status !== 'Active') {
      throw new PlatformError({
        code: 'branch.manager_inactive',
        category: 'conflict',
        messageKey: 'errors.branch.manager_inactive',
        fields: [{ field: 'managerId', code: 'branch.manager_inactive' }],
      });
    }

    if (
      !ELIGIBLE_MANAGER_ROLE_CODES.includes(String(candidate.roleCode)) &&
      candidate.roleCode !== 'Owner' &&
      candidate.roleCode !== 'Branch Manager'
    ) {
      throw new PlatformError({
        code: 'branch.manager_not_eligible',
        category: 'conflict',
        messageKey: 'errors.branch.manager_not_eligible',
        fields: [{ field: 'managerId', code: 'branch.manager_not_eligible' }],
      });
    }
  }
}

/**
 * Stand-in for a real tenant-service `getPlanLimits()` call — see the
 * BranchLimitProvider doc comment in branch.types.ts. Configurable via
 * DEFAULT_BRANCH_LIMIT so it can be tuned without a code change; defaults to
 * 3 for this phase (no subscription/plan integration yet — see NEX-136
 * review notes). Swap this provider for a real tenant-service-backed one
 * once subscription plans are finalized; BranchService only depends on the
 * BranchLimitProvider interface, so no service-layer change is required.
 */
@Injectable()
export class ConfiguredBranchLimitProvider implements BranchLimitProvider {
  private static readonly FALLBACK_LIMIT = 3;

  private readonly logger = new Logger(ConfiguredBranchLimitProvider.name);
  private readonly defaultLimit: number;

  constructor(private readonly configService: ConfigService) {
    const configured = Number(
      this.configService.get<string>('DEFAULT_BRANCH_LIMIT') ??
        String(ConfiguredBranchLimitProvider.FALLBACK_LIMIT),
    );
    this.defaultLimit =
      Number.isInteger(configured) && configured > 0
        ? configured
        : ConfiguredBranchLimitProvider.FALLBACK_LIMIT;
  }

  getBranchLimit(tenantId: string): Promise<number> {
    this.logger.debug(
      `No subscription-plan lookup exists yet — using configured default branch limit ` +
        `(${this.defaultLimit}) for tenant ${tenantId}.`,
    );
    return Promise.resolve(this.defaultLimit);
  }
}
