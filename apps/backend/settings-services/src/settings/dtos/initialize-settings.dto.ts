import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class InitializeTenantSettingsDto {
  @ApiProperty({ description: 'Target Tenant ID', example: '64f0c18f7c4d2f0012ab3400' })
  @IsString()
  @IsNotEmpty()
  tenantId!: string;

  @ApiProperty({ description: 'Owner or Actor User ID', example: '64f0c18f7c4d2f0012ab3401' })
  @IsString()
  @IsNotEmpty()
  actorId!: string;

  @ApiProperty({
    description:
      'Selected business / catalog type (e.g. DRY_CLEANING, LAUNDRY, CAR_WASH, SALON, etc.)',
    example: 'DRY_CLEANING',
  })
  @IsString()
  @IsNotEmpty()
  businessType!: string;
}

export class InitializeTenantSettingsResponseDto {
  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  businessType!: string;

  @ApiProperty()
  appliedTemplate!: string;

  @ApiProperty()
  createdItems!: number;

  @ApiProperty()
  createdServices!: number;

  @ApiProperty()
  createdMappings!: number;

  @ApiProperty()
  createdPrices!: number;
}
