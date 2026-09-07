import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/settings/models/settings_models.dart';
import 'package:nexoraa_mobile/features/settings/services/settings_api_service.dart';

class PricingSettingsScreen extends StatefulWidget {
  const PricingSettingsScreen({super.key, this.apiService});

  final SettingsApiService? apiService;

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _ServicePricingGroup {
  const _ServicePricingGroup({required this.service, required this.items});

  final SettingsServiceModel service;
  final List<SettingsPricingModel> items;
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  late final SettingsApiService _apiService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';

  List<SettingsServiceModel> _activeServices = <SettingsServiceModel>[];
  List<SettingsPricingModel> _pricingList = <SettingsPricingModel>[];
  final Map<String, TextEditingController> _priceControllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _apiService =
        widget.apiService ??
        SettingsApiService(
          tokenStorage: AuthenticationDependencies.tokenStorage,
        );
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _apiService.getSummary();
      if (!mounted) return;

      final Set<String> activeItemIds = summary.items
          .where((i) => i.isActive)
          .map((i) => i.id)
          .toSet();
      final services = summary.services.where((s) => s.isActive).toList();
      final Set<String> activeServiceIds = services.map((s) => s.id).toSet();

      final Map<String, String> serviceNames = {
        for (final s in services) s.id: s.name,
      };
      final Map<String, String> itemNames = {
        for (final i in summary.items.where((i) => i.isActive)) i.id: i.name,
      };

      final activePricing = summary.pricing
          .where((p) {
            if (!p.isActive) return false;
            if (!activeItemIds.contains(p.itemCategoryId)) return false;
            if (!activeServiceIds.contains(p.serviceId)) return false;
            return true;
          })
          .map((p) {
            return p.copyWith(
              serviceName: serviceNames[p.serviceId] ?? 'Service',
              itemName: itemNames[p.itemCategoryId] ?? 'Item',
            );
          })
          .toList();

      for (final p in activePricing) {
        _priceControllers[p.id] = TextEditingController(
          text: p.basePrice.toStringAsFixed(
            p.basePrice.truncateToDouble() == p.basePrice ? 0 : 2,
          ),
        );
      }

      setState(() {
        _activeServices = services;
        _pricingList = activePricing;
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

  List<_ServicePricingGroup> get _groupedPricing {
    final query = _searchQuery.toLowerCase();
    final List<_ServicePricingGroup> groups = <_ServicePricingGroup>[];

    for (final service in _activeServices) {
      final List<SettingsPricingModel> servicePricings = _pricingList
          .where((p) => p.serviceId == service.id)
          .where((p) {
            if (query.isEmpty) return true;
            final itemName = p.itemName?.toLowerCase() ?? '';
            final serviceName = service.name.toLowerCase();
            return itemName.contains(query) || serviceName.contains(query);
          })
          .toList();

      if (servicePricings.isNotEmpty) {
        groups.add(
          _ServicePricingGroup(service: service, items: servicePricings),
        );
      }
    }

    return groups;
  }

  int get _totalFilteredItems =>
      _groupedPricing.fold(0, (sum, g) => sum + g.items.length);

  Future<void> _saveAllPricing() async {
    setState(() => _isSaving = true);

    int updatedCount = 0;
    try {
      for (final pricing in _pricingList) {
        final controller = _priceControllers[pricing.id];
        if (controller == null) continue;
        final double? newPrice = double.tryParse(controller.text.trim());
        if (newPrice != null &&
            newPrice >= 0 &&
            newPrice != pricing.basePrice) {
          await _apiService.updatePricing(pricing.id, basePrice: newPrice);
          updatedCount++;
        }
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      _showSnackBar(
        updatedCount > 0
            ? 'Updated $updatedCount price(s) successfully'
            : 'All prices are up to date',
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Failed to update pricing: $e', isError: true);
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
    final groups = _groupedPricing;

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
                        'Pricing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Set prices per item / service',
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
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search items or services...',
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

                    // Section: ACTIVE PRICING ENTRIES
                    Text(
                      'PRICING ENTRIES ($_totalFilteredItems)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (groups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No pricing configurations found.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...groups.map((group) => _buildServiceGroup(group)),
                  ],
                ),
              ),

            // Bottom Save Pricing Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAllPricing,
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
                          'Save Pricing',
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

  Widget _buildServiceGroup(_ServicePricingGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Service Group Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.service.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.items.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items in Service
          ...group.items.map((pricing) => _buildPricingItemCard(pricing)),
        ],
      ),
    );
  }

  Widget _buildPricingItemCard(SettingsPricingModel pricing) {
    final controller = _priceControllers[pricing.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            child: Text(
              pricing.itemName ?? 'Item',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: <Widget>[
                const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
