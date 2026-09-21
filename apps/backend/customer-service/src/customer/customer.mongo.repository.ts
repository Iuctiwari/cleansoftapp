import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import {
  createActiveTenantFilter,
  createAuditFields,
  createSoftDeleteUpdate,
} from '@nexoraa/database';
import { Types, type Model } from 'mongoose';

import { CustomerMongoose, type CustomerType } from './customer.mongoose.schema';
import type {
  CreateCustomerFields,
  CustomerListQuery,
  CustomerMutableFields,
  CustomerPage,
  CustomerRecord,
  CustomerRepository,
  CustomerScope,
  CustomerStatistics,
} from './customer.types';

function escapeRegularExpression(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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
      createdAt: document.createdAt as Date,
      updatedAt: document.updatedAt as Date,
    };
  }
}
