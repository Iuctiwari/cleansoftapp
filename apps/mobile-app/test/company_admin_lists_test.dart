import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/businesses_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/settings_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';

TenantOverviewEntryModel _tenant(int i) => TenantOverviewEntryModel(
  tenantId: 'tenant-$i',
  slug: 'shop-$i',
  businessName: 'Shop $i',
  businessType: 'laundry',
  ownerName: 'Owner $i',
  ownerEmail: 'owner$i@example.com',
  status: 'Active',
);

/// Answers only the two calls these screens make.
class _FakeAdminApi implements CompanyAdminApiService {
  _FakeAdminApi({this.tenants = const <TenantOverviewEntryModel>[], this.types = const <BusinessTypeModel>[]});

  final List<TenantOverviewEntryModel> tenants;
  final List<BusinessTypeModel> types;
  final List<String?> searches = <String?>[];

  @override
  Future<TenantOverviewPageModel> listTenantsOverview({
    String? tenantId,
    String? search,
    String? onboardingStatus,
    String? subscriptionStatus,
    String? planKey,
    int page = 1,
    int limit = 20,
  }) async {
    searches.add(search);
    final List<TenantOverviewEntryModel> matching = tenants
        .where((t) => search == null || search.isEmpty || t.businessName.toLowerCase().contains(search.toLowerCase()))
        .toList();
    final List<TenantOverviewEntryModel> slice = matching.skip((page - 1) * limit).take(limit).toList();
    return TenantOverviewPageModel(items: slice, page: page, limit: limit, total: matching.length);
  }

  @override
  Future<List<BusinessTypeModel>> listBusinessTypes() async => types;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child) {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
      GoRoute(
        path: '/form',
        name: AppRouteNames.companyAdminBusinessTypeForm,
        builder: (_, GoRouterState state) => Text('form:${state.extra is String ? state.extra : 'edit'}'),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

/// The page's list (the search box has its own scrollable inside).
final Finder _list = find.byType(Scrollable).first;

void main() {
  testWidgets('Choose a tenant lists every tenant without typing, search narrows it', (WidgetTester tester) async {
    final _FakeAdminApi api = _FakeAdminApi(tenants: List<TenantOverviewEntryModel>.generate(60, (int i) => _tenant(i + 1)));
    await tester.pumpWidget(_app(SettingsTab(apiService: api)));
    await tester.pumpAndSettle();

    expect(api.searches.first, '');
    expect(find.text('All tenants (60)'), findsOneWidget);
    expect(find.text('Shop 1'), findsOneWidget);

    // 50 per page, then "Load more".
    await tester.scrollUntilVisible(find.textContaining('Load more'), 400, scrollable: _list);
    expect(find.text('Load more (10 more)'), findsOneWidget);
    await tester.tap(find.text('Load more (10 more)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Shop 60'), 400, scrollable: _list);
    expect(find.text('Shop 60'), findsOneWidget);
    expect(find.textContaining('Load more'), findsNothing);

    await tester.scrollUntilVisible(find.byType(TextField), -400, scrollable: _list);
    await tester.enterText(find.byType(TextField), 'Shop 5');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('11 matches'), findsOneWidget); // Shop 5 and Shop 50–59
    expect(find.text('Shop 12'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('All tenants (60)'), findsOneWidget); // clearing the search shows everyone again
  });

  testWidgets('Businesses lists all built-in types, configured or not', (WidgetTester tester) async {
    final _FakeAdminApi api = _FakeAdminApi(
      types: <BusinessTypeModel>[
        BusinessTypeModel(
          id: 'bt-1',
          value: 'laundry',
          label: 'laundry',
          isActive: true,
          defaultTerminology: BusinessTypeTerminologyModel.fallback,
          defaultOrderStatuses: const <String>[],
          defaultServices: const <String>[],
          defaultItemCategories: const <String>[],
          defaultExpenseCategories: const <String>[],
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(BusinessesTab(apiService: api)));
    await tester.pumpAndSettle();

    expect(find.text('10 business types · 1 configured'), findsOneWidget);
    for (final String label in kBuiltInBusinessTypes.values.where((String l) => l != 'Laundry')) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Configured'), findsOneWidget);
    expect(find.text('Not configured yet — tap to set defaults'), findsNWidgets(9));

    await tester.tap(find.text('Salon'));
    await tester.pumpAndSettle();
    expect(find.text('form:salon'), findsOneWidget);
  });
}
