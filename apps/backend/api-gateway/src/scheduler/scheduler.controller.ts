import { Body, Controller, Get, Param, Post, Req } from '@nestjs/common';

import { PlatformError } from '../platform/platform.errors';
import { TrustedContextFactory } from '../platform/platform.context';
import type { RequestWithPlatformContext } from '../platform/platform.request';
import { RegisterScheduleDto, ScheduleJobDto } from './scheduler.dto';
import { SchedulerService } from './scheduler.service';

@Controller({ path: 'internal/jobs', version: '1' })
export class SchedulerController {
  constructor(
    private readonly schedulerService: SchedulerService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  @Post()
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
  async inspectJob(@Param('jobId') jobId: string): Promise<unknown> {
    return this.schedulerService.inspectJob(jobId);
  }

  @Post(':jobId/replay')
  async replayJob(
    @Param('jobId') jobId: string,
    @Body() body: { readonly reason: string },
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
