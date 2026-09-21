import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, IsUrl, Matches, MaxLength } from 'class-validator';

const HEX_COLOR_PATTERN = /^#[0-9A-Fa-f]{6}$/;

export class UpdateTenantThemeDto {
  @ApiProperty({ required: false, example: '#2563EB' })
  @IsOptional()
  @Matches(HEX_COLOR_PATTERN, {
    message: 'primaryColorHex must be a 6-digit hex color, e.g. #2563EB',
  })
  primaryColorHex?: string;

  @ApiProperty({ required: false, example: '#7C3AED' })
  @IsOptional()
  @Matches(HEX_COLOR_PATTERN, {
    message: 'secondaryColorHex must be a 6-digit hex color, e.g. #7C3AED',
  })
  secondaryColorHex?: string;

  @ApiProperty({ required: false, example: '#0EA5E9' })
  @IsOptional()
  @Matches(HEX_COLOR_PATTERN, {
    message: 'accentColorHex must be a 6-digit hex color, e.g. #0EA5E9',
  })
  accentColorHex?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  darkThemeEnabled?: boolean;

  @ApiProperty({ required: false, maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  customAppTitle?: string;

  @ApiProperty({ required: false, description: 'URL only — no file upload in this phase' })
  @IsOptional()
  @IsUrl()
  @MaxLength(2048)
  logoUrl?: string;

  @ApiProperty({ required: false, description: 'URL only — no file upload in this phase' })
  @IsOptional()
  @IsUrl()
  @MaxLength(2048)
  bannerUrl?: string;

  @ApiProperty({ required: false, default: false })
  @IsOptional()
  @IsBoolean()
  allowShopThemeOverride?: boolean;
}
