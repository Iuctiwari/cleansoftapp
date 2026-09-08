import 'package:flutter/foundation.dart';

@immutable
class SettingsServiceModel {
  const SettingsServiceModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.pricingType,
    required this.status,
    this.description,
    this.categoryId,
    this.estimatedTimeMins,
    this.branchIds = const <String>[],
    this.itemCategoryIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  factory SettingsServiceModel.fromJson(Map<String, dynamic> json) {
    return SettingsServiceModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      name: json['serviceName'] as String? ?? json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      pricingType: json['pricingType'] as String? ?? 'per_item',
      status: json['status'] as String? ?? 'Active',
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      estimatedTimeMins: json['estimatedTimeMins'] as int?,
      branchIds:
          (json['branchIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      itemCategoryIds:
          (json['itemCategoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String pricingType;
  final String status;
  final String? description;
  final String? categoryId;
  final int? estimatedTimeMins;
  final List<String> branchIds;
  final List<String> itemCategoryIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';

  SettingsServiceModel copyWith({
    String? name,
    String? pricingType,
    String? status,
    String? description,
    String? categoryId,
    int? estimatedTimeMins,
    List<String>? branchIds,
    List<String>? itemCategoryIds,
  }) {
    return SettingsServiceModel(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      code: code,
      pricingType: pricingType ?? this.pricingType,
      status: status ?? this.status,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      estimatedTimeMins: estimatedTimeMins ?? this.estimatedTimeMins,
      branchIds: branchIds ?? this.branchIds,
      itemCategoryIds: itemCategoryIds ?? this.itemCategoryIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class SettingsItemModel {
  const SettingsItemModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.unitType,
    required this.status,
    this.description,
    this.category,
    this.catalogGroupCodes = const <String>[],
    this.branchIds = const <String>[],
    this.serviceIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  factory SettingsItemModel.fromJson(Map<String, dynamic> json) {
    return SettingsItemModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      unitType: json['unitType'] as String? ?? 'piece',
      status: json['status'] as String? ?? 'Active',
      description: json['description'] as String?,
      category: json['category'] as String?,
      catalogGroupCodes:
          (json['catalogGroupCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      branchIds:
          (json['branchIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      serviceIds:
          (json['serviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String unitType;
  final String status;
  final String? description;
  final String? category;
  final List<String> catalogGroupCodes;
  final List<String> branchIds;
  final List<String> serviceIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';

  SettingsItemModel copyWith({
    String? name,
    String? unitType,
    String? status,
    String? description,
    String? category,
    List<String>? catalogGroupCodes,
    List<String>? branchIds,
    List<String>? serviceIds,
  }) {
    return SettingsItemModel(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      code: code,
      unitType: unitType ?? this.unitType,
      status: status ?? this.status,
      description: description ?? this.description,
      category: category ?? this.category,
      catalogGroupCodes: catalogGroupCodes ?? this.catalogGroupCodes,
      branchIds: branchIds ?? this.branchIds,
      serviceIds: serviceIds ?? this.serviceIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class SettingsCategoryModel {
  const SettingsCategoryModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.status,
    this.description,
    this.branchIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  factory SettingsCategoryModel.fromJson(Map<String, dynamic> json) {
    return SettingsCategoryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      description: json['description'] as String?,
      branchIds:
          (json['branchIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String status;
  final String? description;
  final List<String> branchIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';

  SettingsCategoryModel copyWith({
    String? name,
    String? status,
    String? description,
    List<String>? branchIds,
  }) {
    return SettingsCategoryModel(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      code: code,
      status: status ?? this.status,
      description: description ?? this.description,
      branchIds: branchIds ?? this.branchIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class SettingsPricingModel {
  const SettingsPricingModel({
    required this.id,
    required this.tenantId,
    required this.serviceId,
    required this.itemCategoryId,
    required this.pricingType,
    required this.basePrice,
    required this.taxPct,
    required this.status,
    this.branchId,
    this.effectiveFrom,
    this.effectiveTo,
    this.serviceName,
    this.itemName,
  });

  factory SettingsPricingModel.fromJson(Map<String, dynamic> json) {
    return SettingsPricingModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      itemCategoryId: json['itemCategoryId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      pricingType: json['pricingType'] as String? ?? 'per_item',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      taxPct: (json['taxPct'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Active',
      effectiveFrom: json['effectiveFrom'] != null
          ? DateTime.tryParse(json['effectiveFrom'].toString())
          : null,
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.tryParse(json['effectiveTo'].toString())
          : null,
      serviceName: json['serviceName'] as String?,
      itemName: json['itemName'] as String?,
    );
  }

  final String id;
  final String tenantId;
  final String serviceId;
  final String itemCategoryId;
  final String? branchId;
  final String pricingType;
  final double basePrice;
  final double taxPct;
  final String status;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? serviceName;
  final String? itemName;

  bool get isActive => status.toLowerCase() == 'active';

  SettingsPricingModel copyWith({
    double? basePrice,
    double? taxPct,
    String? status,
    String? branchId,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? serviceName,
    String? itemName,
  }) {
    return SettingsPricingModel(
      id: id,
      tenantId: tenantId,
      serviceId: serviceId,
      itemCategoryId: itemCategoryId,
      branchId: branchId ?? this.branchId,
      pricingType: pricingType,
      basePrice: basePrice ?? this.basePrice,
      taxPct: taxPct ?? this.taxPct,
      status: status ?? this.status,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      serviceName: serviceName ?? this.serviceName,
      itemName: itemName ?? this.itemName,
    );
  }
}

@immutable
class BusinessCatalogSummaryModel {
  const BusinessCatalogSummaryModel({
    required this.tenantId,
    required this.totalServices,
    required this.totalActiveServices,
    required this.totalItems,
    required this.totalActiveItems,
    required this.totalCategories,
    required this.totalActiveCategories,
    required this.totalActivePricing,
    required this.services,
    required this.items,
    required this.categories,
    required this.pricing,
  });

  factory BusinessCatalogSummaryModel.fromJson(Map<String, dynamic> json) {
    return BusinessCatalogSummaryModel(
      tenantId: json['tenantId'] as String? ?? '',
      totalServices: json['totalServices'] as int? ?? 0,
      totalActiveServices: json['totalActiveServices'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      totalActiveItems: json['totalActiveItems'] as int? ?? 0,
      totalCategories: json['totalCategories'] as int? ?? 0,
      totalActiveCategories: json['totalActiveCategories'] as int? ?? 0,
      totalActivePricing: json['totalActivePricing'] as int? ?? 0,
      services:
          (json['services'] as List<dynamic>?)
              ?.map(
                (e) => SettingsServiceModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <SettingsServiceModel>[],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => SettingsItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <SettingsItemModel>[],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SettingsCategoryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <SettingsCategoryModel>[],
      pricing:
          (json['pricing'] as List<dynamic>?)
              ?.map(
                (e) => SettingsPricingModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <SettingsPricingModel>[],
    );
  }

  final String tenantId;
  final int totalServices;
  final int totalActiveServices;
  final int totalItems;
  final int totalActiveItems;
  final int totalCategories;
  final int totalActiveCategories;
  final int totalActivePricing;
  final List<SettingsServiceModel> services;
  final List<SettingsItemModel> items;
  final List<SettingsCategoryModel> categories;
  final List<SettingsPricingModel> pricing;
}

@immutable
class TemplateServiceModel {
  const TemplateServiceModel({
    required this.code,
    required this.name,
    required this.pricingType,
    this.description,
  });

  factory TemplateServiceModel.fromJson(Map<String, dynamic> json) {
    return TemplateServiceModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? json['serviceName'] as String? ?? '',
      pricingType: json['pricingType'] as String? ?? 'per_item',
      description: json['description'] as String?,
    );
  }

  final String code;
  final String name;
  final String pricingType;
  final String? description;
}

@immutable
class SettingsCatalogTemplateModel {
  const SettingsCatalogTemplateModel({
    required this.code,
    required this.businessType,
    required this.name,
    this.services = const <TemplateServiceModel>[],
  });

  factory SettingsCatalogTemplateModel.fromJson(Map<String, dynamic> json) {
    return SettingsCatalogTemplateModel(
      code: json['code'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      services:
          (json['services'] as List<dynamic>?)
              ?.map(
                (e) => TemplateServiceModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <TemplateServiceModel>[],
    );
  }

  final String code;
  final String businessType;
  final String name;
  final List<TemplateServiceModel> services;
}
