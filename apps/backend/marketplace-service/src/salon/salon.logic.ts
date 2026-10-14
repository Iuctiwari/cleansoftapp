/**
 * Pure scheduling maths for salon appointments. Times are minutes after
 * midnight, India time. A booking is a list of parts: each chosen service is
 * done by one staff member of the right role, one after the other.
 */

export const SLOT_LENGTHS = [15, 30, 45, 60] as const;

export type SlotState = 'available' | 'pending' | 'booked' | 'unavailable';

export interface StaffMember {
  readonly staffId: string;
  readonly name: string;
  /** What they do, e.g. "Hair Stylist", "Makeup Artist". Menu services ask for a role. */
  readonly role: string;
}

/** Time a staff member is already holding (Pending or Accepted). */
export interface HeldPart {
  readonly staffId: string;
  readonly start: number;
  readonly end: number;
  readonly accepted: boolean;
}

/** One service of a booking, before anybody is assigned. */
export interface PartNeed {
  readonly serviceId: string;
  readonly role: string;
  /** Number of consecutive slots the service takes. */
  readonly slots: number;
}

export interface AssignedPart {
  readonly serviceId: string;
  readonly staffId: string;
  readonly start: number;
  readonly end: number;
}

export interface OpeningDay {
  readonly day: number;
  readonly closed: boolean;
  readonly open?: string;
  readonly close?: string;
}

export interface SlotView {
  readonly start: string;
  readonly end: string;
  readonly state: SlotState;
}

export function parseClock(clock: string): number {
  const [hours, minutes] = clock.split(':').map(Number);
  return hours * 60 + minutes;
}

export function formatClock(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  return `${String(hours).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
}

/** The shop's open window on a YYYY-MM-DD date, or undefined when it is closed. */
export function openWindow(
  hours: readonly OpeningDay[],
  date: string,
): { readonly open: number; readonly close: number } | undefined {
  const weekday = new Date(`${date}T00:00:00Z`).getUTCDay();
  const day = hours.find((candidate) => candidate.day === weekday);
  if (!day || day.closed || !day.open || !day.close) return undefined;
  const open = parseClock(day.open);
  const close = parseClock(day.close);
  return close > open ? { open, close } : undefined;
}

/** How many consecutive slots a service of this many minutes takes. */
export function slotsNeeded(minutes: number, slotMinutes: number): number {
  return Math.max(1, Math.ceil(minutes / slotMinutes));
}

/** True when `start` is one of the shop's slot start times for the day. */
export function isSlotStart(
  open: number,
  close: number,
  slotMinutes: number,
  start: number,
): boolean {
  return start >= open && start + slotMinutes <= close && (start - open) % slotMinutes === 0;
}

const clashes = (part: HeldPart, start: number, end: number): boolean =>
  part.start < end && part.end > start;

export type Assignment =
  | { readonly ok: true; readonly parts: readonly AssignedPart[] }
  | { readonly ok: false; readonly state: 'pending' | 'booked' | 'unavailable' };

export interface AssignInput {
  readonly staff: readonly StaffMember[];
  readonly held: readonly HeldPart[];
  readonly needs: readonly PartNeed[];
  readonly start: number;
  readonly slotMinutes: number;
  /** Owner's picks, by service id. Anyone else is chosen automatically. */
  readonly preferred?: Readonly<Record<string, string>>;
}

/**
 * Gives every service a free staff member of its role, services running back
 * to back from `start`. Auto-pick: the person with the least booked time that
 * day, so work spreads out. Fails with why: nobody has the role (unavailable),
 * everyone is held by waiting requests (pending) or by confirmed ones (booked).
 */
export function assignParts(input: AssignInput): Assignment {
  const { staff, held, needs, slotMinutes, preferred } = input;
  const minutesBooked = (staffId: string): number =>
    held
      .filter((part) => part.staffId === staffId)
      .reduce((sum, part) => sum + (part.end - part.start), 0);
  const parts: AssignedPart[] = [];
  let at = input.start;
  let worst: 'pending' | 'booked' | undefined;

  for (const need of needs) {
    const start = at;
    const end = at + need.slots * slotMinutes;
    at = end;
    const candidates = staff.filter((member) => member.role === need.role);
    if (candidates.length === 0) return { ok: false, state: 'unavailable' };

    const conflicts = (staffId: string): HeldPart[] =>
      held.filter((part) => part.staffId === staffId && clashes(part, start, end));
    const wanted = preferred?.[need.serviceId];
    const free = candidates.filter((member) => conflicts(member.staffId).length === 0);
    const chosen =
      free.find((member) => member.staffId === wanted) ??
      [...free].sort((a, b) => minutesBooked(a.staffId) - minutesBooked(b.staffId))[0];
    if (chosen) {
      parts.push({ serviceId: need.serviceId, staffId: chosen.staffId, start, end });
      continue;
    }
    const everyoneConfirmed = candidates.every((member) =>
      conflicts(member.staffId).some((part) => part.accepted),
    );
    worst = everyoneConfirmed || worst === 'booked' ? 'booked' : 'pending';
  }
  return worst ? { ok: false, state: worst } : { ok: true, parts };
}

export interface SlotGridInput {
  readonly open: number;
  readonly close: number;
  readonly slotMinutes: number;
  readonly staff: readonly StaffMember[];
  readonly held: readonly HeldPart[];
  /** The chosen services; empty means "any one slot with anyone free". */
  readonly needs: readonly PartNeed[];
  /** Earliest start still allowed, e.g. "now" when the date is today. */
  readonly earliestStart?: number;
}

/** Every slot start of the day and whether the whole booking fits there. */
export function buildSlots(input: SlotGridInput): SlotView[] {
  const { open, close, slotMinutes, staff, held, earliestStart } = input;
  const needs: readonly PartNeed[] =
    input.needs.length > 0 ? input.needs : [{ serviceId: '', role: '', slots: 1 }];
  const anyone = input.needs.length === 0;
  const total = needs.reduce((sum, need) => sum + need.slots, 0) * slotMinutes;
  const slots: SlotView[] = [];

  for (let start = open; start + slotMinutes <= close; start += slotMinutes) {
    const end = start + total;
    if (end > close || (earliestStart !== undefined && start < earliestStart)) {
      slots.push({
        start: formatClock(start),
        end: formatClock(Math.min(end, close)),
        state: 'unavailable',
      });
      continue;
    }
    const result = anyone
      ? assignAnyone(staff, held, start, end)
      : assignParts({ staff, held, needs, start, slotMinutes });
    slots.push({
      start: formatClock(start),
      end: formatClock(end),
      state: result.ok ? 'available' : result.state,
    });
  }
  return slots;
}

/** Before services are chosen: a slot is open if anyone at all is free in it. */
function assignAnyone(
  staff: readonly StaffMember[],
  held: readonly HeldPart[],
  start: number,
  end: number,
): Assignment {
  if (staff.length === 0) return { ok: false, state: 'unavailable' };
  const busy = staff.map((member) =>
    held.filter((part) => part.staffId === member.staffId && clashes(part, start, end)),
  );
  if (busy.some((parts) => parts.length === 0)) return { ok: true, parts: [] };
  return {
    ok: false,
    state: busy.every((parts) => parts.some((part) => part.accepted)) ? 'booked' : 'pending',
  };
}
