import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { TenantOwnerMongoose, type TenantOwnerDocument } from './payment-owner.schema';

const OWNER_ROLE_CODE = 'tenant_owner';

/**
 * Resolves the active tenant Owner's userId for a given tenant, so Payment
 * Service can notify them in addition to whichever recipient the existing
 * notification logic already targets. Read-only against the tenantOwners
 * collection — see payment-owner.schema.ts.
 */
@Injectable()
export class PaymentOwnerLookupService {
  constructor(
    @InjectModel(TenantOwnerMongoose.name)
    private readonly tenantOwners: Model<TenantOwnerDocument>,
  ) {}

  async findOwnerId(tenantId: string): Promise<string | undefined> {
    const owner = await this.tenantOwners
      .findOne({ tenantId, roleCode: OWNER_ROLE_CODE, status: 'active' })
      .lean()
      .exec();
    return owner?.userId;
  }
}
