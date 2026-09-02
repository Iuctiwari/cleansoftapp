import { OrderPaymentStatus, OrderStatus } from '../../order/enums';
import type { OrderItemRecord, OrderRecord } from '../../order/order.types';
import type { ReceiptBranchView, ReceiptItemView } from '../receipt.types';

const CURRENCY = 'LKR';

const COMPANY = {
  name: 'NEXORAA',
  tagline: 'CLEANSOFT',
  phone: '011 2 123 456',
  email: 'support@nexoraa.com',
  website: 'www.nexoraa.com',
};

// Brand tokens copied from apps/mobile-app/lib/design_system/colors/app_colors.dart
// so the PDF uses the same palette as the app rather than an approximation.
const COLOR = {
  primary: '#2563EB',
  primaryDark: '#1D4ED8',
  primarySurface: '#EFF6FF',
  primaryBorder: '#BFDBFE',
  ink: '#0F172A',
  textBody: '#374151',
  textMuted: '#64748B',
  textSubtle: '#94A3B8',
  background: '#F8FAFC',
  surfaceMuted: '#F1F5F9',
  border: '#E2E8F0',
  success: '#16A34A',
  successDark: '#059669',
  successSurface: '#F0FDF4',
  successBorder: '#BBF7D0',
};

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function text(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim() ? value.trim() : undefined;
}

