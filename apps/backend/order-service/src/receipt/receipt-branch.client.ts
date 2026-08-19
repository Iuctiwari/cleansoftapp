import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { OrderScope } from '../order/order.types';
import type { ReceiptBranchView } from './receipt.types';

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function text(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim() ? value.trim() : undefined;
}

/**
 * Resolves human-readable branch details for the receipt from Branch
 * Service's GET /v1/branches/:branchId — the same endpoint and request
 * shape OrderService's HttpOrderDependencies.resolveBranch() already uses,
 * kept as a separate minimal client here (rather than extended/reused)
 * because that method only returns {branchId, code} for order-numbering and
 * is order-lifecycle code this task must not touch.
 *
 * Any failure (service unreachable, non-2xx, malformed body) resolves to
 * undefined so the receipt still generates — the template omits the branch
 * line entirely rather than falling back to the raw branchId.
 */
@Injectable()
export class ReceiptBranchClient {
  private readonly logger = new Logger(ReceiptBranchClient.name);

  constructor(private readonly configService: ConfigService) {}

  async resolve(scope: OrderScope): Promise<ReceiptBranchView | undefined> {
    const baseUrl = this.configService
      .get<string>('BRANCH_SERVICE_BASE_URL', 'http://localhost:3004')
      .replace(/\/$/, '');
    try {
      const response = await fetch(`${baseUrl}/v1/branches/${encodeURIComponent(scope.branchId)}`, {
        headers: { authorization: scope.authorization, 'x-branch-id': scope.branchId },
      });
      if (!response.ok) return undefined;
      const body: unknown = await response.json();
      const envelope = asRecord(body);
      const branch = envelope && 'data' in envelope ? asRecord(envelope.data) : envelope;
      return branch ? this.toView(branch) : undefined;
    } catch (error) {
      this.logger.warn(
        `Branch details unavailable for receipt (branchId=${scope.branchId}): ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return undefined;
    }
  }

  private toView(branch: Record<string, unknown>): ReceiptBranchView | undefined {
    const name = text(branch.branchName);
    if (!name) return undefined;
    return {
      name,
      code: text(branch.code),
      address: this.address(branch),
      phone: text(branch.phone),
      email: text(branch.email),
    };
  }

  private address(branch: Record<string, unknown>): string | undefined {
    const parts = [branch.streetAddress, branch.city, branch.state, branch.postalCode]
      .map(text)
      .filter((part): part is string => Boolean(part));
    return parts.length > 0 ? parts.join(', ') : undefined;
  }
}
