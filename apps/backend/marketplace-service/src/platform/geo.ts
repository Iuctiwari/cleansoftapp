import type { GeoJsonPoint, OpeningHoursDay } from './marketplace.database';
import type { GeoPoint } from './marketplace.types';

/** Rough bounding box of India — rejects swapped or zeroed coordinates early. */
export function isInIndia(point: GeoPoint): boolean {
  return (
    point.latitude >= 6 &&
    point.latitude <= 37.6 &&
    point.longitude >= 68 &&
    point.longitude <= 97.5
  );
}

export function toGeoJson(point: GeoPoint): GeoJsonPoint {
  return { type: 'Point', coordinates: [point.longitude, point.latitude] };
}

export function fromGeoJson(point: GeoJsonPoint): GeoPoint {
  return { latitude: point.coordinates[1], longitude: point.coordinates[0] };
}

/** Straight-line distance in km, rounded to 0.1 km for display. */
export function roundKm(meters: number): number {
  return Math.round(meters / 100) / 10;
}

const IST_OFFSET_MINUTES = 330;

/** Day of week (0 = Sunday) and minutes since midnight, in India time. */
export function istClock(now: Date): { readonly day: number; readonly minutes: number } {
  const ist = new Date(now.getTime() + IST_OFFSET_MINUTES * 60_000);
  return { day: ist.getUTCDay(), minutes: ist.getUTCHours() * 60 + ist.getUTCMinutes() };
}

export function parseClock(value: string): number {
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
}

/**
 * Whether a shop is open at `now`. A close time earlier than the open time
 * means the shop closes after midnight (e.g. 18:00–02:00).
 */
export function isOpenAt(hours: readonly OpeningHoursDay[], now: Date): boolean {
  const { day, minutes } = istClock(now);
  const opensWithin = (
    entry: OpeningHoursDay | undefined,
    at: number,
    afterMidnight: boolean,
  ): boolean => {
    if (!entry || entry.closed || !entry.open || !entry.close) return false;
    const open = parseClock(entry.open);
    const close = parseClock(entry.close);
    if (close > open) return !afterMidnight && at >= open && at < close;
    // Overnight: today's part runs open→24:00, the spill-over runs 00:00→close next day.
    return afterMidnight ? at < close : at >= open;
  };
  const today = hours.find((entry) => entry.day === day);
  const yesterday = hours.find((entry) => entry.day === (day + 6) % 7);
  return opensWithin(today, minutes, false) || opensWithin(yesterday, minutes, true);
}

export function todayHours(
  hours: readonly OpeningHoursDay[],
  now: Date,
): OpeningHoursDay | undefined {
  return hours.find((entry) => entry.day === istClock(now).day);
}

/** Great-circle distance in meters (same model as MongoDB's spherical $geoNear). */
export function distanceMeters(from: GeoPoint, to: GeoPoint): number {
  const earthRadius = 6_378_100;
  const toRad = (degrees: number): number => (degrees * Math.PI) / 180;
  const dLat = toRad(to.latitude - from.latitude);
  const dLng = toRad(to.longitude - from.longitude);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(from.latitude)) * Math.cos(toRad(to.latitude)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadius * Math.asin(Math.sqrt(a));
}
