import { Body, Controller, Get, Param, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';

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
  @ApiOperation({ summary: 'Create and dispatch a new internal job.' })
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
  @ApiOperation({ summary: 'Inspect a scheduled job by identifier.' })
  @ApiParam({ name: 'jobId', example: 'job-9f6cc5e3' })
  @ApiEnvelopeResponse(SchedulerJobRecordDto, {
    description: 'Scheduled job record or null when it does not exist.',
    nullable: true,
  })
  async inspectJob(@Param('jobId') jobId: string): Promise<unknown> {
    return this.schedulerService.inspectJob(jobId);
  }

  @Post(':jobId/replay')
  @ApiOperation({ summary: 'Replay or retry an existing scheduled job.' })
  @ApiParam({ name: 'jobId', example: 'job-9f6cc5e3' })
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
  @ApiOperation({ summary: 'Register a recurring schedule template.' })
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
