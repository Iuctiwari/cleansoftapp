import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/settings/models/settings_models.dart';
import 'package:nexoraa_mobile/features/settings/services/settings_api_service.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

class ServicesSettingsScreen extends StatefulWidget {
  const ServicesSettingsScreen({
    super.key,
    this.apiService,
    this.tenantApiService,
  });

  final SettingsApiService? apiService;
  final TenantApiService? tenantApiService;

  @override
  State<ServicesSettingsScreen> createState() => _ServicesSettingsScreenState();
}

class _ServicesSettingsScreenState extends State<ServicesSettingsScreen> {
  late final SettingsApiService _apiService;
  late final TenantApiService _tenantApiService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';
  String? _tenantBusinessType;

  List<SettingsServiceModel> _allServices = <SettingsServiceModel>[];
  List<SettingsItemModel> _allItems = <SettingsItemModel>[];
  List<SettingsCategoryModel> _allCategories = <SettingsCategoryModel>[];
  List<SettingsCatalogTemplateModel> _templates =
      <SettingsCatalogTemplateModel>[];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customServiceNameController =
      TextEditingController();
  String _selectedPricingType = 'PerItem';
  String _selectedCategory = 'Laundry / Dry Cleaning';

  static String normalizePricingType(String raw) {
    final clean = raw.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (clean) {
      case 'peritem':
      case 'item':
        return 'PerItem';
      case 'perkg':
      case 'kg':
        return 'PerKg';
      case 'perpair':
      case 'pair':
        return 'PerPair';
      case 'perhour':
      case 'hour':
        return 'PerHour';
      case 'fixed':
        return 'Fixed';
      case 'custom':
        return 'Custom';
      default:
        return 'PerItem';
    }
  }

