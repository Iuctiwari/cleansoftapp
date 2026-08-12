import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { PlatformError } from '../platform/platform.errors';
import { ManagerCandidateMongoose } from './branch.mongoose.schema';
import {
  BRANCH_MANAGER_ROLE_CODE,
  OWNER_ROLE_CODE,
  type BranchLimitProvider,
  type ManagerEligibilityService,
  type OrdersGateway,
} from './branch.types';

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
  ) {}

  async assertEligible(userId: string, tenantId: string): Promise<void> {
    const candidate = await this.candidateModel.findOne({ userId }).lean().exec();

    if (!candidate || candidate.tenantId !== tenantId) {
      // Never distinguish "not found" from "belongs to another tenant" — both
      // read as the same client-facing error so we don't leak cross-tenant existence.
      throw new PlatformError({
        code: 'branch.manager_not_found',
        category: 'validation',
        messageKey: 'errors.branch.manager_not_found',
        fields: [{ field: 'managerId', code: 'branch.manager_not_found' }],
      });
    }

    if (candidate.status !== 'active') {
      throw new PlatformError({
        code: 'branch.manager_inactive',
        category: 'conflict',
        messageKey: 'errors.branch.manager_inactive',
        fields: [{ field: 'managerId', code: 'branch.manager_inactive' }],
      });
    }

    if (!ELIGIBLE_MANAGER_ROLE_CODES.includes(candidate.roleCode)) {
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

/**
 * Stand-in for a real order-service integration — see the OrdersGateway doc
 * comment in branch.types.ts. Always reports zero non-terminal orders, i.e.
 * it never blocks a deactivation, because order-service has no `orders`
 * collection to query yet.
 */
@Injectable()
export class NullOrdersGateway implements OrdersGateway {
  private readonly logger = new Logger(NullOrdersGateway.name);

  countNonTerminalByBranch(tenantId: string, branchId: string): Promise<number> {
    this.logger.warn(
      `order-service is not implemented yet — skipping unresolved-order check for ` +
        `branch ${branchId} (tenant ${tenantId}). Deactivation will proceed unconditionally.`,
    );
    return Promise.resolve(0);
  }
}
