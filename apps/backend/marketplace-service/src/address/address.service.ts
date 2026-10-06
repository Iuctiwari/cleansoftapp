import { randomUUID } from 'node:crypto';

import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { fromGeoJson, isInIndia, toGeoJson } from '../platform/geo';
import {
  MarketplaceDatabase,
  type ConsumerAddressDocument,
} from '../platform/marketplace.database';
import type { AddressLabel, ConsumerPrincipal, GeoPoint } from '../platform/marketplace.types';
import { normalizeIndianMobile } from '../platform/phone';
import type { CreateAddressDto, UpdateAddressDto } from './address.dto';

export const MAX_ADDRESSES_PER_CONSUMER = 10;

export interface ConsumerAddressView {
  readonly addressId: string;
  readonly label: AddressLabel;
  readonly contactName: string;
  readonly contactPhone: string;
  readonly houseFlat: string;
  readonly streetArea: string;
  readonly landmark?: string;
  readonly city: string;
  readonly state: string;
  readonly pincode: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly isDefault: boolean;
  /** One-line address for list rows, e.g. "Flat 302, Lokhandwala, Mumbai 400053". */
  readonly formatted: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

function toView(address: ConsumerAddressDocument): ConsumerAddressView {
  const point = fromGeoJson(address.location);
  return {
    addressId: address.addressId,
    label: address.label,
    contactName: address.contactName,
    contactPhone: address.contactPhone,
    houseFlat: address.houseFlat,
    streetArea: address.streetArea,
    landmark: address.landmark || undefined,
    city: address.city,
    state: address.state,
    pincode: address.pincode,
    latitude: point.latitude,
    longitude: point.longitude,
    isDefault: address.isDefault,
    formatted: `${address.houseFlat}, ${address.streetArea}, ${address.city} ${address.pincode}`,
    createdAt: address.createdAt,
    updatedAt: address.updatedAt,
  };
}

function assertInIndia(point: GeoPoint): void {
  if (!isInIndia(point)) {
    throw new BadRequestException('The address pin must be a location in India');
  }
}

function contactPhoneOrThrow(value: string): string {
  const phone = normalizeIndianMobile(value);
  if (!phone) throw new BadRequestException('contactPhone must be a valid Indian mobile number');
  return phone;
}

@Injectable()
export class AddressService {
  constructor(private readonly database: MarketplaceDatabase) {}

  async list(consumerId: string): Promise<ConsumerAddressView[]> {
    const addresses = await this.database.addresses
      .find({ consumerId }, { _id: 0 })
      .sort({ isDefault: -1, createdAt: -1 })
      .lean()
      .exec();
    return addresses.map(toView);
  }

  async create(consumer: ConsumerPrincipal, input: CreateAddressDto): Promise<ConsumerAddressView> {
    const point = { latitude: input.latitude, longitude: input.longitude };
    assertInIndia(point);

    const existing = await this.database.addresses.countDocuments({
      consumerId: consumer.consumerId,
    });
    if (existing >= MAX_ADDRESSES_PER_CONSUMER) {
      throw new ConflictException(
        `You can save up to ${MAX_ADDRESSES_PER_CONSUMER} addresses — delete one to add another`,
      );
    }

    const now = new Date().toISOString();
    const isDefault = existing === 0 || input.isDefault === true;
    const address: ConsumerAddressDocument = {
      addressId: randomUUID(),
      consumerId: consumer.consumerId,
      label: input.label,
      contactName: input.contactName?.trim() || consumer.displayName,
      contactPhone: contactPhoneOrThrow(input.contactPhone?.trim() || consumer.mobileNumber),
      houseFlat: input.houseFlat.trim(),
      streetArea: input.streetArea.trim(),
      landmark: input.landmark?.trim() || undefined,
      city: input.city.trim(),
      state: input.state.trim(),
      pincode: input.pincode,
      location: toGeoJson(point),
      isDefault,
      createdAt: now,
      updatedAt: now,
    };

    if (isDefault) await this.clearDefault(consumer.consumerId);
    await this.database.addresses.create(address);
    return toView(address);
  }

