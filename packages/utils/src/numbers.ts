export function toPositiveInteger(value: unknown, fallback: number): number {
  const parsed = typeof value === 'number' ? value : Number(value);

  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}
