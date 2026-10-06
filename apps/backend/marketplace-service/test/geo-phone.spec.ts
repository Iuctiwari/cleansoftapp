import { distanceMeters, isInIndia, isOpenAt, istClock } from '../src/platform/geo';
import type { OpeningHoursDay } from '../src/platform/marketplace.database';
import { normalizeIndianMobile, normalizeShopPhone } from '../src/platform/phone';

/** A Date for the given India (IST) wall-clock time. 2026-10-05 is a Monday. */
function ist(isoLocal: string): Date {
  return new Date(`${isoLocal}+05:30`);
}

const weekdays: OpeningHoursDay[] = [0, 1, 2, 3, 4, 5, 6].map((day) =>
  day === 0 ? { day, closed: true } : { day, closed: false, open: '09:00', close: '20:00' },
);

describe('opening hours (India time)', () => {
  it('reads the day and time in IST, not the server timezone', () => {
    // 2026-10-05 20:00 UTC is already Tuesday 01:30 in India.
    expect(istClock(new Date('2026-10-05T20:00:00Z'))).toEqual({ day: 2, minutes: 90 });
  });

  it('is open inside the hours and closed outside them and on closed days', () => {
    expect(isOpenAt(weekdays, ist('2026-10-05T09:00:00'))).toBe(true);
    expect(isOpenAt(weekdays, ist('2026-10-05T19:59:00'))).toBe(true);
    expect(isOpenAt(weekdays, ist('2026-10-05T20:00:00'))).toBe(false);
    expect(isOpenAt(weekdays, ist('2026-10-05T08:59:00'))).toBe(false);
    expect(isOpenAt(weekdays, ist('2026-10-04T12:00:00'))).toBe(false); // Sunday
  });

  it('handles shops that close after midnight', () => {
    const lateNight: OpeningHoursDay[] = [0, 1, 2, 3, 4, 5, 6].map((day) =>
      day === 1 ? { day, closed: false, open: '18:00', close: '02:00' } : { day, closed: true },
    );
    expect(isOpenAt(lateNight, ist('2026-10-05T23:00:00'))).toBe(true); // Monday night
    expect(isOpenAt(lateNight, ist('2026-10-06T01:30:00'))).toBe(true); // spills into Tuesday
    expect(isOpenAt(lateNight, ist('2026-10-06T02:00:00'))).toBe(false);
    expect(isOpenAt(lateNight, ist('2026-10-05T17:00:00'))).toBe(false);
  });
});

describe('geo helpers', () => {
  it('measures straight-line distance', () => {
    // Andheri station → Bandra station is roughly 6.6 km.
    const km =
      distanceMeters(
        { latitude: 19.1197, longitude: 72.8468 },
        { latitude: 19.0544, longitude: 72.8406 },
      ) / 1000;
    expect(km).toBeGreaterThan(7);
    expect(km).toBeLessThan(7.5);
  });

  it('rejects points outside India, including swapped lat/lng', () => {
    expect(isInIndia({ latitude: 19.1, longitude: 72.8 })).toBe(true);
    expect(isInIndia({ latitude: 72.8, longitude: 19.1 })).toBe(false);
    expect(isInIndia({ latitude: 0, longitude: 0 })).toBe(false);
  });
});

describe('phone numbers', () => {
  it('normalizes Indian mobiles', () => {
    expect(normalizeIndianMobile('+91 98765 43210')).toBe('9876543210');
    expect(normalizeIndianMobile('12345')).toBeUndefined();
  });

  it('accepts a mobile or a landline with STD code as a booking phone', () => {
    expect(normalizeShopPhone('98765-43210')).toBe('9876543210');
    expect(normalizeShopPhone('022 2345 6789')).toBe('02223456789');
    expect(normalizeShopPhone('+91 22 2345 6789')).toBe('02223456789');
    expect(normalizeShopPhone('12345')).toBeUndefined();
    // A landline whose area code starts like a mobile stays a landline.
    expect(normalizeShopPhone('079 2345 6789')).toBe('07923456789');
    expect(normalizeShopPhone('080-2345-6789')).toBe('08023456789');
    // A mobile typed with a leading 0 keeps it (still dials correctly).
    expect(normalizeShopPhone('098765 43210')).toBe('09876543210');
  });
});
