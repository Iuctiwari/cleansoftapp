import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { AppHealth } from './app.service';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appHealth: AppHealth) {}

  @Get('health')
  @ApiOperation({ summary: 'Health check' })
  health(): { status: string; service: string; timestamp: string } {
    return this.appHealth.check();
  }
}
