import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import {
  createActiveTenantFilter,
  createAuditFields,
  createSoftDeleteUpdate,
} from '@nexoraa/database';
import { Types, type Model } from 'mongoose';

import { CustomerMongoose, CustomerSource, CustomerType } from './customer.mongoose.schema';
import type {
  CreateCustomerFields,
  CustomerListQuery,
  CustomerMutableFields,
  CustomerPage,
  CustomerRecord,
  CustomerRepository,
  CustomerScope,
  CustomerStatistics,
  OnlineCustomerInput,
  OnlineCustomerLink,
} from './customer.types';

function escapeRegularExpression(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Matches a 10-digit mobile however the shop typed it: "9876543210",
 * "+91 98765 43210", "098765-43210", "919876543210".
 */
export function mobileMatcher(tenDigits: string): RegExp {
  return new RegExp(`^\\s*(\\+?\\s*91|0)?[\\s-]*${tenDigits.split('').join('[\\s-]*')}\\s*$`);
}

function isDuplicateKeyError(error: unknown): boolean {
  return (error as { code?: number } | null)?.code === 11000;
}

@Injectable()
export class MongoCustomerRepository implements CustomerRepository {
  constructor(
    @InjectModel(CustomerMongoose.name)
    private readonly customerModel: Model<CustomerMongoose>,
  ) {}

  async create(scope: CustomerScope, input: CreateCustomerFields): Promise<CustomerRecord> {
    const customer = await this.customerModel.create({
      ...createAuditFields(scope.actorId),
      tenantId: new Types.ObjectId(scope.tenantId),
      branchId: scope.branchId,
      name: input.name,
      mobile: input.mobile,
      email: input.email,
      address: input.address,
      customerType: input.customerType,
      joiningDate: input.joiningDate ?? new Date(),
      totalOrders: 0,
      totalSpent: 0,
      outstandingBalance: 0,
      lastOrderDate: null,
    });

    return this.mapCustomer(customer.toObject() as unknown as Record<string, unknown>);
  }

  async findById(scope: CustomerScope, id: string): Promise<CustomerRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;

    const customer = await this.customerModel
      .findOne(
        createActiveTenantFilter<CustomerMongoose>(scope.tenantId, {
          _id: id,
          branchId: scope.branchId,
        }),
      )
      .lean()
      .exec();
    return customer ? this.mapCustomer(customer) : null;
  }

  async list(scope: CustomerScope, query: CustomerListQuery): Promise<CustomerPage> {
    const filter: Record<string, unknown> = createActiveTenantFilter<CustomerMongoose>(
      scope.tenantId,
      {
        branchId: scope.branchId,
      },
    );
    if (query.source === CustomerSource.ONLINE) filter.source = CustomerSource.ONLINE;
    // Records created before `source` existed have no value and count as shop-entered.
    if (query.source === CustomerSource.SHOP) filter.source = { $ne: CustomerSource.ONLINE };
    const search = query.search?.trim();
    if (search) {
      const expression = new RegExp(escapeRegularExpression(search), 'i');
      filter.$or = [{ name: expression }, { mobile: expression }];
    }

    const skip = (query.page - 1) * query.limit;
    const [customers, total] = await Promise.all([
      this.customerModel
        .find(filter)
        .sort({ createdAt: -1, _id: -1 })
        .skip(skip)
        .limit(query.limit)
        .lean()
        .exec(),
      this.customerModel.countDocuments(filter).exec(),
    ]);

    return {
      items: customers.map((customer) => this.mapCustomer(customer)),
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  async update(
    scope: CustomerScope,
    id: string,
    input: CustomerMutableFields,
  ): Promise<CustomerRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;

    const setFields: Record<string, unknown> = { updatedBy: scope.actorId };
    const unsetFields: Record<string, 1> = {};
    for (const [field, value] of Object.entries(input)) {
      if (value === null) unsetFields[field] = 1;
      else setFields[field] = value;
    }

    const customer = await this.customerModel
      .findOneAndUpdate(
        createActiveTenantFilter<CustomerMongoose>(scope.tenantId, {
          _id: id,
          branchId: scope.branchId,
        }),
        {
          $set: setFields,
          ...(Object.keys(unsetFields).length > 0 ? { $unset: unsetFields } : {}),
        },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    return customer ? this.mapCustomer(customer) : null;
  }

  async linkOnlineCustomer(
    tenantId: string,
    branchId: string,
    input: OnlineCustomerInput,
  ): Promise<OnlineCustomerLink> {
    const scopeFilter = createActiveTenantFilter<CustomerMongoose>(new Types.ObjectId(tenantId), {
      branchId,
    });

    const linked = await this.customerModel
      .findOne({ ...scopeFilter, consumerId: input.consumerId }, { _id: 1 })
      .lean()
      .exec();
    if (linked) return { customerId: String(linked._id), outcome: 'existing' };

    // Same person already entered by the shop (matched by mobile): link, keep the shop's data.
    const byMobile = await this.customerModel
      .findOne(
        { ...scopeFilter, mobile: mobileMatcher(input.mobile), consumerId: { $exists: false } },
        { _id: 1, email: 1, address: 1 },
      )
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    if (byMobile) {
      await this.customerModel
        .updateOne(
          { _id: byMobile._id, consumerId: { $exists: false } },
          {
            $set: {
              consumerId: input.consumerId,
              ...(!byMobile.email && input.email ? { email: input.email } : {}),
              ...(!byMobile.address && input.address ? { address: input.address } : {}),
            },
          },
        )
        .exec();
      return { customerId: String(byMobile._id), outcome: 'linked' };
    }

    try {
      const created = await this.customerModel.create({
        tenantId: new Types.ObjectId(tenantId),
        branchId,
        name: input.name,
        mobile: input.mobile,
        email: input.email,
        address: input.address,
        customerType: CustomerType.REGULAR,
        joiningDate: new Date(),
        totalOrders: 0,
        totalSpent: 0,
        outstandingBalance: 0,
        lastOrderDate: null,
        source: CustomerSource.ONLINE,
        consumerId: input.consumerId,
      });
      return { customerId: String(created._id), outcome: 'created' };
    } catch (error) {
      // Two requests from the same customer at once: the other one created it.
      if (!isDuplicateKeyError(error)) throw error;
      const winner = await this.customerModel
        .findOne({ ...scopeFilter, consumerId: input.consumerId }, { _id: 1 })
        .lean()
        .exec();
      if (!winner) throw error;
      return { customerId: String(winner._id), outcome: 'existing' };
    }
  }

  async countForTenant(tenantId: string): Promise<number> {
    const filter = createActiveTenantFilter<CustomerMongoose>(new Types.ObjectId(tenantId));
    return this.customerModel.countDocuments(filter).exec();
  }

  async statistics(scope: CustomerScope): Promise<CustomerStatistics> {
    const filter = createActiveTenantFilter<CustomerMongoose>(new Types.ObjectId(scope.tenantId), {
      branchId: scope.branchId,
    });
    const [total, outstandingResult] = await Promise.all([
      this.customerModel.countDocuments(filter).exec(),
      this.customerModel.db
        .collection('orders')
        .aggregate<{ outstanding: number }>([
          {
            $match: {
              tenantId: new Types.ObjectId(scope.tenantId),
              branchId: scope.branchId,
              paymentStatus: { $in: ['Unpaid', 'PartiallyPaid'] },
            },
          },
          { $group: { _id: null, outstanding: { $sum: '$outstandingAmount' } } },
        ])
        .toArray(),
    ]);
    return { total, active: total, outstanding: outstandingResult[0]?.outstanding ?? 0 };
  }

  async softDelete(scope: CustomerScope, id: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(id)) return false;

    const result = await this.customerModel
      .updateOne(
        createActiveTenantFilter<CustomerMongoose>(scope.tenantId, {
          _id: id,
          branchId: scope.branchId,
        }),
        createSoftDeleteUpdate<CustomerMongoose>(scope.actorId),
      )
      .exec();
    return result.modifiedCount === 1;
  }

  private mapCustomer(document: Record<string, unknown>): CustomerRecord {
    return {
      id: String(document._id),
      tenantId: String(document.tenantId),
      branchId: document.branchId as string,
      name: document.name as string,
      mobile: document.mobile as string | undefined,
      email: document.email as string | undefined,
      address: document.address as string | undefined,
      customerType: document.customerType as CustomerType,
      joiningDate: document.joiningDate as Date,
      totalOrders: document.totalOrders as number,
      totalSpent: document.totalSpent as number,
      outstandingBalance: document.outstandingBalance as number,
      lastOrderDate: document.lastOrderDate as Date | null,
      source: (document.source as CustomerSource | undefined) ?? CustomerSource.SHOP,
      consumerId: document.consumerId as string | undefined,
      createdAt: document.createdAt as Date,
      updatedAt: document.updatedAt as Date,
    };
  }
}
