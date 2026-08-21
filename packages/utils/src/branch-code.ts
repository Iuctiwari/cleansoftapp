const AUTO_BRANCH_CODE_PREFIX = 'NX-';
const AUTO_BRANCH_CODE_DIGITS = 3;
const AUTO_BRANCH_CODE_RETRIES = 5;

export function nextAvailableBranchCode(existingCodes: readonly string[]): string {
  const usedCodes = new Set(existingCodes.map((code) => code.trim().toUpperCase()));
  let sequence = 1;
  while (
    usedCodes.has(
      `${AUTO_BRANCH_CODE_PREFIX}${String(sequence).padStart(AUTO_BRANCH_CODE_DIGITS, '0')}`,
    )
  ) {
    sequence += 1;
  }
  return `${AUTO_BRANCH_CODE_PREFIX}${String(sequence).padStart(AUTO_BRANCH_CODE_DIGITS, '0')}`;
}

export { AUTO_BRANCH_CODE_PREFIX, AUTO_BRANCH_CODE_DIGITS, AUTO_BRANCH_CODE_RETRIES };
