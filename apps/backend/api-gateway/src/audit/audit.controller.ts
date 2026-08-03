import { Body, Controller, Get, Param, Post, Query, Req } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { PlatformError } from '../platform/platform.errors';
import { TrustedContextFactory } from '../platform/platform.context';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import type { TrustedContext } from '../platform/platform.types';
import { AuditExportRequestDto, AuditQueryDto } from './audit.dto';
import { AuditService } from './audit.service';
import type { AuditRecord } from './audit.types';

@ApiTags('Audit')
@ApiBearerAuth('access-token')
@Controller({ path: 'audit', version: '1' })
export class AuditController {
  constructor(
    private readonly auditService: AuditService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Query immutable audit evidence',
    description:
      'Returns a paginated list of audit records. ' +
      'Tenant users only see records within their own tenant. ' +
      'Platform operators can filter across all tenants.',
  })
  @ApiResponse({ status: 200, description: 'Paginated audit record list' })
  @ApiResponse({ status: 401, description: 'Not authenticated' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async queryAudit(
    @Query() query: AuditQueryDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    const authorization = this.getAuthorization(request);
    return this.auditService.queryAudit(
      authorization,
      {
        module: query.module,
        action: query.action,
        actorId: query.actorId,
        targetId: query.targetId,
        classification: query.classification,
        tenantId: query.tenantId,
      },
      { page: query.page, pageSize: query.pageSize },
    );
  }

  @Get(':auditId')
  @ApiOperation({
    summary: 'Retrieve a single immutable audit record',
    description: 'Fetches one audit record by its unique ID.',
  })
  @ApiParam({ name: 'auditId', description: 'Unique audit record identifier' })
  @ApiResponse({ status: 200, description: 'Audit record found' })
  @ApiResponse({ status: 401, description: 'Not authenticated' })
  @ApiResponse({ status: 404, description: 'Audit record not found' })
  async getAuditById(
    @Param('auditId') auditId: string,
    @Req() request: RequestWithPlatformContext,
  ): Promise<AuditRecord | null> {
    return this.auditService.getAuditById(this.getAuthorization(request), auditId);
  }

  @Post('exports')
  @ApiOperation({
    summary: 'Request an audit export',
    description:
      'Enqueues an export job for the specified audit filter. ' +
      'Supply an `idempotencyKey` to safely retry without duplicate exports.',
  })
  @ApiResponse({ status: 201, description: 'Export job enqueued' })
  @ApiResponse({ status: 401, description: 'Not authenticated' })
  @ApiResponse({ status: 409, description: 'Idempotency conflict — payload mismatch' })
  async requestAuditExport(
    @Body() body: AuditExportRequestDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    return this.auditService.requestAuditExport(
      this.getAuthorization(request),
      {
        module: body.filters.module,
        action: body.filters.action,
        actorId: body.filters.actorId,
        targetId: body.filters.targetId,
        classification: body.filters.classification,
        tenantId: body.filters.tenantId,
      },
      body.idempotencyKey,
    );
  }

  private getAuthorization(request: RequestWithPlatformContext): TrustedContext {
    if (!request.trustedContext) {
      throw new PlatformError({
        code: 'platform.unauthenticated',
        category: 'unauthenticated',
        messageKey: 'errors.unauthenticated',
      });
    }

    return this.trustedContextFactory.assertTrustedContext(request.trustedContext);
  }
}
