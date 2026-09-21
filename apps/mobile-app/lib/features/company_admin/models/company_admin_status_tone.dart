import 'package:nexoraa_mobile/design_system/design_system.dart';

/// Shared status→badge-tone mapping for tenant status (tenant-service's
/// Tenant.status) and subscription status (TenantSubscriptionStatus) badges
/// across the company_admin screens.
AppBadgeTone companyAdminStatusTone(String status) {
  switch (status) {
    case 'Active':
    case 'ACTIVE':
    case 'TRIALING':
      return AppBadgeTone.success;
    case 'PendingVerification':
    case 'PAST_DUE':
      return AppBadgeTone.warning;
    case 'Suspended':
    case 'SUSPENDED':
    case 'Cancelled':
    case 'CANCELED':
    case 'EXPIRED':
      return AppBadgeTone.error;
    default:
      return AppBadgeTone.neutral;
  }
}
