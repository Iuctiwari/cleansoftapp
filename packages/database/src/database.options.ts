import { Logger } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import type { MongooseModuleOptions } from '@nestjs/mongoose';
import type { Connection } from 'mongoose';

const logger = new Logger('Database');

function configureConnectionLogging(connection: Connection): Connection {
  logger.log('MongoDB connection established');
  connection.on('disconnected', () => logger.log('MongoDB connection disconnected'));
  connection.on('reconnected', () => logger.log('MongoDB connection re-established'));
  connection.on('error', (error: Error) => logger.error('MongoDB connection error', error.stack));

  return connection;
}

export function createMongooseOptions(configService: ConfigService): MongooseModuleOptions {
  const isProduction = configService.getOrThrow<string>('NODE_ENV') === 'production';

  return {
    autoIndex: !isProduction,
    bufferCommands: false,
    connectTimeoutMS: 10_000,
    connectionFactory: configureConnectionLogging,
    heartbeatFrequencyMS: 10_000,
    maxConnecting: 4,
    maxIdleTimeMS: 60_000,
    maxPoolSize: 20,
    minPoolSize: isProduction ? 2 : 0,
    retryAttempts: 10,
    retryDelay: 3_000,
    serverSelectionTimeoutMS: 10_000,
    socketTimeoutMS: 45_000,
    uri: configService.getOrThrow<string>('MONGODB_URI'),
  };
}
