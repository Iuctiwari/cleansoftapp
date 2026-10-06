/**
 * Indian mobile number → its 10 significant digits
 * ("+91 98765-43210" → "9876543210"). Same rule as auth-service.
 */
export function normalizeIndianMobile(value: string): string | undefined {
  let digits = value.replace(/[\s()-]/g, '');
  if (digits.startsWith('+91')) digits = digits.slice(3);
  else if (digits.length === 12 && digits.startsWith('91')) digits = digits.slice(2);
  else if (digits.length === 11 && digits.startsWith('0')) digits = digits.slice(1);
  return /^[6-9]\d{9}$/.test(digits) ? digits : undefined;
}

/**
 * A shop's booking number: a 10-digit mobile, or anything dialled with a
 * leading 0 (a landline with STD code, or a mobile written "0 98765…").
 * A leading 0 is kept as typed — "079 2345 6789" must not be mistaken for the
 * mobile 79234 56789, and 0 + a mobile number still dials that mobile.
 */
export function normalizeShopPhone(value: string): string | undefined {
  let digits = value.replace(/[\s()-]/g, '');
  if (digits.startsWith('+91')) {
    const rest = digits.slice(3);
    return /^[6-9]\d{9}$/.test(rest) ? rest : /^[1-9]\d{8,9}$/.test(rest) ? `0${rest}` : undefined;
  }
  if (digits.length === 12 && digits.startsWith('91')) digits = digits.slice(2);
  if (/^[6-9]\d{9}$/.test(digits)) return digits;
  return /^0[1-9]\d{8,9}$/.test(digits) ? digits : undefined;
}
