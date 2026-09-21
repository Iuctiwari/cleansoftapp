import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import {
  DEFAULT_ACCENT_COLOR_HEX,
  DEFAULT_APP_TITLE,
  DEFAULT_DARK_THEME_ENABLED,
  DEFAULT_PRIMARY_COLOR_HEX,
  DEFAULT_SECONDARY_COLOR_HEX,
} from './theme-defaults';

/**
 * Platform-level configuration keyed by tenantId — does not extend BaseSchema
 * (no tenantId-as-ObjectId applies), same rationale as every other schema in
 * this service. One document per tenant; absence of a document means "use
 * the app's current defaults" (theme-defaults.ts), not "theme is blank."
 */
@DatabaseSchema({ collection: 'platformTenantThemes' })
export class TenantThemeMongoose {
  @Prop({ required: true, trim: true, type: String, unique: true })
  tenantId!: string;

  @Prop({ default: DEFAULT_PRIMARY_COLOR_HEX, required: true, trim: true, type: String })
  primaryColorHex!: string;

  @Prop({ default: DEFAULT_SECONDARY_COLOR_HEX, required: true, trim: true, type: String })
  secondaryColorHex!: string;

  @Prop({ default: DEFAULT_ACCENT_COLOR_HEX, required: true, trim: true, type: String })
  accentColorHex!: string;

  @Prop({ default: DEFAULT_DARK_THEME_ENABLED, required: true, type: Boolean })
  darkThemeEnabled!: boolean;

  @Prop({ default: DEFAULT_APP_TITLE, maxlength: 120, required: true, trim: true, type: String })
  customAppTitle!: string;

  @Prop({ maxlength: 2048, trim: true, type: String })
  logoUrl?: string;

  @Prop({ maxlength: 2048, trim: true, type: String })
  bannerUrl?: string;

  @Prop({ default: false, required: true, type: Boolean })
  allowShopThemeOverride!: boolean;

  @Prop({ required: true, type: String })
  updatedByAdminUserId!: string;
}

export const TenantThemeMongooseSchema = SchemaFactory.createForClass(TenantThemeMongoose);
TenantThemeMongooseSchema.index(
  { tenantId: 1 },
  { name: 'platform_tenant_themes_tenant_unique', unique: true },
);
