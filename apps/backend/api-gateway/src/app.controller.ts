import { Controller, Get } from '@nestjs/common';

import { AppHealth, type HealthResponse } from './app.service';

@Controller('health')
export class AppController {
  constructor(private readonly appHealth: AppHealth) {}

  @Get()
  getHealth(): HealthResponse {
    return this.appHealth.getHealth();
  }
}