function money(value: number): string {
  return `${CURRENCY} ${value.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

function formatDate(value?: Date): string {
  if (!value) return '—';
  return new Date(value).toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
}

function formatDateOnly(value?: Date): string {
  if (!value) return '—';
  return new Date(value).toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

const STATUS_LABEL: Record<OrderStatus, string> = {
  [OrderStatus.DRAFT]: 'Draft',
  [OrderStatus.RECEIVED]: 'Received',
  [OrderStatus.ASSIGNED]: 'Assigned',
  [OrderStatus.ACCEPTED]: 'Accepted',
  [OrderStatus.REJECTED]: 'Rejected',
  [OrderStatus.IN_PROGRESS]: 'In Progress',
  [OrderStatus.READY]: 'Ready',
  [OrderStatus.OUT_FOR_DELIVERY]: 'Out for Delivery',
  [OrderStatus.DELIVERED]: 'Completed',
  [OrderStatus.CANCELLED]: 'Cancelled',
};

const PAYMENT_STATUS_LABEL: Record<OrderPaymentStatus, string> = {
  [OrderPaymentStatus.UNPAID]: 'Unpaid',
  [OrderPaymentStatus.PENDING]: 'Pending',
  [OrderPaymentStatus.PARTIALLY_PAID]: 'Partially Paid',
  [OrderPaymentStatus.PAID]: 'Paid',
  [OrderPaymentStatus.PARTIALLY_REFUNDED]: 'Partially Refunded',
  [OrderPaymentStatus.REFUNDED]: 'Refunded',
};

// Matches apps/mobile-app/lib/design_system/widgets/app_brand_logo.dart:
// the repo has no standalone logo image (see AppAssets.logo's own comment),
// so its actual brand mark — AppIcons.brandCheck (Material "check") on a
// rounded, tinted badge — is reproduced here as inline SVG rather than
// approximated with different iconography or plain text.
const LOGO_SVG = `
<svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <rect width="40" height="40" rx="12" fill="rgba(255,255,255,0.18)" stroke="rgba(255,255,255,0.3)"/>
  <path d="M12 20.5L17 25.5L28 14.5" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`;

const ICON = {
  order: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="${COLOR.primary}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 9h16M9 4v16"/></svg>`,
  person: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="${COLOR.primary}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>`,
  calendar: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${COLOR.textMuted}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>`,
  check: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${COLOR.textMuted}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/></svg>`,
  heart: `<svg width="15" height="15" viewBox="0 0 24 24" fill="${COLOR.primary}"><path d="M12 21s-7.5-4.6-10-9.1C.5 8.6 2.4 5 6 5c2 0 3.5 1.1 4.5 2.6C11.5 6.1 13 5 15 5c3.6 0 5.5 3.6 4 6.9-2.5 4.5-10 9.1-10 9.1z"/></svg>`,
  phone: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="${COLOR.textBody}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4 2h3a2 2 0 0 1 2 1.7c.1.9.3 1.8.6 2.7a2 2 0 0 1-.5 2.1L7.9 9.7a16 16 0 0 0 6 6l1.2-1.2a2 2 0 0 1 2.1-.5c.9.3 1.8.5 2.7.6a2 2 0 0 1 1.7 2z"/></svg>`,
  mail: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="${COLOR.textBody}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m2 7 10 6 10-6"/></svg>`,
  globe: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="${COLOR.textBody}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20 15 15 0 0 1 0-20z"/></svg>`,
};

function measurement(item: OrderItemRecord, unitType?: string): string {
  const unit = unitType ?? (item.weight !== undefined ? 'kg' : 'pcs');
  const quantity = item.weight ?? item.quantity;
  if (quantity === undefined) return '—';
  const compact = Number.isInteger(quantity) ? quantity.toString() : quantity.toFixed(2);
  return `${compact} ${unit}`;
}

function toItemView(item: OrderItemRecord): ReceiptItemView {
  const category = item.itemCategorySnapshot;
  const service = item.serviceSnapshot;
  return {
    serviceName: text(service.name) ?? 'Service',
    serviceCode: text(service.code),
    categoryName: text(category.name) ?? 'Item',
    measurement: measurement(item, text(category.unitType)),
    unitPrice: item.unitPrice,
    discount: item.discount,
    tax: item.tax,
    lineTotal: item.lineTotal,
    notes: text(item.notes),
  };
}

function itemRow(view: ReceiptItemView, index: number): string {
  return `
    <tr>
      <td class="col-index">${index + 1}</td>
      <td class="col-service">
        <div class="service-name">${escapeHtml(view.serviceName)}</div>
        ${view.notes ? `<div class="service-notes">${escapeHtml(view.notes)}</div>` : ''}
      </td>
      <td class="col-category">${escapeHtml(view.categoryName)}</td>
      <td class="col-measurement">${escapeHtml(view.measurement)}</td>
      <td class="col-money">${money(view.unitPrice)}</td>
      <td class="col-money">${view.discount > 0 ? money(view.discount) : '—'}</td>
      <td class="col-money">${money(view.tax)}</td>
      <td class="col-money col-line-total">${money(view.lineTotal)}</td>
    </tr>`;
}

function infoRow(label: string, value?: string): string {
  if (!value) return '';
  return `<div class="info-row"><span class="info-label">${escapeHtml(label)}</span><span class="info-value">${escapeHtml(value)}</span></div>`;
}

function footerTile(icon: string, label: string, value?: string): string {
  if (!value) return '';
  return `
    <div class="footer-tile">
      <div class="footer-tile-icon">${icon}</div>
      <div class="footer-tile-label">${escapeHtml(label)}</div>
      <div class="footer-tile-value">${escapeHtml(value)}</div>
    </div>`;
}

function branchLine(branch?: ReceiptBranchView): string | undefined {
  if (!branch) return undefined;
  return branch.code ? `${branch.name} (${branch.code})` : branch.name;
}

export function buildReceiptHtml(order: OrderRecord, branch?: ReceiptBranchView): string {
  const customer = order.customerSnapshot;
  const customerName = text(customer.name) ?? 'Customer';
  const customerMobile = text(customer.mobile);
  const customerEmail = text(customer.email);
  const customerAddress = text(customer.address);

  const items = order.items.map((item) => toItemView(item));
  const generatedAt = formatDate(new Date());
  const isPaid = order.outstandingAmount <= 0 && order.paidAmount > 0;

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  @page { size: A4; margin: 0; }
  html, body { background: ${COLOR.background}; }
  body {
    font-family: 'Segoe UI', Arial, sans-serif;
    color: ${COLOR.ink};
    font-size: 13px;
    line-height: 1.45;
  }
  .page { width: 210mm; min-height: 297mm; margin: 0 auto; padding: 14mm 13mm; background: #ffffff; }

  .header {
    background: linear-gradient(135deg, ${COLOR.primary}, ${COLOR.primaryDark});
    color: #ffffff;
    border-radius: 12px;
    padding: 20px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }
  .brand { display: flex; align-items: center; gap: 12px; }
  .brand-name { font-size: 21px; font-weight: 800; letter-spacing: 0.5px; line-height: 1.1; }
  .brand-tagline { font-size: 10px; letter-spacing: 3px; opacity: 0.85; margin-top: 2px; }
  .header-right { text-align: right; }
  .receipt-title { font-size: 24px; font-weight: 800; }
  .receipt-subtitle { font-size: 10.5px; opacity: 0.85; margin-top: 3px; }

  .section-title {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.4px;
    color: ${COLOR.primary};
    text-transform: uppercase;
    margin-bottom: 10px;
  }

  .info-grid {
    display: flex;
    gap: 28px;
    background: ${COLOR.primarySurface};
    border: 1px solid ${COLOR.primaryBorder};
    border-radius: 10px;
    padding: 16px 20px;
    margin-bottom: 18px;
  }
  .info-col { flex: 1; min-width: 0; }
  .info-row { display: flex; justify-content: space-between; padding: 4px 0; gap: 14px; }
  .info-label { color: ${COLOR.textMuted}; }
  .info-value { font-weight: 600; text-align: right; word-break: break-word; max-width: 62%; }

  table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
  thead th {
    background: ${COLOR.primaryDark};
    color: #ffffff;
    font-size: 9.5px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    padding: 10px 8px;
    text-align: left;
  }
  thead th:first-child { border-radius: 6px 0 0 0; }
  thead th:last-child { border-radius: 0 6px 0 0; }
  thead th.col-money, thead th.col-index { text-align: right; }
  thead th.col-index { text-align: center; }
  tbody td { padding: 9px 8px; border-bottom: 1px solid ${COLOR.border}; vertical-align: top; word-break: break-word; }
  tbody tr:nth-child(even) { background: ${COLOR.background}; }
  tr { page-break-inside: avoid; }
  thead { display: table-header-group; }
  .col-index { text-align: center; color: ${COLOR.textMuted}; }
  .col-money { text-align: right; white-space: nowrap; }
  .col-line-total { font-weight: 700; }
  .service-name { font-weight: 600; }
  .service-notes { color: ${COLOR.textMuted}; font-size: 10px; margin-top: 2px; }

  .totals-wrap { display: flex; justify-content: flex-end; margin-bottom: 18px; }
  .totals-box { width: 280px; }
  .totals-row { display: flex; justify-content: space-between; padding: 5px 0; }
  .totals-row.muted { color: ${COLOR.textMuted}; }
  .totals-divider { border-top: 1px solid ${COLOR.border}; margin: 8px 0; }
  .grand-total { display: flex; justify-content: space-between; align-items: baseline; font-size: 17px; font-weight: 800; color: ${COLOR.primaryDark}; padding: 4px 0; }
  .payment-box {
    background: ${COLOR.successSurface};
    border: 1px solid ${COLOR.successBorder};
    border-radius: 8px;
    padding: 10px 12px;
    margin-top: 10px;
  }
  .payment-row { display: flex; justify-content: space-between; font-weight: 700; color: ${COLOR.successDark}; padding: 2px 0; }
  .payment-row.outstanding { color: ${COLOR.textBody}; font-weight: 600; }

  .footer-strip {
    display: flex;
    background: ${COLOR.surfaceMuted};
    border: 1px solid ${COLOR.border};
    border-radius: 10px;
    overflow: hidden;
    margin-bottom: 18px;
  }
  .footer-tile {
    flex: 1;
    text-align: center;
    padding: 12px 8px;
    border-right: 1px solid ${COLOR.border};
  }
  .footer-tile:last-child { border-right: none; }
  .footer-tile-icon { margin-bottom: 4px; }
  .footer-tile-label { font-size: 8.5px; color: ${COLOR.textMuted}; text-transform: uppercase; letter-spacing: 0.3px; }
  .footer-tile-value { font-weight: 700; margin-top: 3px; font-size: 11.5px; }

  .thanks {
    background: ${COLOR.primarySurface};
    border: 1px solid ${COLOR.primaryBorder};
    border-radius: 10px;
    padding: 18px;
    text-align: center;
  }
  .thanks-title { display: flex; align-items: center; justify-content: center; gap: 6px; font-style: italic; color: ${COLOR.primaryDark}; font-size: 17px; font-weight: 700; }
  .thanks-sub { color: ${COLOR.textMuted}; font-size: 10.5px; margin-top: 3px; }
  .contact-row { margin-top: 12px; font-size: 10px; color: ${COLOR.textBody}; display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; }
  .contact-item { display: inline-flex; align-items: center; gap: 5px; }

  .legal { text-align: center; color: ${COLOR.textSubtle}; font-size: 9px; margin-top: 14px; }

  @media print {
    .page { width: auto; min-height: auto; margin: 0; }
  }
</style>
</head>
<body>
  <div class="page">
    <div class="header">
      <div class="brand">
        ${LOGO_SVG}
        <div>
          <div class="brand-name">${escapeHtml(COMPANY.name)}</div>
          <div class="brand-tagline">${escapeHtml(COMPANY.tagline)}</div>
        </div>
      </div>
      <div class="header-right">
        <div class="receipt-title">Receipt</div>
        <div class="receipt-subtitle">Thank you for choosing Nexoraa CleanSoft!</div>
      </div>
    </div>

    <div class="info-grid">
      <div class="info-col">
        <div class="section-title">${ICON.order} Order Information</div>
        ${infoRow('Order Number', order.orderNumber)}
        ${infoRow('Order Date', formatDate(order.createdAt))}
        ${infoRow('Branch', branchLine(branch))}
        ${infoRow('Order Status', STATUS_LABEL[order.status])}
        ${infoRow('Payment Status', PAYMENT_STATUS_LABEL[order.paymentStatus])}
      </div>
      <div class="info-col">
        <div class="section-title">${ICON.person} Customer Information</div>
        ${infoRow('Name', customerName)}
        ${infoRow('Mobile', customerMobile)}
        ${infoRow('Email', customerEmail)}
        ${infoRow('Address', customerAddress)}
      </div>
    </div>

    <div class="section-title">${ICON.order} Services</div>
    <table>
      <thead>
        <tr>
          <th class="col-index">#</th>
          <th>Service / Item</th>
          <th>Category</th>
          <th>Qty / Wt</th>
          <th class="col-money">Unit Price</th>
          <th class="col-money">Disc.</th>
          <th class="col-money">Tax</th>
          <th class="col-money">Line Total</th>
        </tr>
      </thead>
      <tbody>
        ${items.map((view, index) => itemRow(view, index)).join('')}
      </tbody>
    </table>

    <div class="totals-wrap">
      <div class="totals-box">
        <div class="totals-row"><span>Subtotal</span><span>${money(order.subtotal)}</span></div>
        <div class="totals-row muted">
          <span>Discount${order.discountPercentage > 0 ? ` (${order.discountPercentage}%)` : ''}</span>
          <span>- ${money(order.discount)}</span>
        </div>
        <div class="totals-row"><span>Tax</span><span>${money(order.tax)}</span></div>
        <div class="totals-divider"></div>
        <div class="grand-total"><span>Grand Total</span><span>${money(order.grandTotal)}</span></div>
        <div class="payment-box">
          <div class="payment-row"><span>${isPaid ? `${ICON.check} ` : ''}Paid Amount</span><span>${money(order.paidAmount)}</span></div>
          <div class="payment-row outstanding"><span>Outstanding</span><span>${money(order.outstandingAmount)}</span></div>
        </div>
      </div>
    </div>

    <div class="footer-strip">
      ${footerTile(ICON.calendar, 'Expected Delivery', formatDateOnly(order.expectedDeliveryDate))}
      ${footerTile(ICON.check, 'Delivered On', formatDateOnly(order.deliveryDate))}
    </div>

    <div class="thanks">
      <div class="thanks-title">${ICON.heart} Thank You!</div>
      <div class="thanks-sub">For a cleaner, healthier tomorrow.</div>
      <div class="contact-row">
        <span class="contact-item">${ICON.phone} ${escapeHtml(COMPANY.phone)}</span>
        <span class="contact-item">${ICON.mail} ${escapeHtml(COMPANY.email)}</span>
        <span class="contact-item">${ICON.globe} ${escapeHtml(COMPANY.website)}</span>
      </div>
    </div>

    <div class="legal">
      This is an electronically generated receipt and does not require a signature. Generated ${generatedAt}.
    </div>
  </div>
</body>
</html>`;
}
