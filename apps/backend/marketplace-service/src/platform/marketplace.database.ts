import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  type OnModuleDestroy,
  type OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import mongoose, { Schema, type Connection, type Model } from 'mongoose';

import {
  ADDRESS_LABELS,
  SERVICE_MODES,
  SHOP_CATEGORIES,
  type AddressLabel,
  type ServiceMode,
  type ShopCategory,
} from './marketplace.types';

/** GeoJSON point as stored by MongoDB: coordinates are [longitude, latitude]. */
export interface GeoJsonPoint {
  readonly type: 'Point';
  readonly coordinates: [number, number];
}

const geoPointSchema = new Schema<GeoJsonPoint>(
  {
    type: { type: String, enum: ['Point'], required: true },
    coordinates: { type: [Number], required: true },
  },
  { _id: false },
);

// ─── Consumer address ──────────────────────────────────────────────────────

export interface ConsumerAddressDocument {
  readonly addressId: string;
  readonly consumerId: string;
  readonly label: AddressLabel;
  readonly contactName: string;
  readonly contactPhone: string;
  readonly houseFlat: string;
  readonly streetArea: string;
  readonly landmark?: string;
  readonly city: string;
  readonly state: string;
  readonly pincode: string;
  readonly location: GeoJsonPoint;
  readonly isDefault: boolean;
  readonly createdAt: string;
  readonly updatedAt: string;
}

const consumerAddressSchema = new Schema<ConsumerAddressDocument>(
  {
    addressId: { type: String, required: true, unique: true },
    consumerId: { type: String, required: true, index: true },
    label: { type: String, enum: ADDRESS_LABELS, required: true },
    contactName: { type: String, required: true, trim: true },
    contactPhone: { type: String, required: true, trim: true },
    houseFlat: { type: String, required: true, trim: true },
    streetArea: { type: String, required: true, trim: true },
    landmark: { type: String, trim: true },
    city: { type: String, required: true, trim: true },
    state: { type: String, required: true, trim: true },
    pincode: { type: String, required: true, trim: true },
    location: { type: geoPointSchema, required: true },
    isDefault: { type: Boolean, required: true, default: false },
    createdAt: { type: String, required: true },
    updatedAt: { type: String, required: true },
  },
  { collection: 'consumerAddresses', versionKey: false },
);

// ─── Shop listing (one per branch) ──────────────────────────────────────────

export interface OpeningHoursDay {
  /** 0 = Sunday … 6 = Saturday */
  readonly day: number;
  readonly closed: boolean;
  /** "HH:mm", 24-hour, shop local time (IST) */
  readonly open?: string;
  readonly close?: string;
}

export interface ShopAddress {
  readonly streetAddress: string;
  readonly area?: string;
  readonly landmark?: string;
  readonly city: string;
  readonly state: string;
  readonly postalCode: string;
}

