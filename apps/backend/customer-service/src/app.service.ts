import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface HealthResponse {
  status: 'ok';
  service: string;
  environment: string;
  message: 'NestJS service foundation ready';
}

@Injectable()
export class AppHealth {
  constructor(private readonly configService: ConfigService) {}

  getHealth(): HealthResponse {
    return {
      status: 'ok',
      service: this.configService.getOrThrow<string>('SERVICE_NAME'),
      environment: this.configService.getOrThrow<string>('NODE_ENV'),
      message: 'NestJS service foundation ready',
    };
  }
}
