import { Controller, Get, Param, Req, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiInternalServerErrorResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiProduces,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { type OrderRequest, OrderScopeGuard } from '../order/order.guard';
import { OrderIdPipe } from '../order/order-id.pipe';
import type { OrderScope } from '../order/order.types';
import { ReceiptService } from './receipt.service';

const ID_PARAMETER = {
  description: 'Order MongoDB ObjectId.',
  example: '64f0c18f7c4d2f0012ab34cd',
  name: 'orderId',
  schema: { pattern: '^[0-9a-fA-F]{24}$', type: 'string' },
};

function scope(request: OrderRequest): OrderScope {
  if (!request.orderScope) throw new Error('Order scope guard was not applied');
  return request.orderScope;
}

@ApiTags('Orders')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(OrderScopeGuard)
@Controller({ path: 'orders', version: '1' })
export class ReceiptController {
  constructor(private readonly receiptService: ReceiptService) {}

  @Get(':orderId/receipt')
  @ApiOperation({ summary: 'Generate the printable/downloadable PDF receipt for a scoped order' })
  @ApiParam(ID_PARAMETER)
  @ApiProduces('application/pdf')
  @ApiOkResponse({ description: 'Receipt PDF bytes.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiInternalServerErrorResponse({ description: 'Receipt generation failed unexpectedly.' })
  async receipt(
    @Req() request: OrderRequest,
    @Param('orderId', OrderIdPipe) orderId: string,
    @Res() response: Response,
  ): Promise<void> {
    // Nest's Express adapter JSON-serializes any returned Buffer instead of
    // writing raw bytes, which corrupts the PDF, so the response is written
    // directly here rather than via a controller return value.
    const pdf = await this.receiptService.generatePdf(scope(request), orderId);
    response
      .status(200)
      .set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': 'inline; filename="receipt.pdf"',
        'Content-Length': pdf.length,
      })
      .end(pdf);
  }
}
