import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class ContractVersionDto {
  @ApiProperty({ example: 1 })
  major!: number;

  @ApiProperty({ example: 0 })
  minor!: number;
}

class AuditActorSnapshotDto {
  @ApiProperty({ example: 'platform-admin-1' })
  actorId!: string;

  @ApiProperty({ enum: ['user', 'service', 'support'], example: 'user' })
  actorType!: 'user' | 'service' | 'support';
}

class AuditTargetSnapshotDto {
  @ApiProperty({ example: 'session-9d6cb4d6' })
  targetId!: string;

  @ApiProperty({ example: 'auth_session' })
  targetType!: string;
}

class AuditRetentionTagDto {
  @ApiProperty({ example: 'security' })
  code!: string;

  @ApiProperty({ example: 'Security' })
  label!: string;
}

class AuditSummaryDto {
  @ApiProperty({
    type: 'object',
    additionalProperties: {
      anyOf: [{ type: 'string' }, { type: 'number' }, { type: 'boolean' }, { type: 'null' }],
    },
    example: { sessionId: 'session-9d6cb4d6', deviceName: 'Pixel 8 Pro' },
  })
  fields!: Record<string, string | number | boolean | null>;
}

export class AuditRecordDto {
  @ApiProperty({ example: 'audit-3aa08f4d' })
  auditId!: string;

  @ApiProperty({ enum: ['platform', 'tenant', 'support'], example: 'platform' })
  scopeKind!: 'platform' | 'tenant' | 'support';

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  tenantId?: string;

  @ApiPropertyOptional({ example: 'branch-alpha-main' })
  branchId?: string;

  @ApiProperty({ type: AuditActorSnapshotDto })
  actor!: AuditActorSnapshotDto;

  @ApiProperty({ example: 'auth' })
  module!: string;

  @ApiProperty({ example: 'login_success' })
  action!: string;

  @ApiProperty({ type: AuditTargetSnapshotDto })
  target!: AuditTargetSnapshotDto;

  @ApiProperty({
    enum: ['security', 'financial', 'operational', 'compliance'],
    example: 'security',
  })
  classification!: 'security' | 'financial' | 'operational' | 'compliance';

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  occurredAtUtc!: string;

  @ApiProperty({ example: 'b9a1d970-9868-4a1f-b4f2-4f48091d1984' })
  correlationId!: string;

  @ApiProperty({ example: 'cfe4a86d-7e6c-4bfa-9da8-ef4f4e60dd8c' })
  causationId!: string;

  @ApiProperty({ example: '458d7926-6f0f-4900-b65e-d4b05054cbf2' })
  requestId!: string;

  @ApiProperty({ enum: ['accepted', 'committed', 'replayed'], example: 'committed' })
  result!: 'accepted' | 'committed' | 'replayed';

  @ApiProperty({ example: 'auth:login:session-9d6cb4d6' })
  sourceObligation!: string;

  @ApiPropertyOptional({ type: AuditSummaryDto })
  oldSummary?: AuditSummaryDto;

  @ApiPropertyOptional({ type: AuditSummaryDto })
  newSummary?: AuditSummaryDto;

  @ApiProperty({ type: [AuditRetentionTagDto] })
  retentionTags!: AuditRetentionTagDto[];

  @ApiProperty({ type: ContractVersionDto })
  contractVersion!: ContractVersionDto;
}

export class AuditExportIntentDto {
  @ApiProperty({ example: 'export-2a3878d9' })
  exportId!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  requestedAtUtc!: string;

  @ApiProperty({ example: 'audit-export-20260803-01' })
  idempotencyKey!: string;

  @ApiProperty({
    type: 'object',
    additionalProperties: false,
    example: { module: 'auth', classification: 'security', tenantId: 'tenant-alpha' },
  })
  filters!: Record<string, string>;

  @ApiProperty({ enum: ['platform', 'tenant', 'support'], example: 'platform' })
  authorizationKind!: 'platform' | 'tenant' | 'support';
}
