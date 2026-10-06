export function normalizeIdentifier(identifier: string): string {
  return identifier.trim().toLowerCase();
}

/**
 * Indian mobile number → its 10 significant digits ("+91 98765-43210" → "9876543210").
 * Returns undefined when the value is not a valid Indian mobile number.
 */
export function normalizeIndianMobile(value: string): string | undefined {
  let digits = value.replace(/[\s()-]/g, '');
  if (digits.startsWith('+91')) digits = digits.slice(3);
  else if (digits.length === 12 && digits.startsWith('91')) digits = digits.slice(2);
  else if (digits.length === 11 && digits.startsWith('0')) digits = digits.slice(1);
  return /^[6-9]\d{9}$/.test(digits) ? digits : undefined;
}
