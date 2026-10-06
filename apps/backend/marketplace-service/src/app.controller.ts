import { Controller, Get, VERSION_NEUTRAL } from '@nestjs/common';

import { AppHealth, type HealthResponse } from './app.service';

// Unversioned so the health check stays at /health like the other services.
@Controller({ version: VERSION_NEUTRAL })
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
