import {
  BadGatewayException,
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type {
  BranchReference,
  CatalogQuote,
  CatalogPricingType,
  CustomerSnapshot,
  OrderDependencies,
  OrderScope,
} from './order.types';
import { CATALOG_PRICING_TYPES } from './order.types';

interface Envelope<T> {
  readonly data?: T;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

@Injectable()
export class HttpOrderDependencies implements OrderDependencies {
  constructor(private readonly configService: ConfigService) {}

  async resolveBranch(scope: OrderScope): Promise<BranchReference> {
    const baseUrl = this.configService.get<string>(
      'BRANCH_SERVICE_BASE_URL',
      'http://localhost:3004',
    );
    const response = await this.request(
      scope,
      `${baseUrl.replace(/\/$/, '')}/v1/branches/${encodeURIComponent(scope.branchId)}`,
    );
    const branch = asRecord(response);
    if (!branch || branch.status !== 'active')
      throw new ForbiddenException('The selected branch is not active or accessible');
    const code = typeof branch.code === 'string' ? branch.code.trim().toUpperCase() : '';
    if (!code || !/^[A-Z0-9_-]+$/.test(code)) {
      throw new BadGatewayException('Branch code is unavailable for order numbering');
    }
    return { branchId: scope.branchId, code };
  }

  async resolveCustomer(scope: OrderScope, customerId: string): Promise<CustomerSnapshot> {
    const baseUrl = this.configService.get<string>(
      'CUSTOMER_SERVICE_BASE_URL',
      'http://localhost:3005',
    );
    const response = await this.request(
      scope,
      `${baseUrl.replace(/\/$/, '')}/customers/${customerId}`,
    );
    const customer = asRecord(response);
    if (!customer || String(customer.id) !== customerId) {
      throw new NotFoundException('Customer not found');
    }
    if (String(customer.tenantId) !== scope.tenantId) {
      throw new ForbiddenException('Customer is outside the authenticated tenant');
    }
    if (String(customer.branchId) !== scope.branchId) {
      throw new ForbiddenException('Customer is outside the authenticated branch');
    }

    const name = this.optionalText(customer.name);
    const customerType = this.optionalText(customer.customerType);
    if (!name || !customerType) {
      throw new BadGatewayException('Customer Service returned an invalid customer record');
    }

    return {
      customerId,
      name,
      customerType,
      ...this.optionalSnapshotField('mobile', customer.mobile),
      ...this.optionalSnapshotField('email', customer.email),
      ...this.optionalSnapshotField('address', customer.address),
    };
  }

  async quoteCatalog(
    scope: OrderScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<CatalogQuote> {
    const baseUrl = this.configService
      .get<string>('SERVICE_SERVICE_BASE_URL', 'http://localhost:3006/api/v1')
      .replace(/\/$/, '');
    let service: Record<string, unknown>;
    let itemCategory: Record<string, unknown>;
    let quoteRecord: Record<string, unknown> | undefined;
    try {
      [service, itemCategory] = await this.catalogReferences(
        scope,
        baseUrl,
        serviceId,
        itemCategoryId,
      );
      quoteRecord = asRecord(
        await this.request(
          scope,
          `${baseUrl}/services/${serviceId}/quote?branchId=${encodeURIComponent(scope.branchId)}&itemCategoryId=${encodeURIComponent(itemCategoryId)}`,
        ),
      );
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new BadRequestException('Invalid or unavailable service/item category');
      }
      throw error;
    }

    const price = Number(quoteRecord?.basePrice);
    const taxPercent = Number(quoteRecord?.taxPct ?? 0);
    const pricingType = this.pricingType(quoteRecord?.pricingType ?? service.pricingType);
    const serviceName = this.optionalText(service.serviceName ?? service.name);
    const itemCategoryName = this.optionalText(itemCategory.name);
    if (
      !quoteRecord ||
      this.optionalText(quoteRecord.serviceId) !== serviceId ||
      !serviceName ||
      !itemCategoryName ||
      !pricingType ||
      !Number.isFinite(price) ||
      price < 0 ||
      !Number.isFinite(taxPercent) ||
      taxPercent < 0 ||
      taxPercent > 100 ||
      (quoteRecord.itemCategoryId !== undefined &&
        this.optionalText(quoteRecord.itemCategoryId) !== itemCategoryId) ||
      (quoteRecord.branchId !== undefined &&
        quoteRecord.branchId !== null &&
        this.optionalText(quoteRecord.branchId) !== scope.branchId)
    ) {
      throw new BadGatewayException('Catalog quote response is invalid');
    }

    return {
      itemCategorySnapshot: {
        itemCategoryId,
        name: itemCategoryName,
        ...this.optionalSnapshotField('code', itemCategory.code),
        ...this.optionalSnapshotField('unitType', itemCategory.unitType),
      },
      pricingType,
      serviceSnapshot: {
        serviceId,
        name: serviceName,
        pricing: {
          basePrice: price,
          pricingType,
          taxPct: taxPercent,
          ...this.optionalSnapshotField('servicePricingId', quoteRecord.servicePricingId),
          ...(Number.isSafeInteger(Number(quoteRecord.version))
            ? { version: Number(quoteRecord.version) }
            : {}),
          ...this.optionalSnapshotField('effectiveFrom', quoteRecord.effectiveFrom),
          ...this.optionalSnapshotField('effectiveTo', quoteRecord.effectiveTo),
        },
        ...this.optionalSnapshotField('code', service.code),
      },
      taxPercent,
      unitPrice: price,
    };
  }

  async validateCatalogReference(
    scope: OrderScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<void> {
    const baseUrl = this.configService
      .get<string>('SERVICE_SERVICE_BASE_URL', 'http://localhost:3006/api/v1')
      .replace(/\/$/, '');
    try {
      await this.catalogReferences(scope, baseUrl, serviceId, itemCategoryId);
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new BadRequestException('Invalid or unavailable service/item category');
      }
      throw error;
    }
  }

  assertStaffEligible(scope: OrderScope, staffId: string): Promise<void> {
    // User/Staff Management is intentionally deferred. Keep this boundary as the future
    // validation integration point without calling or duplicating an unavailable service.
    void scope;
    void staffId;
    return Promise.resolve();
  }

  private async catalogReferences(
    scope: OrderScope,
    baseUrl: string,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<readonly [Record<string, unknown>, Record<string, unknown>]> {
    const [serviceResponse, itemCategoryResponse] = await Promise.all([
      this.request(scope, `${baseUrl}/services/${serviceId}`),
      this.request(scope, `${baseUrl}/item-categories/${itemCategoryId}`),
    ]);
    const service = asRecord(serviceResponse);
    const itemCategory = asRecord(itemCategoryResponse);
    if (!service || !itemCategory) {
      throw new BadGatewayException('Catalog reference response is invalid');
    }
    this.assertCatalogRecord(scope, service, serviceId, 'Service');
    this.assertCatalogRecord(scope, itemCategory, itemCategoryId, 'Item category');
    this.assertBranchAvailability(scope, service, 'Service');
    this.assertBranchAvailability(scope, itemCategory, 'Item category');
    this.assertRelationship(service, itemCategory, serviceId, itemCategoryId);
    return [service, itemCategory];
  }

  private assertCatalogRecord(
    scope: OrderScope,
    record: Record<string, unknown>,
    expectedId: string,
    label: string,
  ): void {
    if (String(record.id ?? record._id) !== expectedId) {
      throw new BadGatewayException(`${label} response identifier is invalid`);
    }
    if (String(record.tenantId) !== scope.tenantId) {
      throw new ForbiddenException(`${label} is outside the authenticated tenant`);
    }
    if (String(record.status).toLowerCase() !== 'active') {
      throw new BadRequestException(`${label} is inactive or unavailable`);
    }
  }

  private assertBranchAvailability(
    scope: OrderScope,
    record: Record<string, unknown>,
    label: string,
  ): void {
    if (!Array.isArray(record.branchIds) || record.branchIds.length === 0) return;
    if (!record.branchIds.map(String).includes(scope.branchId)) {
      throw new ForbiddenException(`${label} is unavailable in the authenticated branch`);
    }
  }

  private assertRelationship(
    service: Record<string, unknown>,
    itemCategory: Record<string, unknown>,
    serviceId: string,
    itemCategoryId: string,
  ): void {
    if (
      Array.isArray(service.itemCategoryIds) &&
      service.itemCategoryIds.length > 0 &&
      !service.itemCategoryIds.map(String).includes(itemCategoryId)
    ) {
      throw new BadRequestException('Service is not available for the selected item category');
    }
    if (
      Array.isArray(itemCategory.serviceIds) &&
      itemCategory.serviceIds.length > 0 &&
      !itemCategory.serviceIds.map(String).includes(serviceId)
    ) {
      throw new BadRequestException('Item category is not available for the selected service');
    }
  }

  private pricingType(value: unknown): CatalogPricingType | undefined {
    return typeof value === 'string' && CATALOG_PRICING_TYPES.includes(value as CatalogPricingType)
      ? (value as CatalogPricingType)
      : undefined;
  }

  private async request(scope: OrderScope, url: string): Promise<unknown> {
    let response: Response;
    try {
      response = await fetch(url, {
        headers: { authorization: scope.authorization, 'x-branch-id': scope.branchId },
      });
    } catch {
      throw new BadGatewayException('Required service is unavailable');
    }
    if (response.status === 404) throw new NotFoundException('Referenced record was not found');
    if (response.status === 401)
      throw new BadGatewayException('Required service rejected authentication');
    if (response.status === 403)
      throw new ForbiddenException('Referenced record is outside the allowed scope');
    if (!response.ok) throw new BadGatewayException('Required service request failed');
    let body: unknown;
    try {
      body = await response.json();
    } catch {
      throw new BadGatewayException('Required service returned an invalid response');
    }
    const record = asRecord(body);
    return record && 'data' in record ? (record as Envelope<unknown>).data : body;
  }

  private optionalText(value: unknown): string | undefined {
    return typeof value === 'string' && value.trim() ? value.trim() : undefined;
  }

  private optionalSnapshotField<TKey extends string>(
    key: TKey,
    value: unknown,
  ): Partial<Record<TKey, string>> {
    const text = this.optionalText(value);
    return text ? ({ [key]: text } as Partial<Record<TKey, string>>) : {};
  }
}
