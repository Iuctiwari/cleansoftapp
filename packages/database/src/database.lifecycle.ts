import { Injectable, Logger, type BeforeApplicationShutdown } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import type { Connection } from 'mongoose';

@Injectable()
export class DatabaseLifecycle implements BeforeApplicationShutdown {
  private readonly logger = new Logger(DatabaseLifecycle.name);

  constructor(@InjectConnection() private readonly connection: Connection) {}

  async beforeApplicationShutdown(signal?: string): Promise<void> {
    if (Number(this.connection.readyState) === 0) {
      return;
    }

    const signalMessage = signal ? ` after ${signal}` : '';
    this.logger.log(`Closing MongoDB connection${signalMessage}`);
    await this.connection.close(false);
    this.logger.log('MongoDB connection closed');
  }
}
