import { Controller, Get, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@Injectable()
export class PlatformHealthService {
  constructor(private readonly configService: ConfigService) {}

  getLiveness(): { status: 'ok'; service: string; timestampUtc: string } {
    return {
      status: 'ok',
      service: this.configService.getOrThrow<string>('APP_NAME'),
      timestampUtc: new Date().toISOString(),
    };
  }

  getReadiness(): {
    status: 'ready';
    service: string;
    version: string;
    timestampUtc: string;
  } {
    return {
      status: 'ready',
      service: this.configService.getOrThrow<string>('APP_NAME'),
      version: this.configService.getOrThrow<string>('API_VERSION'),
      timestampUtc: new Date().toISOString(),
    };
  }
}

@ApiTags('Health')
@Controller({ path: 'health', version: '1' })
export class PlatformHealthController {
  constructor(private readonly healthService: PlatformHealthService) {}

  @Get('live')
  @ApiOperation({
    summary: 'Liveness probe',
    description: 'Returns 200 when the process is alive. Used by Kubernetes/Docker health checks.',
  })
  @ApiResponse({ status: 200, description: 'Service is alive', schema: { example: { status: 'ok', service: 'Nexoraa CleanSoft', timestampUtc: '2026-01-01T00:00:00.000Z' } } })
  live(): { status: 'ok'; service: string; timestampUtc: string } {
    return this.healthService.getLiveness();
  }

  @Get('ready')
  @ApiOperation({
    summary: 'Readiness probe',
    description: 'Returns 200 when the service is ready to accept traffic (dependencies connected).',
  })
  @ApiResponse({ status: 200, description: 'Service is ready' })
  ready(): { status: 'ready'; service: string; version: string; timestampUtc: string } {
    return this.healthService.getReadiness();
  }
}
