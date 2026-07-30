import { Controller, Get, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

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

@Controller({ path: 'health', version: '1' })
export class PlatformHealthController {
  constructor(private readonly healthService: PlatformHealthService) {}

  @Get('live')
  live(): { status: 'ok'; service: string; timestampUtc: string } {
    return this.healthService.getLiveness();
  }

  @Get('ready')
  ready(): { status: 'ready'; service: string; version: string; timestampUtc: string } {
    return this.healthService.getReadiness();
  }
}
