import { timingSafeEqual } from 'node:crypto';

import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface InternalRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

@Injectable()
export class CatalogProvisioningGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<InternalRequest>();
    const supplied = this.header(request, 'x-catalog-provisioning-key');
    const expected = this.configService.get<string>('CATALOG_PROVISIONING_KEY')?.trim();
    if (!supplied || !expected || !this.matches(supplied, expected)) {
      throw new UnauthorizedException(
        'Valid internal catalog provisioning credentials are required',
      );
    }
    return true;
  }

  private header(request: InternalRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private matches(supplied: string, expected: string): boolean {
    const suppliedBuffer = Buffer.from(supplied);
    const expectedBuffer = Buffer.from(expected);
    return (
      suppliedBuffer.length === expectedBuffer.length &&
      timingSafeEqual(suppliedBuffer, expectedBuffer)
    );
  }
}
