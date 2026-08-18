import { InMemoryTenantRepository } from '../../tenant-service/src/tenant/tenant.repository';
import { TenantService } from '../../tenant-service/src/tenant/tenant.service';
import type { CompleteTenantOnboardingInput } from '../../tenant-service/src/tenant/tenant.types';

function onboarding(
  businessType: CompleteTenantOnboardingInput['businessType'],
  services: CompleteTenantOnboardingInput['services'],
): CompleteTenantOnboardingInput {
  return {
    businessName: 'Example CleanSoft',
    businessType,
    ownerName: 'Tenant Owner',
    email: 'owner@example.test',
    mobileNumber: '+919876543210',
    branch: {
      branchName: 'Head Office',
      streetAddress: '1 Main Road',
      city: 'Mumbai',
      postalCode: '400001',
      phone: '+919876543210',
      email: 'branch@example.test',
    },
    services,
    staff: [],
  };
}

describe('Tenant catalog provisioning integration', () => {
  let repository: InMemoryTenantRepository;
  let provision: jest.Mock;
  let service: TenantService;

  beforeEach(() => {
    repository = new InMemoryTenantRepository();
    provision = jest.fn().mockResolvedValue(undefined);
    service = new TenantService(repository, { provision });
  });

  async function register(): Promise<{ tenantId: string; ownerUserId: string }> {
    const result = await service.registerTenant({
      businessName: 'Example CleanSoft',
      businessType: 'dry_cleaning',
      ownerName: 'Tenant Owner',
      email: 'owner@example.test',
      mobileNumber: '+919876543210',
      password: 'Strong!123',
      agreedToTerms: true,
    });
    return { tenantId: result.tenantId, ownerUserId: result.ownerUserId };
  }

  it('provisions the main and all selected business types after onboarding', async () => {
    const tenant = await register();
    await service.completeOnboarding(
      tenant.tenantId,
      onboarding('dry_cleaning', ['laundry', 'salon']),
    );

    expect(provision).toHaveBeenCalledWith({
      tenantId: tenant.tenantId,
      ownerUserId: tenant.ownerUserId,
      businessTypes: ['dry_cleaning', 'laundry', 'salon'],
    });
  });

  it('preserves an enabled business type when another type is added', async () => {
    const tenant = await register();
    await service.completeOnboarding(tenant.tenantId, onboarding('dry_cleaning', ['dry_cleaning']));
    await service.completeOnboarding(tenant.tenantId, onboarding('salon', ['salon']));

    const [candidate] = await repository.listCatalogProvisioningCandidates();
    expect(candidate.businessTypes).toEqual(expect.arrayContaining(['dry_cleaning', 'salon']));
  });

  it('backfills only enabled business types for existing tenants', async () => {
    const tenant = await register();
    await service.completeOnboarding(
      tenant.tenantId,
      onboarding('dry_cleaning', ['dry_cleaning', 'laundry']),
    );
    provision.mockClear();
    const [candidate] = await repository.listCatalogProvisioningCandidates();

    await expect(service.provisionExistingCatalogs()).resolves.toBe(1);
    expect(candidate.tenantId).toBe(tenant.tenantId);
    expect(candidate.businessTypes).toEqual(expect.arrayContaining(['dry_cleaning', 'laundry']));
    expect(provision).toHaveBeenCalledWith(candidate);
  });
});
