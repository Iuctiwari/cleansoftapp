import { Injectable, Logger, ServiceUnavailableException, type OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createActiveTenantFilter, createAuditFields } from '@nexoraa/database';
import mongoose, { type Model, Types } from 'mongoose';

import {
  ExpenseCategoryMongoose,
  ExpenseCategoryMongooseSchema,
  ExpenseCategoryStatus,
  ExpenseMongoose,
  ExpenseMongooseSchema,
  ExpensePaymentMethod,
} from './expense.mongoose.schema';
import type {
  CreateExpenseCategoryFields,
  CreateExpenseFields,
  ExpenseCategoryRecord,
  ExpenseListQuery,
  ExpensePage,
  ExpenseRecord,
  ExpenseRepository,
  ExpenseScope,
  ExpenseStatistics,
  UpdateExpenseFields,
} from './expense.types';

function escapeRegularExpression(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const DEFAULT_CATEGORIES = [
  { categoryName: 'Rent', description: 'Branch space rent and lease payments' },
  { categoryName: 'Electricity', description: 'Electricity bills and power utility' },
  { categoryName: 'Water', description: 'Water bills and plumbing utilities' },
  { categoryName: 'Detergent/Materials', description: 'Cleaning supplies, detergents, chemicals' },
  { categoryName: 'Packaging', description: 'Garment bags, covers, tags, hangers' },
  { categoryName: 'Salary', description: 'Staff salaries, wages, and bonuses' },
  { categoryName: 'Transport', description: 'Delivery fuel, logistics, vehicle maintenance' },
  { categoryName: 'Equipment Maintenance', description: 'Machine repair, servicing, parts' },
  { categoryName: 'Marketing', description: 'Advertisements, flyers, promotions' },
  { categoryName: 'Miscellaneous', description: 'Other general business expenses' },
];

@Injectable()
export class MongoExpenseRepository implements ExpenseRepository, OnModuleInit {
  private readonly logger = new Logger(MongoExpenseRepository.name);
  private categoryModel?: Model<ExpenseCategoryMongoose>;
  private expenseModel?: Model<ExpenseMongoose>;
  constructor(private readonly configService: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const uri = this.configService.get<string>(
      'MONGODB_URI',
      'mongodb://localhost:27017/nexoraa_cleansoft',
    );
    try {
      const conn = await mongoose
        .createConnection(uri, {
          serverSelectionTimeoutMS: 2000,
          connectTimeoutMS: 2000,
          autoIndex: true,
        })
        .asPromise();

      this.categoryModel = conn.model(ExpenseCategoryMongoose.name, ExpenseCategoryMongooseSchema);
      this.expenseModel = conn.model(ExpenseMongoose.name, ExpenseMongooseSchema);
      this.logger.log(`Expense MongoDB connection established at ${uri}`);
    } catch (error) {
      this.logger.error(
        `MongoDB not reachable at ${uri}. Expense persistence is unavailable.`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  private get isMongoReady(): boolean {
    return Boolean(
      this.categoryModel &&
        this.expenseModel &&
        this.categoryModel.db?.readyState === mongoose.ConnectionStates.connected,
    );
  }

  private mongoUnavailable(): never {
    throw new ServiceUnavailableException('Expense persistence is unavailable');
  }

  async createCategory(
    scope: ExpenseScope,
    input: CreateExpenseCategoryFields,
  ): Promise<ExpenseCategoryRecord> {
    if (this.isMongoReady && this.categoryModel) {
      const tenantObjectId = new Types.ObjectId(scope.tenantId);
      const category = await this.categoryModel.create({
        ...createAuditFields(scope.actorId),
        tenantId: tenantObjectId,
        categoryName: input.categoryName.trim(),
        description: input.description?.trim(),
        status: input.status ?? ExpenseCategoryStatus.ACTIVE,
      });
      return this.mapCategory(category.toObject() as unknown as Record<string, unknown>);
    }

    this.mongoUnavailable();
  }

  async findCategoryById(scope: ExpenseScope, id: string): Promise<ExpenseCategoryRecord | null> {
    if (this.isMongoReady && this.categoryModel) {
      if (!Types.ObjectId.isValid(id)) return null;
      const category = await this.categoryModel
        .findOne(
          createActiveTenantFilter<ExpenseCategoryMongoose>(scope.tenantId, {
            _id: id,
          }),
        )
        .lean()
        .exec();
      return category ? this.mapCategory(category) : null;
    }

    this.mongoUnavailable();
  }

  async listCategories(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]> {
    if (this.isMongoReady && this.categoryModel) {
      const categories = await this.categoryModel
        .find(createActiveTenantFilter<ExpenseCategoryMongoose>(scope.tenantId))
        .sort({ categoryName: 1 })
        .lean()
        .exec();
      return categories.map((item) => this.mapCategory(item));
    }

    this.mongoUnavailable();
  }

  async seedDefaultCategoriesIfEmpty(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]> {
    const existing = await this.listCategories(scope);
    if (existing.length > 0) return existing;

    if (this.isMongoReady && this.categoryModel) {
      const tenantObjectId = new Types.ObjectId(scope.tenantId);
      const docs = DEFAULT_CATEGORIES.map((item) => ({
        ...createAuditFields(scope.actorId),
        tenantId: tenantObjectId,
        categoryName: item.categoryName,
        description: item.description,
        status: ExpenseCategoryStatus.ACTIVE,
      }));

      await this.categoryModel.insertMany(docs);
      return this.listCategories(scope);
    }

    this.mongoUnavailable();
  }

  async createExpense(scope: ExpenseScope, input: CreateExpenseFields): Promise<ExpenseRecord> {
    if (this.isMongoReady && this.expenseModel) {
      const tenantObjectId = new Types.ObjectId(scope.tenantId);
      const categoryObjectId = new Types.ObjectId(input.expenseCategoryId);

      const expense = await this.expenseModel.create({
        ...createAuditFields(scope.actorId),
        tenantId: tenantObjectId,
        branchId: scope.branchId,
        expenseCategoryId: categoryObjectId,
        amount: input.amount,
        paymentMethod: input.paymentMethod,
        vendor: input.vendor?.trim(),
        description: input.description.trim(),
        attachment: input.attachment?.trim(),
        expenseDate: input.expenseDate ?? new Date(),
        recordedBy: scope.actorId,
      });

      const populated = await this.findById(scope, String(expense._id));
      return populated ?? this.mapExpense(expense.toObject() as unknown as Record<string, unknown>);
    }

    this.mongoUnavailable();
  }

  async findById(scope: ExpenseScope, id: string): Promise<ExpenseRecord | null> {
    if (this.isMongoReady && this.expenseModel) {
      if (!Types.ObjectId.isValid(id)) return null;

      const expense = await this.expenseModel
        .findOne(
          createActiveTenantFilter<ExpenseMongoose>(scope.tenantId, {
            _id: id,
            branchId: scope.branchId,
          }),
        )
        .populate<{ expenseCategoryId: ExpenseCategoryMongoose | null }>('expenseCategoryId')
        .lean()
        .exec();

      return expense ? this.mapPopulatedExpense(expense) : null;
    }

    this.mongoUnavailable();
  }

  async listExpenses(scope: ExpenseScope, query: ExpenseListQuery): Promise<ExpensePage> {
    if (this.isMongoReady && this.expenseModel) {
      const filter: Record<string, unknown> = createActiveTenantFilter<ExpenseMongoose>(
        scope.tenantId,
        {
          branchId: query.branchId ?? scope.branchId,
        },
      );

      if (query.categoryId && Types.ObjectId.isValid(query.categoryId)) {
        filter.expenseCategoryId = new Types.ObjectId(query.categoryId);
      }

      if (query.paymentMethod) {
        filter.paymentMethod = query.paymentMethod;
      }

      if (query.startDate || query.endDate) {
        const dateFilter: Record<string, Date> = {};
        if (query.startDate) dateFilter.$gte = query.startDate;
        if (query.endDate) dateFilter.$lte = query.endDate;
        filter.expenseDate = dateFilter;
      }

      const search = query.search?.trim();
      if (search) {
        const expression = new RegExp(escapeRegularExpression(search), 'i');
        filter.$or = [{ description: expression }, { vendor: expression }];
      }

      const skip = (query.page - 1) * query.limit;
      const [expenses, total] = await Promise.all([
        this.expenseModel
          .find(filter)
          .populate<{ expenseCategoryId: ExpenseCategoryMongoose | null }>('expenseCategoryId')
          .sort({ expenseDate: -1, _id: -1 })
          .skip(skip)
          .limit(query.limit)
          .lean()
          .exec(),
        this.expenseModel.countDocuments(filter).exec(),
      ]);

      return {
        items: expenses.map((item) => this.mapPopulatedExpense(item)),
        total,
        page: query.page,
        limit: query.limit,
      };
    }

    this.mongoUnavailable();
  }

  async updateExpense(
    scope: ExpenseScope,
    id: string,
    input: UpdateExpenseFields,
  ): Promise<ExpenseRecord | null> {
    if (this.isMongoReady && this.expenseModel) {
      if (!Types.ObjectId.isValid(id)) return null;

      const setFields: Record<string, unknown> = { updatedBy: scope.actorId };
      const unsetFields: Record<string, 1> = {};

      for (const [field, value] of Object.entries(input)) {
        if (value === null) {
          unsetFields[field] = 1;
        } else if (value !== undefined) {
          if (field === 'expenseCategoryId' && typeof value === 'string') {
            if (!Types.ObjectId.isValid(value)) return null;
            setFields[field] = new Types.ObjectId(value);
          } else {
            setFields[field] = value;
          }
        }
      }

      const updated = await this.expenseModel
        .findOneAndUpdate(
          createActiveTenantFilter<ExpenseMongoose>(scope.tenantId, {
            _id: id,
            branchId: scope.branchId,
          }),
          {
            $set: setFields,
            ...(Object.keys(unsetFields).length > 0 ? { $unset: unsetFields } : {}),
          },
          { new: true, runValidators: true },
        )
        .populate<{ expenseCategoryId: ExpenseCategoryMongoose | null }>('expenseCategoryId')
        .lean()
        .exec();

      return updated ? this.mapPopulatedExpense(updated) : null;
    }

    this.mongoUnavailable();
  }

  async statistics(scope: ExpenseScope): Promise<ExpenseStatistics> {
    if (this.isMongoReady && this.expenseModel) {
      const filter = createActiveTenantFilter<ExpenseMongoose>(new Types.ObjectId(scope.tenantId), {
        branchId: scope.branchId,
      });

      const [aggregateResult, distinctCategories] = await Promise.all([
        this.expenseModel
          .aggregate<{
            _id: null;
            totalAmount: number;
            count: number;
            byPaymentMethod: Array<{ paymentMethod: string; total: number }>;
          }>([
            { $match: filter },
            {
              $facet: {
                totals: [
                  {
                    $group: {
                      _id: null,
                      totalAmount: { $sum: '$amount' },
                      count: { $sum: 1 },
                    },
                  },
                ],
                paymentMethods: [
                  {
                    $group: {
                      _id: '$paymentMethod',
                      total: { $sum: '$amount' },
                    },
                  },
                ],
              },
            },
            {
              $project: {
                _id: null,
                totalAmount: { $ifNull: [{ $arrayElemAt: ['$totals.totalAmount', 0] }, 0] },
                count: { $ifNull: [{ $arrayElemAt: ['$totals.count', 0] }, 0] },
                byPaymentMethod: {
                  $map: {
                    input: '$paymentMethods',
                    as: 'pm',
                    in: {
                      paymentMethod: '$$pm._id',
                      total: '$$pm.total',
                    },
                  },
                },
              },
            },
          ])
          .exec(),
        this.expenseModel.distinct('expenseCategoryId', filter).exec(),
      ]);

      const result = aggregateResult[0];
      const byPaymentMethod: Record<string, number> = {};
      if (result?.byPaymentMethod) {
        for (const item of result.byPaymentMethod) {
          if (item.paymentMethod) byPaymentMethod[item.paymentMethod] = item.total;
        }
      }

      return {
        totalAmount: result?.totalAmount ?? 0,
        count: result?.count ?? 0,
        categoryCount: distinctCategories.length,
        byPaymentMethod,
      };
    }

    this.mongoUnavailable();
  }

  private mapCategory(document: Record<string, unknown>): ExpenseCategoryRecord {
    return {
      id: String(document._id),
      tenantId: String(document.tenantId),
      categoryName: document.categoryName as string,
      description: document.description as string | undefined,
      status: document.status as ExpenseCategoryStatus,
      createdAt: document.createdAt as Date,
      updatedAt: document.updatedAt as Date,
    };
  }

  private mapExpense(document: Record<string, unknown>): ExpenseRecord {
    return {
      id: String(document._id),
      tenantId: String(document.tenantId),
      branchId: document.branchId as string,
      expenseCategoryId: String(document.expenseCategoryId),
      categoryName: undefined,
      amount: document.amount as number,
      paymentMethod: document.paymentMethod as ExpensePaymentMethod,
      vendor: document.vendor as string | undefined,
      description: document.description as string,
      attachment: document.attachment as string | undefined,
      expenseDate: document.expenseDate as Date,
      recordedBy: document.recordedBy as string,
      createdAt: document.createdAt as Date,
      updatedAt: document.updatedAt as Date,
    };
  }

  private mapPopulatedExpense(document: Record<string, unknown>): ExpenseRecord {
    const categoryDoc = document.expenseCategoryId as Record<string, unknown> | null;
    const isPopulated = categoryDoc && typeof categoryDoc === 'object' && '_id' in categoryDoc;

    return {
      id: String(document._id),
      tenantId: String(document.tenantId),
      branchId: document.branchId as string,
      expenseCategoryId: isPopulated ? String(categoryDoc._id) : String(document.expenseCategoryId),
      categoryName: isPopulated ? (categoryDoc.categoryName as string) : undefined,
      amount: document.amount as number,
      paymentMethod: document.paymentMethod as ExpensePaymentMethod,
      vendor: document.vendor as string | undefined,
      description: document.description as string,
      attachment: document.attachment as string | undefined,
      expenseDate: document.expenseDate as Date,
      recordedBy: document.recordedBy as string,
      createdAt: document.createdAt as Date,
      updatedAt: document.updatedAt as Date,
    };
  }
}
