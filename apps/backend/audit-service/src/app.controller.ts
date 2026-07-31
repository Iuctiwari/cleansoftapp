import { Controller, Get } from '@nestjs/common';

import { AppHealth, type HealthResponse } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appHealth: AppHealth) {}

  @Get()
  getRoot(): HealthResponse {
    return this.appHealth.getHealth();
  }

  @Get('health')
  getHealth(): HealthResponse {
    return this.appHealth.getHealth();
  }
}
