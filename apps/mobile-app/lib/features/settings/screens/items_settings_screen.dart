import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/settings/models/settings_models.dart';
import 'package:nexoraa_mobile/features/settings/services/settings_api_service.dart';

class ItemsSettingsScreen extends StatefulWidget {
  const ItemsSettingsScreen({super.key, this.apiService});

  final SettingsApiService? apiService;

  @override
  State<ItemsSettingsScreen> createState() => _ItemsSettingsScreenState();
}

class _ItemsSettingsScreenState extends State<ItemsSettingsScreen> {
  late final SettingsApiService _apiService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';

  List<SettingsItemModel> _allItems = <SettingsItemModel>[];
  List<SettingsServiceModel> _services = <SettingsServiceModel>[];
  List<SettingsPricingModel> _pricing = <SettingsPricingModel>[];
  String? _selectedServiceId;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customItemNameController =
      TextEditingController();

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
    _searchController.dispose();
    _customItemNameController.dispose();
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

      setState(() {
        _allItems = List<SettingsItemModel>.from(summary.items);
        _services = List<SettingsServiceModel>.from(summary.services);
        _pricing = List<SettingsPricingModel>.from(summary.pricing);
        final activeServices = _services.where((s) => s.isActive).toList();
        if (activeServices.isNotEmpty) {
          if (_selectedServiceId == null ||
              !activeServices.any((s) => s.id == _selectedServiceId)) {
            _selectedServiceId = activeServices.first.id;
          }
        } else {
          _selectedServiceId = null;
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

  String _getItemServicesLabel(SettingsItemModel item) {
    final List<String> serviceNames = [];

    // 1. Resolve from item.serviceIds
    for (final sId in item.serviceIds) {
      final s = _services.cast<SettingsServiceModel?>().firstWhere(
        (s) => s != null && s.id == sId,
        orElse: () => null,
      );
      if (s != null && s.name.trim().isNotEmpty) {
        final name = s.name.trim();
        if (!serviceNames.contains(name)) {
          serviceNames.add(name);
        }
      }
    }

    // 2. Resolve from pricing associated with this item
    for (final p in _pricing) {
      if (p.itemCategoryId == item.id && p.isActive) {
        String? name = p.serviceName?.trim();
        if (name == null || name.isEmpty) {
          final s = _services.cast<SettingsServiceModel?>().firstWhere(
            (s) => s != null && s.id == p.serviceId,
            orElse: () => null,
          );
          name = s?.name.trim();
        }
        if (name != null && name.isNotEmpty && !serviceNames.contains(name)) {
          serviceNames.add(name);
        }
      }
    }

    // 3. Fallback to category string if available
    if (serviceNames.isEmpty &&
        item.category != null &&
        item.category!.trim().isNotEmpty) {
      final parts = item.category!
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty);
      for (final p in parts) {
        if (!serviceNames.contains(p)) {
          serviceNames.add(p);
        }
      }
    }

    if (serviceNames.isNotEmpty) {
      return serviceNames.join(', ');
    }

    return item.category?.trim().isNotEmpty == true
        ? item.category!.trim()
        : 'General';
  }

  List<SettingsItemModel> get _activeItems {
    final seen = <String>{};
    final List<SettingsItemModel> unique = [];

    for (final item in _allItems) {
      if (!item.isActive) continue;
      final key = item.code.isNotEmpty
          ? item.code.toUpperCase().trim()
          : item.name.toLowerCase().trim();
      if (seen.contains(key)) continue;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final servicesLabel = _getItemServicesLabel(item).toLowerCase();
        final matches =
            item.name.toLowerCase().contains(query) ||
            servicesLabel.contains(query) ||
            (item.category?.toLowerCase().contains(query) ?? false);
        if (!matches) continue;
      }
      seen.add(key);
      unique.add(item);
    }
    return unique;
  }

  List<SettingsItemModel> get _inactiveItems {
    final seen = <String>{};
    final List<SettingsItemModel> unique = [];

    for (final item in _allItems) {
      if (item.isActive) continue;
      final key = item.code.isNotEmpty
          ? item.code.toUpperCase().trim()
          : item.name.toLowerCase().trim();
      if (seen.contains(key)) continue;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final servicesLabel = _getItemServicesLabel(item).toLowerCase();
        final matches =
            item.name.toLowerCase().contains(query) ||
            servicesLabel.contains(query) ||
            (item.category?.toLowerCase().contains(query) ?? false);
        if (!matches) continue;
      }
      seen.add(key);
      unique.add(item);
    }
    return unique;
  }

