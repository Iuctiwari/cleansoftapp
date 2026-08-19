/**
 * V1 known gaps versus the visual reference: Order Service has no
 * receiptNumber, payment method/reference, or staff/cashier display name,
 * and no QR-code generation exists anywhere in the backend. The template
 * renders only fields backed by real OrderRecord/BranchRecord data (see
 * receipt.template.ts) and omits these rather than inventing them.
 */

export interface ReceiptItemView {
  readonly serviceName: string;
  readonly serviceCode?: string;
  readonly categoryName: string;
  readonly measurement: string;
  readonly unitPrice: number;
  readonly discount: number;
  readonly tax: number;
  readonly lineTotal: number;
  readonly notes?: string;
}

/**
 * Human-readable branch display fields sourced from Branch Service's
 * GET /v1/branches/:branchId (see ReceiptBranchClient). Undefined when the
 * branch record could not be resolved — the template must omit the branch
 * line entirely in that case rather than falling back to the raw branchId.
 */
export interface ReceiptBranchView {
  readonly name: string;
  readonly code?: string;
  readonly address?: string;
  readonly phone?: string;
  readonly email?: string;
}
