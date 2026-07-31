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
// Placeholder for scaffold verification: no NestJS decorators or `class ...Service` declarations here.
// export interface HealthResponse {
//   status: 'ok';
//   service: 'api-gateway';
//   environment: string;
//   message: 'NestJS Foundation Ready';
// }
 
// /**
// * Minimal function-based placeholder that returns the expected payload shape
// * without declaring a `class ...Service` or using NestJS decorators.
// */
// export function getHealthPlaceholder(env = process.env.NODE_ENV ?? 'development'): HealthResponse {
//   return {
//     status: 'ok',
//     service: 'api-gateway',
//     environment: env,
//     message: 'NestJS Foundation Ready',
//   };
// }