  static String normalizeBusinessType(String raw) {
    final clean = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean.contains('laundry') || clean.contains('dryclean')) {
      return 'dry_cleaning';
    }
    if (clean.contains('salon')) {
      return 'salon';
    }
    if (clean.contains('carwash') ||
        clean.contains('vehiclewash') ||
        clean.contains('washcar') ||
        clean.contains('washvehicle')) {
      return 'vehicle_wash';
    }
    if (clean.contains('appliance')) {
      return 'appliance_repair';
    }
    if (clean.contains('shoe')) {
      return 'shoe_cleaning';
    }
    if (clean.contains('tailor')) {
      return 'tailoring';
    }
    if (clean.contains('mobile')) {
      return 'mobile_repair';
    }
    return clean;
  }

  static String getPricingLabel(String raw) {
    final normalized = normalizePricingType(raw);
    return _pricingTypeLabels[normalized] ?? _pricingTypeLabels[raw] ?? raw;
  }

  static const List<MapEntry<String, String>> _pricingDropdownOptions = [
    MapEntry('PerItem', 'Per Item'),
    MapEntry('PerKg', 'Per Kg'),
    MapEntry('PerPair', 'Per Pair'),
    MapEntry('PerHour', 'Per Hour'),
    MapEntry('Fixed', 'Fixed'),
    MapEntry('Custom', 'Custom'),
  ];

  static const Map<String, String> _pricingTypeLabels = <String, String>{
    'PerItem': 'Per Item',
    'PerKg': 'Per Kg',
    'PerPair': 'Per Pair',
    'PerHour': 'Per Hour',
    'Fixed': 'Fixed',
    'Custom': 'Custom',
    'per_item': 'Per Item',
    'per_kg': 'Per Kg',
    'per_pair': 'Per Pair',
    'fixed': 'Fixed',
    'custom': 'Custom',
  };

  static const List<SettingsCatalogTemplateModel> _fallbackTemplates = [
    SettingsCatalogTemplateModel(
      code: 'LAUNDRY_DRY_CLEANING',
      businessType: 'dry_cleaning',
      name: 'Laundry / Dry Cleaning',
      services: [
        TemplateServiceModel(
          code: 'SERVICE_DRY_CLEANING',
          name: 'Dry Cleaning',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SERVICE_WASH_FOLD',
          name: 'Wash & Fold',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SERVICE_IRONING',
          name: 'Ironing',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SERVICE_PREMIUM_CLEANING',
          name: 'Premium Cleaning',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SERVICE_WASH_ONLY',
          name: 'Wash Only',
          pricingType: 'per_item',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'SALON',
      businessType: 'salon',
      name: 'Salon',
      services: [
        TemplateServiceModel(
          code: 'SALON_HAIRCUT',
          name: 'Haircut',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_HAIR_WASH',
          name: 'Hair Wash',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_HAIR_COLOR',
          name: 'Hair Coloring',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_HAIR_STYLING',
          name: 'Hair Styling',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_FACIAL',
          name: 'Facial',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_MANICURE',
          name: 'Manicure',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_PEDICURE',
          name: 'Pedicure',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_CURLING',
          name: 'Curling',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'SALON_STRAIGHTENING',
          name: 'Straightening',
          pricingType: 'per_item',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'CAR_WASH',
      businessType: 'vehicle_wash',
      name: 'Car Washing',
      services: [
        TemplateServiceModel(
          code: 'CAR_INTERIOR',
          name: 'Interior Cleaning',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'CAR_EXTERIOR',
          name: 'Exterior Cleaning',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'CAR_FULL_WASH',
          name: 'Full Wash',
          pricingType: 'per_item',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'APPLIANCE_REPAIR',
      businessType: 'appliance_repair',
      name: 'Appliance Repair',
      services: [
        TemplateServiceModel(
          code: 'APPLIANCE_INSPECTION',
          name: 'Inspection',
          pricingType: 'fixed',
        ),
        TemplateServiceModel(
          code: 'APPLIANCE_REPAIR_SERVICE',
          name: 'Repair',
          pricingType: 'custom',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'SHOE_CLEANING',
      businessType: 'shoe_cleaning',
      name: 'Shoe Cleaning',
      services: [
        TemplateServiceModel(
          code: 'SHOE_BASIC_CLEAN',
          name: 'Basic Cleaning',
          pricingType: 'per_pair',
        ),
        TemplateServiceModel(
          code: 'SHOE_DEEP_CLEAN',
          name: 'Deep Cleaning',
          pricingType: 'per_pair',
        ),
        TemplateServiceModel(
          code: 'SHOE_POLISH',
          name: 'Polishing',
          pricingType: 'per_pair',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'TAILORING',
      businessType: 'tailoring',
      name: 'Tailoring',
      services: [
        TemplateServiceModel(
          code: 'TAILOR_STITCHING',
          name: 'Stitching',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'TAILOR_ALTERATION',
          name: 'Alteration',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'TAILOR_REPAIR',
          name: 'Repair',
          pricingType: 'per_item',
        ),
      ],
    ),
    SettingsCatalogTemplateModel(
      code: 'MOBILE_REPAIR',
      businessType: 'mobile_repair',
      name: 'Mobile Repair',
      services: [
        TemplateServiceModel(
          code: 'MOBILE_DIAGNOSTIC',
          name: 'Diagnostic',
          pricingType: 'fixed',
        ),
        TemplateServiceModel(
          code: 'MOBILE_SCREEN_REPAIR',
          name: 'Screen Repair',
          pricingType: 'per_item',
        ),
        TemplateServiceModel(
          code: 'MOBILE_BATTERY_REPLACEMENT',
          name: 'Battery Replacement',
          pricingType: 'per_item',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _apiService =
        widget.apiService ??
        SettingsApiService(
          tokenStorage: AuthenticationDependencies.tokenStorage,
        );
    _tenantApiService =
        widget.tenantApiService ??
        TenantApiService(tokenStorage: AuthenticationDependencies.tokenStorage);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customServiceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await AuthenticationDependencies.tokenStorage.read();
      if (session?.tenantId != null && session!.tenantId!.isNotEmpty) {
        try {
          final profile = await _tenantApiService.getTenantProfile(
            session.tenantId!,
          );
          if (profile.businessType != null &&
              profile.businessType!.trim().isNotEmpty) {
            _tenantBusinessType = profile.businessType!.trim();
          }
        } catch (_) {}
      }

      final summary = await _apiService.getSummary();
      List<SettingsCatalogTemplateModel> templates = [];
      try {
        templates = await _apiService.getTemplates();
      } catch (_) {
        templates = _fallbackTemplates;
      }

      if (templates.isEmpty) {
        templates = _fallbackTemplates;
      }

      if (!mounted) return;

      setState(() {
        _allItems = List<SettingsItemModel>.from(summary.items);
        _allServices = List<SettingsServiceModel>.from(summary.services);
        _allCategories = List<SettingsCategoryModel>.from(summary.categories);
        _templates = templates;
        if (_availableCategoryOptions.isNotEmpty &&
            !_availableCategoryOptions.contains(_selectedCategory)) {
          _selectedCategory = _availableCategoryOptions.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _resolvedBusinessType {
    if (_tenantBusinessType != null && _tenantBusinessType!.trim().isNotEmpty) {
      final normalized = normalizeBusinessType(_tenantBusinessType!);
      if (normalized.isNotEmpty) return normalized;
    }

    final templatesToFilter = _templates.isNotEmpty
        ? _templates
        : _fallbackTemplates;

    for (final item in _allItems) {
      for (final code in item.catalogGroupCodes) {
        final norm = normalizeBusinessType(code);
        if (norm.isNotEmpty &&
            templatesToFilter.any(
              (t) =>
                  normalizeBusinessType(t.code) == norm ||
                  normalizeBusinessType(t.businessType) == norm,
            )) {
          return norm;
        }
      }
      if (item.category != null && item.category!.trim().isNotEmpty) {
        final norm = normalizeBusinessType(item.category!);
        if (norm.isNotEmpty &&
            templatesToFilter.any(
              (t) =>
                  normalizeBusinessType(t.name) == norm ||
                  normalizeBusinessType(t.businessType) == norm,
            )) {
          return norm;
        }
      }
    }

    final sortedServices = [
      ..._allServices.where((s) => s.isActive),
      ..._allServices.where((s) => !s.isActive),
    ];
    for (final service in sortedServices) {
      for (final template in templatesToFilter) {
        final sCode = service.code.toUpperCase().trim();
        final sName = service.name.toLowerCase().trim();
        if (template.services.any(
          (ts) =>
              ts.code.toUpperCase().trim() == sCode ||
              ts.name.toLowerCase().trim() == sName,
        )) {
          return normalizeBusinessType(template.businessType);
        }
      }
      if (service.description != null &&
          service.description!.trim().isNotEmpty) {
        final norm = normalizeBusinessType(service.description!);
        if (norm.isNotEmpty &&
            templatesToFilter.any(
              (t) =>
                  normalizeBusinessType(t.name) == norm ||
                  normalizeBusinessType(t.businessType) == norm,
            )) {
          return norm;
        }
      }
    }

    for (final cat in _allCategories) {
      final norm = normalizeBusinessType(
        cat.code.isNotEmpty ? cat.code : cat.name,
      );
      if (norm.isNotEmpty &&
          templatesToFilter.any(
            (t) =>
                normalizeBusinessType(t.code) == norm ||
                normalizeBusinessType(t.businessType) == norm ||
                normalizeBusinessType(t.name) == norm,
          )) {
        return norm;
      }
    }

    return 'dry_cleaning';
  }

  List<SettingsCatalogTemplateModel> get _tenantTemplates {
    final templatesToFilter = _templates.isNotEmpty
        ? _templates
        : _fallbackTemplates;

    final String currentType = _resolvedBusinessType;

    final matching = templatesToFilter.where((t) {
      final tCodeNorm = normalizeBusinessType(t.code);
      final tTypeNorm = normalizeBusinessType(t.businessType);
      final tNameNorm = normalizeBusinessType(t.name);
      return tCodeNorm == currentType ||
          tTypeNorm == currentType ||
          tNameNorm == currentType;
    }).toList();

    if (matching.isNotEmpty) {
      return matching;
    }

    return [templatesToFilter.first];
  }

  List<String> get _availableCategoryOptions {
    final Set<String> categories = <String>{};
    for (final template in _tenantTemplates) {
      categories.add(_formatCategoryName(template.name));
    }
    for (final cat in _allCategories) {
      if (cat.name.isNotEmpty) {
        final catNorm = normalizeBusinessType(
          cat.code.isNotEmpty ? cat.code : cat.name,
        );
        if (catNorm == _resolvedBusinessType ||
            _tenantTemplates.any(
              (t) =>
                  _formatCategoryName(t.name).toLowerCase() ==
                  cat.name.toLowerCase(),
            )) {
          categories.add(cat.name);
        }
      }
    }
    if (categories.isEmpty && _tenantTemplates.isNotEmpty) {
      categories.add(_formatCategoryName(_tenantTemplates.first.name));
    }
    return categories.toList();
  }

  String _formatCategoryName(String raw) {
    final trimmed = raw.replaceAll('Template', '').trim();
    if (trimmed.toLowerCase() == 'dry cleaning' ||
        trimmed.toLowerCase() == 'laundry') {
      return 'Laundry / Dry Cleaning';
    }
    if (trimmed.toLowerCase() == 'car wash') {
      return 'Car Washing';
    }
    return trimmed;
  }

  List<SettingsServiceModel> get _activeServices {
    return _allServices.where((service) {
      if (!service.isActive) return false;
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return service.name.toLowerCase().contains(query) ||
          service.code.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, List<_AvailableServiceItem>> get _groupedAvailableServices {
    final Map<String, List<_AvailableServiceItem>> grouped = {};
    final Set<String> activeCodes = _allServices
        .where((s) => s.isActive)
        .map((s) => s.code.toUpperCase().trim())
        .toSet();
    final Set<String> activeNames = _allServices
        .where((s) => s.isActive)
        .map((s) => s.name.toLowerCase().trim())
        .toSet();

    // 1. Group ONLY from tenant's business templates
    final templatesToUse = _tenantTemplates;
    for (final template in templatesToUse) {
      final categoryName = _formatCategoryName(template.name);
      final List<_AvailableServiceItem> items = [];

      for (final service in template.services) {
        final code = service.code.toUpperCase().trim();
        final name = service.name.toLowerCase().trim();

        if (activeCodes.contains(code) || activeNames.contains(name)) {
          continue;
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          if (!service.name.toLowerCase().contains(q) &&
              !service.code.toLowerCase().contains(q)) {
            continue;
          }
        }

        // Check if exists as inactive in _allServices
        final existingInactive = _allServices
            .where((s) => !s.isActive)
            .cast<SettingsServiceModel?>()
            .firstWhere(
              (s) =>
                  s != null &&
                  (s.code.toUpperCase() == code ||
                      s.name.toLowerCase() == name),
              orElse: () => null,
            );

        items.add(
          _AvailableServiceItem(
            code: service.code,
            name: service.name,
            pricingType: service.pricingType,
            description: service.description,
            categoryName: categoryName,
            existingModel: existingInactive,
          ),
        );
      }

      if (items.isNotEmpty) {
        if (!grouped.containsKey(categoryName)) {
          grouped[categoryName] = [];
        }
        grouped[categoryName]!.addAll(items);
      }
    }

    // 2. Also check any tenant inactive custom services that belong to the current business
    final Set<String> templateCodes = templatesToUse
        .expand((t) => t.services)
        .map((s) => s.code.toUpperCase().trim())
        .toSet();

    for (final service in _allServices.where((s) => !s.isActive)) {
      if (templateCodes.contains(service.code.toUpperCase().trim())) {
        continue;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!service.name.toLowerCase().contains(q) &&
            !service.code.toLowerCase().contains(q)) {
          continue;
        }
      }

      // Strict filter: only include if service category/description belongs to the current business
      final sCategory = service.description?.trim() ?? '';
      if (sCategory.isNotEmpty) {
        final sCatNorm = normalizeBusinessType(sCategory);
        final matchesBusiness =
            sCatNorm == _resolvedBusinessType ||
            _tenantTemplates.any(
              (t) =>
                  _formatCategoryName(t.name).toLowerCase() ==
                  sCategory.toLowerCase(),
            );
        if (!matchesBusiness) {
          continue;
        }
      }

      final categoryName = sCategory.isNotEmpty
          ? sCategory
          : (_tenantTemplates.isNotEmpty
                ? _formatCategoryName(_tenantTemplates.first.name)
                : 'Custom Services');

      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(
        _AvailableServiceItem(
          code: service.code,
          name: service.name,
          pricingType: service.pricingType,
          description: service.description,
          categoryName: categoryName,
          existingModel: service,
        ),
      );
    }

    return grouped;
  }

  Future<void> _removeService(SettingsServiceModel service) async {
    setState(() {
      final index = _allServices.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _allServices[index] = service.copyWith(status: 'Inactive');
      }
    });

    try {
      await _apiService.updateService(service.id, status: 'Inactive');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to remove service: $e', isError: true);
      _loadData();
    }
  }

  Future<void> _addService(SettingsServiceModel service) async {
    setState(() {
      final index = _allServices.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _allServices[index] = service.copyWith(status: 'Active');
      }
    });

    try {
      await _apiService.updateService(service.id, status: 'Active');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to add service: $e', isError: true);
      _loadData();
    }
  }

  Future<void> _addAvailableItem(_AvailableServiceItem item) async {
    if (item.existingModel != null) {
      await _addService(item.existingModel!);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newService = await _apiService.createService(
        serviceName: item.name,
        code: item.code,
        pricingType: normalizePricingType(item.pricingType),
        description: item.categoryName,
        status: 'Active',
      );

      if (!mounted) return;
      setState(() {
        _allServices.add(newService);
        _isSaving = false;
      });

      _showSnackBar('Service "${item.name}" added successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Failed to add service: $e', isError: true);
    }
  }

  Future<void> _addCustomService() async {
    final String name = _customServiceNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a service name', isError: true);
      return;
    }

    final String code = name.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '_',
    );

    // Check if service with same code or name already exists in _allServices
    final existingIndex = _allServices.indexWhere(
      (s) =>
          s.code.toUpperCase().trim() == code.trim() ||
          s.name.toLowerCase().trim() == name.toLowerCase().trim(),
    );

    if (existingIndex != -1) {
      final existing = _allServices[existingIndex];
      if (existing.isActive) {
        _showSnackBar(
          'Service "$name" is already in active services',
          isError: true,
        );
        return;
      }
      _customServiceNameController.clear();
      await _addService(existing);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newService = await _apiService.createService(
        serviceName: name,
        code: code,
        pricingType: normalizePricingType(_selectedPricingType),
        description: _selectedCategory,
        status: 'Active',
      );

      _customServiceNameController.clear();

      if (!mounted) return;
      setState(() {
        _allServices.add(newService);
        _isSaving = false;
      });

      _showSnackBar('Service "$name" added successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Failed to add service: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final groupedAvailable = _groupedAvailableServices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          AppIcons.arrowBack,
                          size: 20,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your service offerings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: <Widget>[
                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search services...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section: CURRENT SERVICES
                    Text(
                      'CURRENT SERVICES (${_activeServices.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_activeServices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No active services configured. Add services below.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._activeServices.map(
                        (service) => _buildActiveServiceCard(service),
                      ),

                    const SizedBox(height: 24),

                    // Section: AVAILABLE SERVICES GROUPED BY CATEGORY
                    if (groupedAvailable.isNotEmpty) ...<Widget>[
                      const Text(
                        'AVAILABLE SERVICES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...groupedAvailable.entries.map((entry) {
                        final categoryTitle = entry.key;
                        final services = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        categoryTitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${services.length} available',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              ...services.map(
                                (item) => _buildAvailableServiceTile(item),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Section: ADD CUSTOM SERVICE
                    _buildAddCustomServiceCard(),
                  ],
                ),
              ),

            // Bottom Save Services Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          _showSnackBar(
                            'Services configuration saved successfully',
                          );
                          Navigator.of(context).maybePop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Services',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveServiceCard(SettingsServiceModel service) {
    final String pricingLabel = getPricingLabel(service.pricingType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pricing: $pricingLabel${service.estimatedTimeMins != null ? ' • ${service.estimatedTimeMins} mins' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _removeService(service),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServiceTile(_AvailableServiceItem item) {
    final String pricingLabel = getPricingLabel(item.pricingType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pricing: $pricingLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _isSaving ? null : () => _addAvailableItem(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCategoryDropdownOpen = false;

  Widget _buildCategorySelector(List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isCategoryDropdownOpen
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: _isCategoryDropdownOpen ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _isCategoryDropdownOpen = !_isCategoryDropdownOpen;
                });
              },
              hoverColor: const Color(0xFFF1F5F9),
              splashColor: const Color(0xFFE2E8F0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isCategoryDropdownOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: _isCategoryDropdownOpen
                ? Column(
                    children: <Widget>[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = category == _selectedCategory;
                            return Material(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                    _isCategoryDropdownOpen = false;
                                  });
                                },
                                hoverColor: const Color(0xFFF1F5F9),
                                splashColor: const Color(0xFFDBEAFE),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isPricingTypeDropdownOpen = false;

  Widget _buildPricingTypeSelector() {
    final currentOption = _pricingDropdownOptions.firstWhere(
      (opt) => opt.key == _selectedPricingType,
      orElse: () => _pricingDropdownOptions.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isPricingTypeDropdownOpen
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: _isPricingTypeDropdownOpen ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _isPricingTypeDropdownOpen = !_isPricingTypeDropdownOpen;
                  if (_isPricingTypeDropdownOpen) {
                    _isCategoryDropdownOpen = false;
                  }
                });
              },
              hoverColor: const Color(0xFFF1F5F9),
              splashColor: const Color(0xFFE2E8F0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        currentOption.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isPricingTypeDropdownOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: _isPricingTypeDropdownOpen
                ? Column(
                    children: <Widget>[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _pricingDropdownOptions.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final option = _pricingDropdownOptions[index];
                            final isSelected =
                                option.key == _selectedPricingType;
                            return Material(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPricingType = option.key;
                                    _isPricingTypeDropdownOpen = false;
                                  });
                                },
                                hoverColor: const Color(0xFFF1F5F9),
                                splashColor: const Color(0xFFDBEAFE),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          option.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomServiceCard() {
    final categories = _availableCategoryOptions;
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ADD CUSTOM SERVICE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          // Service Name Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _customServiceNameController,
              decoration: const InputDecoration(
                hintText: 'Service name (e.g. Steam Press)...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category Selector Dropdown with Smooth Animation and Design-System Styling
          _buildCategorySelector(categories),
          const SizedBox(height: 12),
          // Pricing Type and Submit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildPricingTypeSelector()),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isSaving ? null : _addCustomService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailableServiceItem {
  const _AvailableServiceItem({
    required this.code,
    required this.name,
    required this.pricingType,
    required this.categoryName,
    this.description,
    this.existingModel,
  });

  final String code;
  final String name;
  final String pricingType;
  final String categoryName;
  final String? description;
  final SettingsServiceModel? existingModel;
}
