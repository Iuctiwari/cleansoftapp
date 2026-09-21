import { Injectable } from '@nestjs/common';

@Injectable()
export class AppHealth {
  check(): { status: string; service: string; timestamp: string } {
    return {
      status: 'ok',
      service: 'platform-admin-service',
      timestamp: new Date().toISOString(),
    };
  }
}
