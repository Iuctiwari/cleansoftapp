import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { HealthIndicatorService, type HealthIndicatorResult } from '@nestjs/terminus';
import type { Connection } from 'mongoose';

const HEALTH_CHECK_TIMEOUT_MS = 5_000;

@Injectable()
export class DatabaseHealth {
  constructor(
    @InjectConnection() private readonly connection: Connection,
    private readonly healthIndicatorService: HealthIndicatorService,
  ) {}

  async check(): Promise<HealthIndicatorResult> {
    const indicator = this.healthIndicatorService.check('mongodb');
    const database = this.connection.db;

    if (!database) {
      return indicator.down('MongoDB connection is not available');
    }

    let timeout: NodeJS.Timeout | undefined;

    try {
      await Promise.race([
        database.admin().ping(),
        new Promise<never>((_resolve, reject) => {
          timeout = setTimeout(
            () => reject(new Error('MongoDB health check timed out')),
            HEALTH_CHECK_TIMEOUT_MS,
          );
        }),
      ]);

      return indicator.up();
    } catch {
      return indicator.down('MongoDB ping failed');
    } finally {
      if (timeout) {
        clearTimeout(timeout);
      }
    }
  }
}
