import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class OverviewTenantsDto {
  @ApiProperty({ required: false, description: 'Exact lookup; ignores every other filter.' })
  @IsOptional()
  @IsString()
  tenantId?: string;

  @ApiProperty({ required: false, description: 'Matches businessName, ownerName, or ownerEmail.' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiProperty({
    required: false,
    enum: ['PendingVerification', 'Active', 'Suspended', 'Cancelled'],
    description: "tenant-service's own onboarding status.",
  })
  @IsOptional()
  @IsString()
  onboardingStatus?: string;

  @ApiProperty({
    required: false,
    enum: ['TRIALING', 'ACTIVE', 'PAST_DUE', 'EXPIRED', 'SUSPENDED', 'CANCELED'],
  })
  @IsOptional()
  @IsString()
  subscriptionStatus?: string;

  @ApiProperty({
    required: false,
    enum: ['FREE_TRIAL', 'STARTER', 'PRO', 'ENTERPRISE', 'CUSTOM'],
  })
  @IsOptional()
  @IsString()
  planKey?: string;

  @ApiProperty({ required: false, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiProperty({ required: false, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
