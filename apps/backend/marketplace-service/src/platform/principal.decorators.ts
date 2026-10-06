import {
  createParamDecorator,
  ForbiddenException,
  UnauthorizedException,
  type ExecutionContext,
} from '@nestjs/common';
import { hasPermission, Permissions } from '@nexoraa/shared';

import type { ConsumerPrincipal, MarketplaceRequest, ShopPrincipal } from './marketplace.types';

/** The signed-in customer (set by ConsumerAuthenticationMiddleware). */
export const CurrentConsumer = createParamDecorator(
  (_data: unknown, context: ExecutionContext): ConsumerPrincipal => {
    const consumer = context.switchToHttp().getRequest<MarketplaceRequest>().consumer;
    if (!consumer) throw new UnauthorizedException('A customer session is required');
    return consumer;
  },
);

/** The signed-in shop user (set by ShopAuthenticationMiddleware). */
export const CurrentShop = createParamDecorator(
  (_data: unknown, context: ExecutionContext): ShopPrincipal => {
    const shop = context.switchToHttp().getRequest<MarketplaceRequest>().shop;
    if (!shop) throw new UnauthorizedException('A shop session is required');
    return shop;
  },
);

/** Editing the public listing is limited to owners and branch managers. */
export function assertCanEditListing(shop: ShopPrincipal): void {
  if (!hasPermission(shop.roleCode, shop.permissions, Permissions.branchesWrite)) {
    throw new ForbiddenException('Only the owner or a branch manager can edit the shop listing');
  }
}
