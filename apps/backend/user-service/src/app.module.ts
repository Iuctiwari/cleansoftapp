import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { UserModule } from './user/user.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
      envFilePath: ['.env', '../../../.env'],
    }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const rawUri = configService.get<string>('MONGODB_URI');
        const finalUri = (rawUri ?? 'mongodb://127.0.0.1:27017/nexoraa_cleansoft')
          .replace('mongodb://mongodb:', 'mongodb://127.0.0.1:')
          .replace('mongodb://localhost:', 'mongodb://127.0.0.1:')
          .replace('mongodb://mongodb/', 'mongodb://127.0.0.1/');
        return {
          uri: finalUri,
          maxPoolSize: 10,
          serverSelectionTimeoutMS: 5000,
          socketTimeoutMS: 45_000,
        };
      },
    }),
    UserModule,
  ],
  controllers: [AppController],
  providers: [AppHealth],
})
export class AppModule {}