  async update(
    consumerId: string,
    addressId: string,
    input: UpdateAddressDto,
  ): Promise<ConsumerAddressView> {
    const current = await this.findOwned(consumerId, addressId);

    if ((input.latitude === undefined) !== (input.longitude === undefined)) {
      throw new BadRequestException('latitude and longitude must be updated together');
    }
    const location =
      input.latitude !== undefined && input.longitude !== undefined
        ? { latitude: input.latitude, longitude: input.longitude }
        : undefined;
    if (location) assertInIndia(location);

    const trimmed = (value: string | undefined): string | undefined =>
      value === undefined ? undefined : value.trim();
    const changes: Partial<ConsumerAddressDocument> = Object.fromEntries(
      Object.entries({
        label: input.label,
        contactName: trimmed(input.contactName) || undefined,
        contactPhone: input.contactPhone ? contactPhoneOrThrow(input.contactPhone) : undefined,
        houseFlat: trimmed(input.houseFlat),
        streetArea: trimmed(input.streetArea),
        city: trimmed(input.city),
        state: trimmed(input.state),
        pincode: input.pincode,
        location: location ? toGeoJson(location) : undefined,
      }).filter(([, value]) => value !== undefined && value !== ''),
    );
    const landmark = trimmed(input.landmark);

    if (input.isDefault === true && !current.isDefault) await this.clearDefault(consumerId);

    const updated = await this.database.addresses
      .findOneAndUpdate(
        { consumerId, addressId },
        {
          $set: {
            ...changes,
            ...(landmark ? { landmark } : {}),
            // The default can only move by choosing another address as default.
            ...(input.isDefault === true ? { isDefault: true } : {}),
            updatedAt: new Date().toISOString(),
          },
          ...(landmark === '' ? { $unset: { landmark: '' } } : {}),
        },
        { new: true, projection: { _id: 0 } },
      )
      .lean()
      .exec();
    if (!updated) throw new NotFoundException('Address not found');
    return toView(updated);
  }

  async setDefault(consumerId: string, addressId: string): Promise<ConsumerAddressView> {
    await this.findOwned(consumerId, addressId);
    return this.update(consumerId, addressId, { isDefault: true });
  }

  async remove(consumerId: string, addressId: string): Promise<void> {
    const address = await this.findOwned(consumerId, addressId);
    const count = await this.database.addresses.countDocuments({ consumerId });
    if (count <= 1) {
      throw new ConflictException(
        'An address is required — add another address before deleting this one',
      );
    }

    await this.database.addresses.deleteOne({ consumerId, addressId }).exec();
    if (address.isDefault) {
      const newest = await this.database.addresses
        .findOne({ consumerId })
        .sort({ createdAt: -1 })
        .exec();
      if (newest) {
        await this.database.addresses
          .updateOne({ consumerId, addressId: newest.addressId }, { $set: { isDefault: true } })
          .exec();
      }
    }
  }

  /** The address to search from: the one asked for, else the default. */
  async resolve(consumerId: string, addressId?: string): Promise<ConsumerAddressView> {
    if (addressId) return toView(await this.findOwned(consumerId, addressId));

    const fallback = await this.database.addresses
      .findOne({ consumerId }, { _id: 0 })
      .sort({ isDefault: -1, createdAt: -1 })
      .lean()
      .exec();
    if (!fallback) {
      throw new ConflictException('Add your address first to see shops near you');
    }
    return toView(fallback);
  }

  private async findOwned(consumerId: string, addressId: string): Promise<ConsumerAddressDocument> {
    // Scoped by consumerId: another customer's addressId is simply "not found".
    const address = await this.database.addresses
      .findOne({ consumerId, addressId }, { _id: 0 })
      .lean()
      .exec();
    if (!address) throw new NotFoundException('Address not found');
    return address;
  }

  private async clearDefault(consumerId: string): Promise<void> {
    await this.database.addresses
      .updateMany({ consumerId, isDefault: true }, { $set: { isDefault: false } })
      .exec();
  }
}