export interface ShopListingDocument {
  readonly branchId: string;
  readonly tenantId: string;
  readonly shopName: string;
  readonly branchName: string;
  readonly categories: readonly ShopCategory[];
  readonly address: ShopAddress;
  readonly location?: GeoJsonPoint;
  readonly bookingPhone?: string;
  readonly ownerPhone: string;
  readonly serviceModes: readonly ServiceMode[];
  readonly serviceRadiusKm: number;
  readonly openingHours: readonly OpeningHoursDay[];
  readonly about?: string;
  readonly isListed: boolean;
  readonly tenantStatus: string;
  readonly isComplete: boolean;
  /** isListed && isComplete && tenant Active — the only listings customers can find. */
  readonly searchable: boolean;
  readonly updatedBy: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

const openingHoursSchema = new Schema<OpeningHoursDay>(
  {
    day: { type: Number, min: 0, max: 6, required: true },
    closed: { type: Boolean, required: true },
    open: { type: String },
    close: { type: String },
  },
  { _id: false },
);

const shopListingSchema = new Schema<ShopListingDocument>(
  {
    branchId: { type: String, required: true, unique: true },
    tenantId: { type: String, required: true, index: true },
    shopName: { type: String, required: true },
    branchName: { type: String, required: true },
    categories: { type: [String], enum: SHOP_CATEGORIES, required: true },
    address: {
      type: new Schema<ShopAddress>(
        {
          streetAddress: { type: String, default: '' },
          area: { type: String },
          landmark: { type: String },
          city: { type: String, default: '' },
          state: { type: String, default: '' },
          postalCode: { type: String, default: '' },
        },
        { _id: false },
      ),
      required: true,
    },
    location: { type: geoPointSchema },
    bookingPhone: { type: String },
    ownerPhone: { type: String, default: '' },
    serviceModes: { type: [String], enum: SERVICE_MODES, default: [] },
    serviceRadiusKm: { type: Number, min: 1, max: 50, default: 5 },
    openingHours: { type: [openingHoursSchema], default: [] },
    about: { type: String, maxlength: 300 },
    isListed: { type: Boolean, required: true, default: true },
    tenantStatus: { type: String, required: true },
    isComplete: { type: Boolean, required: true, default: false },
    searchable: { type: Boolean, required: true, default: false, index: true },
    updatedBy: { type: String, required: true },
    createdAt: { type: String, required: true },
    updatedAt: { type: String, required: true },
  },
  { collection: 'shopListings', versionKey: false },
);
// 2dsphere indexes skip documents with no location, so incomplete listings are fine.
shopListingSchema.index({ location: '2dsphere' });

// ─── Service request (customer → shop) ─────────────────────────────────────

export const REQUEST_STATUSES = [
  'Pending',
  'Accepted',
  'Declined',
  'Cancelled',
  'Expired',
  'Completed',
] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];

export interface RequestHistoryEntry {
  readonly status: RequestStatus;
  readonly at: string;
  readonly by: 'customer' | 'shop' | 'system';
  readonly actorId?: string;
  readonly note?: string;
}

export interface RequestAddressSnapshot {
  readonly addressId: string;
  readonly label: string;
  readonly contactName: string;
  readonly contactPhone: string;
  readonly formatted: string;
  readonly landmark?: string;
  readonly location: GeoJsonPoint;
}

/** One service on a salon's online menu. */
export interface SalonMenuItem {
  readonly serviceId: string;
  readonly name: string;
  readonly price: number;
  readonly durationMinutes: number;
  /** The kind of staff who do this service, e.g. "Hair Stylist". */
  readonly role: string;
  /** The price-list entry (service-service) this menu item is billed as, so an order can be made from a booking. */
  readonly catalogServiceId?: string;
  readonly catalogItemCategoryId?: string;
}

/** A person on the salon's roster. They are not app users; the owner lists them here. */
export interface SalonStaffMember {
  readonly staffId: string;
  readonly name: string;
  readonly role: string;
}

/** One service of an appointment, with who does it and when. */
export interface SalonBookedPart {
  readonly serviceId: string;
  readonly name: string;
  readonly price: number;
  readonly durationMinutes: number;
  readonly role: string;
  readonly catalogServiceId?: string;
  readonly catalogItemCategoryId?: string;
  readonly staffId: string;
  readonly staffName: string;
  /** Minutes after midnight, India time. */
  readonly startMinute: number;
  readonly endMinute: number;
}

/** What a salon appointment holds in the diary; set only on salon bookings. */
export interface SalonBookingSnapshot {
  readonly parts: readonly SalonBookedPart[];
  readonly totalPrice: number;
  readonly totalMinutes: number;
  /** Minutes after midnight, India time. */
  readonly startMinute: number;
  readonly endMinute: number;
  /** Salons take payment at the shop, after the service. No advance. */
  readonly payment: 'pay_at_shop';
}

