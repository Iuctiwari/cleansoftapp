import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { BusinessTypeController } from './business-type.controller';
import { BusinessTypeMongoose, BusinessTypeMongooseSchema } from './business-type.mongoose.schema';
import { BusinessTypeService } from './business-type.service';

@Module({
  imports: [
    // PlatformRoleGuard is attached via @UseGuards(PlatformRoleGuard) on the
    // controller below. NestJS constructs controller-scoped guards using the
    // CONSUMING module's own injector, not the module that originally provides
    // the guard class — so JwtService (a PlatformRoleGuard dependency) must be
    // importable here too, even though AdminAuthModule already registers it.
    JwtModule.register({}),
    MongooseModule.forFeature([
      { name: BusinessTypeMongoose.name, schema: BusinessTypeMongooseSchema },
    ]),
  ],
  controllers: [BusinessTypeController],
  providers: [BusinessTypeService, PlatformRoleGuard],
})
export class BusinessTypeModule {}
