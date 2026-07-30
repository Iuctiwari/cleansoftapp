import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseHealth } from '@nexoraa/database';
import { HealthCheckService, type HealthIndicatorResult } from '@nestjs/terminus';

export interface HealthResponse {
  status: 'ok';
  service: 'api-gateway';
  environment: string;
  message: 'NestJS Foundation Ready';
  mongodb: HealthIndicatorResult[string];
}

@Injectable()
export class AppHealth {
  constructor(
    private readonly configService: ConfigService,
    private readonly databaseHealth: DatabaseHealth,
    private readonly healthCheckService: HealthCheckService,
  ) {}

  async getHealth(): Promise<HealthResponse> {
    const health = await this.healthCheckService.check([
      (): Promise<HealthIndicatorResult> => this.databaseHealth.check(),
    ]);

    return {
      status: 'ok',
      service: 'api-gateway',
      environment: this.configService.getOrThrow<string>('NODE_ENV'),
      message: 'NestJS Foundation Ready',
      mongodb: health.details.mongodb,
    };
  }
}
