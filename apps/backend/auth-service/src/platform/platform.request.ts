import type { TrustedContext } from './platform.types';

export const REQUEST_CONTEXT_KEY = 'trustedContext';

export interface RequestWithPlatformContext {
  headers: Record<string, string | string[] | undefined>;
  correlationId?: string;
  trustedContext?: TrustedContext;
}
