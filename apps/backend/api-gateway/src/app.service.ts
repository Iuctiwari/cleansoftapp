import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface HealthResponse {
  status: 'ok';
  service: 'api-gateway';
  environment: string;
  message: 'NestJS Foundation Ready';
}

@Injectable()
export class AppHealth {
  constructor(private readonly configService: ConfigService) {}

  getHealth(): HealthResponse {
    return {
      status: 'ok',
      service: 'api-gateway',
      environment: this.configService.getOrThrow<string>('NODE_ENV'),
      message: 'NestJS Foundation Ready',
    };
  }
}
