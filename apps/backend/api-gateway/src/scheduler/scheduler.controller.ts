import { Body, Controller, Get, Param, Post, Req } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';

import { PlatformError } from '../platform/platform.errors';
import { TrustedContextFactory } from '../platform/platform.context';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import { ApiEnvelopeResponse } from '../platform/platform.swagger';
import { RegisterScheduleDto, ReplayJobDto, ScheduleJobDto } from './scheduler.dto';
import { SchedulerService } from './scheduler.service';
import {
  SchedulerJobRecordDto,
  SchedulerReplayResponseDto,
  SchedulerScheduleRecordDto,
} from './scheduler.swagger';

@ApiTags('Scheduler')
@ApiBearerAuth('access-token')
@Controller({ path: 'internal/jobs', version: '1' })
export class SchedulerController {
  constructor(
    private readonly schedulerService: SchedulerService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Post()
  @ApiOperation({
    summary: 'Enqueue a background job',
    description:
      'Schedules a new background job for asynchronous processing. ' +
      'Idempotent — supplying the same `idempotencyKey` is safe to retry.',
  })
  @ApiEnvelopeResponse(SchedulerJobRecordDto, {
    description: 'Scheduled job record after persistence and dispatch.',
    status: 'created',
  })
  async scheduleJob(
    @Body() body: ScheduleJobDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    const authorization = this.getAuthorization(request);
    return this.schedulerService.scheduleJob(
      this.schedulerService.createJobInputFromContext(authorization, body),
    );
  }

  @Get(':jobId')
  @ApiOperation({
    summary: 'Inspect a background job',
    description: 'Returns the current status, attempts, and metadata of the specified job.',
  })
  @ApiParam({ name: 'jobId', description: 'Unique job identifier', example: 'job-9f6cc5e3' })
  @ApiEnvelopeResponse(SchedulerJobRecordDto, {
    description: 'Scheduled job record or null when it does not exist.',
    nullable: true,
  })
  async inspectJob(@Param('jobId') jobId: string): Promise<unknown> {
    return this.schedulerService.inspectJob(jobId);
  }

  @Post(':jobId/replay')
  @ApiOperation({
    summary: 'Replay or retry a failed job',
    description: 'Forces a re-queue of a failed or completed job for debugging or recovery.',
  })
  @ApiParam({ name: 'jobId', description: 'Unique job identifier to replay', example: 'job-9f6cc5e3' })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['reason'],
      properties: {
        reason: { type: 'string', example: 'Manual retry after infrastructure incident' },
      },
    },
  })
  @ApiEnvelopeResponse(SchedulerReplayResponseDto, {
    description: 'Replay result recorded after dispatch.',
  })
  async replayJob(
    @Param('jobId') jobId: string,
    @Body() body: ReplayJobDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    const authorization = this.getAuthorization(request);
    return this.schedulerService.retryOrReplay({
      authorization,
      jobId,
      reason: body.reason,
    });
  }

  @Post('schedules')
  @ApiOperation({
    summary: 'Register a recurring CRON schedule',
    description:
      'Creates a named recurring schedule that fires background jobs on a CRON expression. ' +
      'Timezone must be a valid IANA timezone string.',
  })
  @ApiEnvelopeResponse(SchedulerScheduleRecordDto, {
    description: 'Registered schedule definition.',
    status: 'created',
  })
  async registerSchedule(
    @Body() body: RegisterScheduleDto,
    @Req() request: RequestWithPlatformContext,
  ): Promise<unknown> {
    const authorization = this.getAuthorization(request);
    return this.schedulerService.registerSchedule({
      owner: body.owner,
      tenantId: 'tenantId' in authorization ? authorization.tenantId : body.tenantId,
      environment: 'internal',
      cron: body.cron,
      timezone: body.timezone,
      payloadReference: body.payloadReference,
      payloadChecksum: body.payloadChecksum,
    });
  }

  private getAuthorization(
    request: RequestWithPlatformContext,
  ): ReturnType<TrustedContextFactory['assertTrustedContext']> {
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