export interface ServiceRequestDocument {
  readonly requestId: string;
  /** Human-friendly, e.g. SR-2026-000123 */
  readonly requestNumber: string;
  readonly consumerId: string;
  readonly customer: { readonly name: string; readonly mobile: string; readonly email: string };
  readonly tenantId: string;
  readonly branchId: string;
  readonly shop: { readonly shopName: string; readonly branchName: string; readonly phone: string };
  readonly category: ShopCategory;
  readonly requestType: ServiceMode;
  readonly description: string;
  readonly items: readonly { readonly name: string; readonly quantity: number }[];
  /** YYYY-MM-DD, India date */
  readonly preferredDate: string;
  readonly preferredSlot: { readonly start: string; readonly end: string };
  readonly address?: RequestAddressSnapshot;
  readonly distanceKm?: number;
  readonly status: RequestStatus;
  readonly confirmedAt?: string;
  readonly shopNote?: string;
  readonly declineReason?: string;
  readonly cancelReason?: string;
  /** The branch's customer-list record (customer-service) for this customer. */
  readonly shopCustomerId?: string;
  readonly orderId?: string;
  readonly orderNumber?: string;
  /** The worker the owner/manager sent to collect the order. */
  readonly pickupWorker?: { readonly userId: string; readonly name: string };
  /** Filled in by that worker at the customer's door. */
  readonly collected?: {
    readonly at: string;
    readonly items: readonly { readonly name: string; readonly quantity: number }[];
    readonly totalQuantity: number;
    readonly byUserId: string;
    readonly note?: string;
    /** S3 keys of the photos the worker took at the door. */
    readonly photos?: readonly string[];
  };
  /** YYYY-MM-DD, India date: when the clothes come back. */
  readonly deliveryDate?: string;
  readonly deliveryDateIsCustom?: boolean;
  /** Salon appointments only: the chosen menu services and the diary time they hold. */
  readonly salon?: SalonBookingSnapshot;
  readonly expiresAt: string;
  readonly statusHistory: readonly RequestHistoryEntry[];
  readonly createdAt: string;
  readonly updatedAt: string;
}

const serviceRequestSchema = new Schema<ServiceRequestDocument>(
  {
    requestId: { type: String, required: true, unique: true },
    requestNumber: { type: String, required: true, unique: true },
    consumerId: { type: String, required: true },
    customer: { type: Schema.Types.Mixed, required: true },
    tenantId: { type: String, required: true },
    branchId: { type: String, required: true },
    shop: { type: Schema.Types.Mixed, required: true },
    category: { type: String, enum: SHOP_CATEGORIES, required: true },
    requestType: { type: String, enum: SERVICE_MODES, required: true },
    description: { type: String, required: true },
    items: { type: [Schema.Types.Mixed], default: [] },
    preferredDate: { type: String, required: true },
    preferredSlot: { type: Schema.Types.Mixed, required: true },
    address: { type: Schema.Types.Mixed },
    distanceKm: { type: Number },
    status: { type: String, enum: REQUEST_STATUSES, required: true },
    confirmedAt: { type: String },
    shopNote: { type: String },
    declineReason: { type: String },
    cancelReason: { type: String },
    shopCustomerId: { type: String },
    orderId: { type: String },
    orderNumber: { type: String },
    pickupWorker: { type: Schema.Types.Mixed },
    collected: { type: Schema.Types.Mixed },
    deliveryDate: { type: String },
    deliveryDateIsCustom: { type: Boolean },
    salon: { type: Schema.Types.Mixed },
    expiresAt: { type: String, required: true },
    statusHistory: { type: [Schema.Types.Mixed], default: [] },
    createdAt: { type: String, required: true },
    updatedAt: { type: String, required: true },
  },
  { collection: 'serviceRequests', versionKey: false },
);
serviceRequestSchema.index({ consumerId: 1, createdAt: -1 });
serviceRequestSchema.index({ branchId: 1, status: 1, createdAt: -1 });
serviceRequestSchema.index({ status: 1, expiresAt: 1 });
serviceRequestSchema.index({ branchId: 1, 'pickupWorker.userId': 1, status: 1 });
// Salon diary lookups: one branch, one day, still holding time.
serviceRequestSchema.index(
  { branchId: 1, preferredDate: 1, status: 1 },
  { partialFilterExpression: { salon: { $exists: true } } },
);
// An order can settle only one request.
serviceRequestSchema.index(
  { orderId: 1 },
  { unique: true, partialFilterExpression: { orderId: { $exists: true } } },
);

