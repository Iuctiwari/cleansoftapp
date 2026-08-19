import { Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import puppeteer, { type Browser } from 'puppeteer';

import { OrderService } from '../order/order.service';
import type { OrderScope } from '../order/order.types';
import { ReceiptBranchClient } from './receipt-branch.client';
import { buildReceiptHtml } from './templates/receipt.template';

@Injectable()
export class ReceiptService {
  private readonly logger = new Logger(ReceiptService.name);

  constructor(
    private readonly orderService: OrderService,
    private readonly branchClient: ReceiptBranchClient,
  ) {}

  async generatePdf(scope: OrderScope, orderId: string): Promise<Buffer> {
    // OrderService.get() enforces the same tenant/branch/role scope and
    // Order-not-found handling used by GET /orders/:id — the receipt never
    // reads order data any other way. Branch details are best-effort: a
    // failed lookup must not block receipt generation (see ReceiptBranchClient).
    const [order, branch] = await Promise.all([
      this.orderService.get(scope, orderId),
      this.branchClient.resolve(scope),
    ]);
    const html = buildReceiptHtml(order, branch);

    let browser: Browser | undefined;
    try {
      browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });
      const page = await browser.newPage();
      try {
        await page.setContent(html, { waitUntil: 'networkidle0' });
        const pdf = await page.pdf({
          format: 'a4',
          printBackground: true,
          margin: { top: '0', bottom: '0', left: '0', right: '0' },
        });
        return Buffer.from(pdf);
      } finally {
        await page.close();
      }
    } catch (error) {
      this.logger.error(
        'Receipt PDF generation failed',
        error instanceof Error ? error.stack : error,
      );
      throw new InternalServerErrorException('Unable to generate the receipt PDF');
    } finally {
      if (browser) await browser.close();
    }
  }
}
