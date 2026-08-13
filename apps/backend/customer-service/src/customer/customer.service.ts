import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';

import type { CreateCustomerDto, ListCustomersQueryDto, UpdateCustomerDto } from './customer.dto';
import { CustomerType } from './customer.mongoose.schema';
import {
  CUSTOMER_REPOSITORY,
  type CustomerMutableFields,
  type CustomerPage,
  type CustomerRecord,
  type CustomerRepository,
  type CustomerScope,
  type CustomerStatistics,
} from './customer.types';

@Injectable()
export class CustomerService {
  constructor(
    @Inject(CUSTOMER_REPOSITORY)
    private readonly customerRepository: CustomerRepository,
  ) {}

  create(scope: CustomerScope, input: CreateCustomerDto): Promise<CustomerRecord> {
    return this.customerRepository.create(scope, {
      name: input.name.trim(),
      mobile: input.mobile?.trim(),
      email: input.email?.trim().toLowerCase(),
      address: input.address?.trim(),
      customerType: input.customerType,
      joiningDate: input.joiningDate ? new Date(input.joiningDate) : undefined,
    });
  }

  list(scope: CustomerScope, query: ListCustomersQueryDto): Promise<CustomerPage> {
    return this.customerRepository.list(scope, {
      page: query.page,
      limit: query.limit,
      search: query.search?.trim(),
    });
  }

  statistics(scope: CustomerScope): Promise<CustomerStatistics> {
    return this.customerRepository.statistics(scope);
  }

  async getById(scope: CustomerScope, id: string): Promise<CustomerRecord> {
    const customer = await this.customerRepository.findById(scope, id);
    if (!customer) throw new NotFoundException('Customer not found');
    return customer;
  }

  async update(
    scope: CustomerScope,
    id: string,
    input: UpdateCustomerDto,
  ): Promise<CustomerRecord> {
    const existing = await this.getById(scope, id);
    const customerType = input.customerType ?? existing.customerType;
    const mobile = input.mobile === null ? undefined : (input.mobile?.trim() ?? existing.mobile);
    if (customerType !== CustomerType.WALK_IN && !mobile) {
      throw new BadRequestException('Mobile is required for registered customers');
    }

    const changes: CustomerMutableFields = {
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(input.mobile !== undefined
        ? { mobile: input.mobile === null ? null : input.mobile.trim() }
        : {}),
      ...(input.email !== undefined
        ? { email: input.email === null ? null : input.email.trim().toLowerCase() }
        : {}),
      ...(input.address !== undefined
        ? { address: input.address === null ? null : input.address.trim() }
        : {}),
      ...(input.customerType !== undefined ? { customerType: input.customerType } : {}),
      ...(input.joiningDate !== undefined ? { joiningDate: new Date(input.joiningDate) } : {}),
    };
    if (Object.keys(changes).length === 0) {
      throw new BadRequestException('At least one mutable customer field is required');
    }
    const customer = await this.customerRepository.update(scope, id, changes);
    if (!customer) throw new NotFoundException('Customer not found');
    return customer;
  }

  async delete(scope: CustomerScope, id: string): Promise<void> {
    const deleted = await this.customerRepository.softDelete(scope, id);
    if (!deleted) throw new NotFoundException('Customer not found');
  }
}