  Future<void> _removeItem(SettingsItemModel item) async {
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _allItems[index] = item.copyWith(status: 'Inactive');
      }
    });

    try {
      await _apiService.updateItem(item.id, status: 'Inactive');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to remove item: $e', isError: true);
      _loadData();
    }
  }

  Future<void> _addItem(SettingsItemModel item) async {
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _allItems[index] = item.copyWith(status: 'Active');
      }
    });

    try {
      await _apiService.updateItem(item.id, status: 'Active');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to add item: $e', isError: true);
      _loadData();
    }
  }

  Future<void> _addCustomItem() async {
    final String name = _customItemNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter an item name', isError: true);
      return;
    }

    final String code = name.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '_',
    );
    final List<SettingsServiceModel> activeServices = _services
        .where((s) => s.isActive)
        .toList();
    final SettingsServiceModel? selectedService = activeServices
        .cast<SettingsServiceModel?>()
        .firstWhere(
          (s) => s?.id == _selectedServiceId,
          orElse: () => activeServices.isNotEmpty ? activeServices.first : null,
        );
    final String category = selectedService?.name ?? 'General';
    final List<String>? serviceIds = selectedService != null
        ? <String>[selectedService.id]
        : null;

    setState(() => _isSaving = true);

    try {
      final newItem = await _apiService.createItem(
        name: name,
        code: code,
        unitType: 'Piece',
        category: category,
        serviceIds: serviceIds,
        status: 'Active',
      );

      _customItemNameController.clear();

      if (!mounted) return;
      setState(() {
        final existingIndex = _allItems.indexWhere(
          (i) =>
              i.id == newItem.id ||
              i.code.toUpperCase() == newItem.code.toUpperCase(),
        );
        if (existingIndex != -1) {
          final existing = _allItems[existingIndex];
          final List<String> combined = [
            ...existing.serviceIds,
            ...newItem.serviceIds,
            if (selectedService != null) selectedService.id,
          ];
          final uniqueServiceIds = combined.toSet().toList();
          _allItems[existingIndex] = existing.copyWith(
            status: 'Active',
            serviceIds: uniqueServiceIds,
          );
        } else {
          _allItems.add(newItem);
        }
        _isSaving = false;
      });

      _showSnackBar('Item "$name" added to catalog');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Failed to add item: $e', isError: true);
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
                        'Items / Catalog',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your item catalog',
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
                          hintText: 'Search items...',
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

                    // Section: CATALOG ITEMS (count)
                    Text(
                      'CATALOG ITEMS (${_activeItems.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_activeItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No active items found. Add items from below.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._activeItems.map((item) => _buildActiveItemCard(item)),

                    const SizedBox(height: 20),

                    // Section: AVAILABLE TO ADD
                    if (_inactiveItems.isNotEmpty) ...<Widget>[
                      const Text(
                        'AVAILABLE TO ADD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._inactiveItems.map(
                        (item) => _buildAvailableItemCard(item),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section: ADD CUSTOM ITEM
                    _buildAddCustomItemCard(),
                  ],
                ),
              ),

            // Bottom Save Catalog Button
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
                            'Catalog configuration saved successfully',
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
                          'Save Catalog',
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

  Widget _buildActiveItemCard(SettingsItemModel item) {
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
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getItemServicesLabel(item),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _removeItem(item),
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

  Widget _buildAvailableItemCard(SettingsItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getItemServicesLabel(item),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _addItem(item),
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

  Widget _buildCategorySelector(List<SettingsServiceModel> activeServices) {
    final SettingsServiceModel? currentService = activeServices
        .cast<SettingsServiceModel?>()
        .firstWhere(
          (s) => s?.id == _selectedServiceId,
          orElse: () => activeServices.isNotEmpty ? activeServices.first : null,
        );
    final String label = currentService?.name ?? 'Select Service';

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
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: currentService != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
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
                          itemCount: activeServices.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final service = activeServices[index];
                            final isSelected = service.id == _selectedServiceId;
                            return Material(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedServiceId = service.id;
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
                                          service.name,
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

  Widget _buildAddCustomItemCard() {
    final List<SettingsServiceModel> activeServices = _services
        .where((s) => s.isActive)
        .toList();

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
            'ADD CUSTOM ITEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _customItemNameController,
              decoration: const InputDecoration(
                hintText: 'Item name...',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildCategorySelector(activeServices)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isSaving || activeServices.isEmpty
                    ? null
                    : _addCustomItem,
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
