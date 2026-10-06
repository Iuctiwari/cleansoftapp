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
 * A shop's booking number may also be a landline with STD code
 * ("022 2345 6789" → "02223456789"): 10–11 digits after removing +91.
 */
export function normalizeShopPhone(value: string): string | undefined {
  const mobile = normalizeIndianMobile(value);
  if (mobile) return mobile;
  let digits = value.replace(/[\s()-]/g, '');
  if (digits.startsWith('+91')) digits = `0${digits.slice(3)}`;
  return /^0[1-9]\d{8,9}$/.test(digits) ? digits : undefined;
}
