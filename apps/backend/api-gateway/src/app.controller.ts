import { Controller, Get } from '@nestjs/common';
import { HealthCheck } from '@nestjs/terminus';

import { AppHealth, type HealthResponse } from './app.service';

@Controller('health')
export class AppController {
  constructor(private readonly appHealth: AppHealth) {}

  @Get()
  @HealthCheck()
  getHealth(): HealthResponse {
    return this.appHealth.getHealth();
  }
}
