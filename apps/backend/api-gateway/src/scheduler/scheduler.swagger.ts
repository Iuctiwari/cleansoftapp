import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class SchedulerJobScopeDto {
  @ApiPropertyOptional({ example: 'tenant-alpha' })
  tenantId?: string;

  @ApiPropertyOptional({ example: 'branch-alpha-main' })
  branchId?: string;
}

export class SchedulerJobRecordDto {
  @ApiProperty({ example: 'job-9f6cc5e3' })
  jobId!: string;

  @ApiProperty({ example: '1.0.0' })
  version!: string;

  @ApiProperty({ example: 'orders.rebuild-index' })
  owner!: string;

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  tenantId?: string;

  @ApiProperty({ example: 'internal' })
  environment!: string;

  @ApiProperty({ type: SchedulerJobScopeDto })
  scope!: SchedulerJobScopeDto;

  @ApiProperty({ example: '458d7926-6f0f-4900-b65e-d4b05054cbf2' })
  requestId!: string;

  @ApiProperty({ example: 'b9a1d970-9868-4a1f-b4f2-4f48091d1984' })
  correlationId!: string;

  @ApiProperty({ example: 'job-order-index-tenant-alpha-001' })
  idempotencyKey!: string;

  @ApiProperty({ example: 's3://internal/jobs/orders/rebuild-index.json' })
  payloadReference!: string;

  @ApiProperty({ example: 'sha256:0f6b3d7d8426' })
  payloadChecksum!: string;

  @ApiProperty({ example: 0 })
  priority!: number;

  @ApiProperty({ example: 30000 })
  delayMs!: number;

  @ApiProperty({ example: 3 })
  maxAttempts!: number;

  @ApiProperty({
    type: 'object',
    additionalProperties: {
      anyOf: [{ type: 'string' }, { type: 'number' }, { type: 'boolean' }, { type: 'null' }],
    },
    example: { trigger: 'manual', source: 'api' },
  })
  metadata!: Record<string, string | number | boolean | null>;

  @ApiProperty({ example: 'scheduler:internal:tenant-alpha' })
  queueName!: string;

  @ApiProperty({
    enum: [
      'Pending',
      'Waiting',
      'Delayed',
      'Active',
      'Completed',
      'Failed',
      'RetryScheduled',
      'DeadLettered',
      'Cancelled',
      'Expired',
    ],
    example: 'Waiting',
  })
  status!: string;

  @ApiProperty({ example: 0 })
  attempts!: number;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  scheduledAtUtc!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  createdAtUtc!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  updatedAtUtc!: string;

  @ApiPropertyOptional({ example: 'Redis unavailable during dispatch.' })
  failureReason?: string;

  @ApiPropertyOptional({ example: 'Exceeded retry threshold.' })
  deadLetterReason?: string;

  @ApiProperty({ example: 0 })
  replayCount!: number;
}

export class SchedulerScheduleRecordDto {
  @ApiProperty({ example: 'schedule-7d61d8e4' })
  scheduleId!: string;

  @ApiProperty({ example: 'orders.rebuild-index' })
  owner!: string;

  @ApiPropertyOptional({ example: 'tenant-alpha' })
  tenantId?: string;

  @ApiProperty({ example: 'internal' })
  environment!: string;

  @ApiProperty({ example: '0 */6 * * *' })
  cron!: string;

  @ApiProperty({ example: 'Asia/Calcutta' })
  timezone!: string;

  @ApiProperty({ example: 's3://internal/jobs/orders/rebuild-index.json' })
  payloadReference!: string;

  @ApiProperty({ example: 'sha256:0f6b3d7d8426' })
  payloadChecksum!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  createdAtUtc!: string;
}

export class SchedulerReplayResponseDto {
  @ApiProperty({ example: 'job-9f6cc5e3' })
  jobId!: string;

  @ApiProperty({ enum: ['Waiting'], example: 'Waiting' })
  status!: string;

  @ApiProperty({ example: 1 })
  replayCount!: number;
}
