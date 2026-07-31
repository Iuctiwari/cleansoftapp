export function toError(value: unknown, fallbackMessage = 'Unknown error'): Error {
  if (value instanceof Error) {
    return value;
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    return new Error(value);
  }

  return new Error(fallbackMessage);
}