// ─── Salon online-booking setup (one per branch) ───────────────────────────

export interface SalonConfigDocument {
  readonly branchId: string;
  readonly tenantId: string;
  /** Length of one bookable slot, in minutes. */
  readonly slotMinutes: number;
  readonly staff: readonly SalonStaffMember[];
  readonly menu: readonly SalonMenuItem[];
  readonly updatedBy: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

const salonConfigSchema = new Schema<SalonConfigDocument>(
  {
    branchId: { type: String, required: true, unique: true },
    tenantId: { type: String, required: true, index: true },
    slotMinutes: { type: Number, required: true },
    staff: { type: [Schema.Types.Mixed], default: [] },
    menu: { type: [Schema.Types.Mixed], default: [] },
    updatedBy: { type: String, required: true },
    createdAt: { type: String, required: true },
    updatedAt: { type: String, required: true },
  },
  { collection: 'salonConfigs', versionKey: false },
);

interface CounterDocument {
  readonly _id: string;
  readonly seq: number;
}
const counterSchema = new Schema<CounterDocument>(
  { _id: { type: String, required: true }, seq: { type: Number, required: true } },
  { collection: 'counters', versionKey: false },
);

/** One Mongo connection for the whole service; models are created once. */
@Injectable()
export class MarketplaceDatabase implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MarketplaceDatabase.name);
  private connection?: Connection;
  private addressModel?: Model<ConsumerAddressDocument>;
  private listingModel?: Model<ShopListingDocument>;
  private requestModel?: Model<ServiceRequestDocument>;
  private salonConfigModel?: Model<SalonConfigDocument>;
  private counterModel?: Model<CounterDocument>;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const uri = this.configService.get<string>(
      'MONGODB_URI',
      'mongodb://localhost:27017/nexoraa_marketplace',
    );
    try {
      this.connection = await mongoose
        .createConnection(uri, { serverSelectionTimeoutMS: 5000, autoIndex: true })
        .asPromise();
      this.addressModel = this.connection.model('ConsumerAddress', consumerAddressSchema);
      this.listingModel = this.connection.model('ShopListing', shopListingSchema);
      this.requestModel = this.connection.model('ServiceRequest', serviceRequestSchema);
      this.salonConfigModel = this.connection.model('SalonConfig', salonConfigSchema);
      this.counterModel = this.connection.model('Counter', counterSchema);
      await Promise.all([
        this.addressModel.syncIndexes(),
        this.listingModel.syncIndexes(),
        this.requestModel.syncIndexes(),
        this.salonConfigModel.syncIndexes(),
      ]);
      this.logger.log('Marketplace MongoDB connection established');
    } catch (error) {
      this.logger.error(
        'MongoDB not reachable. Marketplace persistence is unavailable.',
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.connection?.close();
  }

  get addresses(): Model<ConsumerAddressDocument> {
    return this.ready(this.addressModel);
  }

  get listings(): Model<ShopListingDocument> {
    return this.ready(this.listingModel);
  }

  get requests(): Model<ServiceRequestDocument> {
    return this.ready(this.requestModel);
  }

  get salonConfigs(): Model<SalonConfigDocument> {
    return this.ready(this.salonConfigModel);
  }

  /** Next value of a named sequence (atomic). */
  async nextSequence(name: string): Promise<number> {
    const counter = await this.ready(this.counterModel)
      .findOneAndUpdate({ _id: name }, { $inc: { seq: 1 } }, { new: true, upsert: true })
      .lean()
      .exec();
    return counter.seq;
  }

  private ready<T>(model: Model<T> | undefined): Model<T> {
    if (!model || this.connection?.readyState !== mongoose.ConnectionStates.connected) {
      throw new ServiceUnavailableException('Marketplace storage is temporarily unavailable');
    }
    return model;
  }
}
