import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_token_storage.dart';

/// Mirrors AuthenticationDependencies' static-singleton shape, but is a
/// completely separate object graph — company admin auth must never share
/// state with tenant/staff auth (AuthenticationDependencies).
abstract final class CompanyAdminDependencies {
  static CompanyAdminTokenStorage tokenStorage = SecureCompanyAdminTokenStorage();

  static CompanyAdminApiService apiService = CompanyAdminApiService(
    tokenStorage: tokenStorage,
  );
}
