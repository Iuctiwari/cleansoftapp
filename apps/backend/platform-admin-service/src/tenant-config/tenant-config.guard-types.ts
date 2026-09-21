export interface TenantAuthContext {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
}

export interface TenantConfigRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  trustedContext?: TenantAuthContext;
}
