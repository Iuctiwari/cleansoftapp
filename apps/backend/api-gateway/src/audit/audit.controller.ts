import { Body, Controller, Get, Param, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';

import { PlatformError } from '../platform/platform.errors';
import { TrustedContextFactory } from '../platform/platform.context';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import type { TrustedContext } from '../platform/platform.types';
import { ApiEnvelopeResponse } from '../platform/platform.swagger';
import { AuditExportRequestDto, AuditQueryDto } from './audit.dto';
import { AuditService } from './audit.service';
import type { AuditRecord } from './audit.types';
import { AuditExportIntentDto, AuditRecordDto } from './audit.swagger';

@ApiTags('Audit')
@ApiBearerAuth('access-token')
@Controller({ path: 'audit', version: '1' })
export class AuditController {
  constructor(
    private readonly auditService: AuditService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Query immutable audit evidence.' })
  @ApiEnvelopeResponse(AuditRecordDto, {
    description: 'Audit evidence matching the requested filters.',
    isArray: true,
  })
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
  @ApiOperation({ summary: 'Retrieve a single audit record by identifier.' })
  @ApiParam({ name: 'auditId', example: 'audit-3aa08f4d' })
  @ApiEnvelopeResponse(AuditRecordDto, {
    description: 'One audit record or null when not found in scope.',
    nullable: true,
  })
  async getAuditById(
    @Param('auditId') auditId: string,
    @Req() request: RequestWithPlatformContext,
  ): Promise<AuditRecord | null> {
    return this.auditService.getAuditById(this.getAuthorization(request), auditId);
  }

  @Post('exports')
  @ApiOperation({ summary: 'Request an idempotent audit export intent.' })
  @ApiEnvelopeResponse(AuditExportIntentDto, {
    description: 'Accepted audit export intent.',
    status: 'created',
  })
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
