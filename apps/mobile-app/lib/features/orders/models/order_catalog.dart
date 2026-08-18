enum CatalogPricingType {
  perItem('PerItem'),
  perKg('PerKg'),
  perPair('PerPair'),
  perHour('PerHour'),
  fixed('Fixed'),
  custom('Custom');

  const CatalogPricingType(this.apiValue);

  final String apiValue;

  static CatalogPricingType fromApi(String value) {
    for (final CatalogPricingType type in values) {
      if (type.apiValue == value) return type;
    }
    throw FormatException('Unknown catalog pricing type: $value.');
  }

  bool get usesWeight => this == CatalogPricingType.perKg;

  String get unitLabel => switch (this) {
    CatalogPricingType.perKg => 'kg',
    CatalogPricingType.perPair => 'pair',
    CatalogPricingType.perHour => 'hour',
    CatalogPricingType.fixed => 'service',
    CatalogPricingType.custom => 'unit',
    CatalogPricingType.perItem => 'item',
  };
}

enum CatalogUnitType {
  piece('Piece'),
  kg('Kg'),
  pair('Pair'),
  hour('Hour');

  const CatalogUnitType(this.apiValue);

  final String apiValue;

  static CatalogUnitType fromApi(String value) {
    for (final CatalogUnitType type in values) {
      if (type.apiValue == value) return type;
    }
    throw FormatException('Unknown catalog unit type: $value.');
  }

  String get label => switch (this) {
    CatalogUnitType.piece => 'piece',
    CatalogUnitType.kg => 'kg',
    CatalogUnitType.pair => 'pair',
    CatalogUnitType.hour => 'hour',
  };
}

class OrderItemCategory {
  const OrderItemCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.unitType,
    required this.branchIds,
    required this.serviceIds,
    required this.catalogGroupCodes,
    this.category,
  });

  factory OrderItemCategory.fromJson(Map<String, dynamic> json) =>
      OrderItemCategory(
        id: catalogRequiredText(json, 'id'),
        tenantId: catalogRequiredText(json, 'tenantId'),
        name: catalogRequiredText(json, 'name'),
        code: catalogRequiredText(json, 'code'),
        category: catalogOptionalText(json['category']),
        catalogGroupCodes: catalogStringList(json['catalogGroupCodes']),
        unitType: CatalogUnitType.fromApi(
          catalogRequiredText(json, 'unitType'),
        ),
        branchIds: catalogStringList(json['branchIds']),
        serviceIds: catalogStringList(json['serviceIds']),
      );

  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String? category;
  final List<String> catalogGroupCodes;
  final CatalogUnitType unitType;
  final List<String> branchIds;
  final List<String> serviceIds;
}

class OrderCatalogService {
  const OrderCatalogService({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.pricingType,
    required this.branchIds,
    required this.itemCategoryIds,
    required this.currentPricing,
  });

  factory OrderCatalogService.fromJson(Map<String, dynamic> json) =>
      OrderCatalogService(
        id: catalogRequiredText(json, 'id'),
        tenantId: catalogRequiredText(json, 'tenantId'),
        name:
            catalogOptionalText(json['serviceName']) ??
            catalogRequiredText(json, 'name'),
        code: catalogRequiredText(json, 'code'),
        pricingType: CatalogPricingType.fromApi(
          catalogRequiredText(json, 'pricingType'),
        ),
        branchIds: catalogStringList(json['branchIds']),
        itemCategoryIds: catalogStringList(json['itemCategoryIds']),
        currentPricing: catalogList(json['currentPricing'] ?? const <Object>[])
            .map((Object? item) => OrderCatalogPrice.fromJson(catalogMap(item)))
            .toList(growable: false),
      );

  final String id;
  final String tenantId;
  final String name;
  final String code;
  final CatalogPricingType pricingType;
  final List<String> branchIds;
  final List<String> itemCategoryIds;
  final List<OrderCatalogPrice> currentPricing;
}

class OrderCatalogPrice {
  const OrderCatalogPrice({
    required this.tenantId,
    required this.serviceId,
    required this.itemCategoryId,
    required this.pricingType,
    required this.basePrice,
    this.branchId,
  });

  factory OrderCatalogPrice.fromJson(Map<String, dynamic> json) =>
      OrderCatalogPrice(
        tenantId: catalogRequiredText(json, 'tenantId'),
        serviceId: catalogRequiredText(json, 'serviceId'),
        itemCategoryId: catalogRequiredText(json, 'itemCategoryId'),
        branchId: catalogOptionalText(json['branchId']),
        pricingType: CatalogPricingType.fromApi(
          catalogRequiredText(json, 'pricingType'),
        ),
        basePrice: catalogRequiredNumber(json, 'basePrice'),
      );

  final String tenantId;
  final String serviceId;
  final String itemCategoryId;
  final String? branchId;
  final CatalogPricingType pricingType;
  final double basePrice;
}

class OrderCatalogQuote {
  const OrderCatalogQuote({
    required this.serviceId,
    required this.itemCategoryId,
    required this.branchId,
    required this.pricingType,
    required this.unitPrice,
    required this.taxPercent,
    this.quantity,
    this.weight,
    this.lineAmount,
  });

  factory OrderCatalogQuote.fromJson(Map<String, dynamic> json) =>
      OrderCatalogQuote(
        serviceId: catalogRequiredText(json, 'serviceId'),
        itemCategoryId: catalogRequiredText(json, 'itemCategoryId'),
        branchId: catalogRequiredText(json, 'branchId'),
        pricingType: CatalogPricingType.fromApi(
          catalogRequiredText(json, 'pricingType'),
        ),
        unitPrice: catalogRequiredNumber(json, 'unitPrice'),
        taxPercent: catalogRequiredNumber(json, 'taxPct'),
        quantity: catalogNumber(json['quantity']),
        weight: catalogNumber(json['weight']),
        lineAmount:
            catalogNumber(json['lineAmount']) ??
            catalogNumber(json['subtotal']),
      );

  final String serviceId;
  final String itemCategoryId;
  final String branchId;
  final CatalogPricingType pricingType;
  final double unitPrice;
  final double taxPercent;
  final double? quantity;
  final double? weight;
  final double? lineAmount;

  double get baseAmount {
    if (lineAmount != null) return lineAmount!;
    final double units = weight ?? quantity ?? 1;
    return _money(units * unitPrice);
  }

  double get taxAmount => _money(baseAmount * taxPercent / 100);

  double get total => _money(baseAmount + taxAmount);
}

class CatalogPage<T> {
  const CatalogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;
}

Map<String, dynamic> catalogMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a catalog JSON object.');
}

List<Object?> catalogList(Object? value) {
  if (value is List) return value.cast<Object?>();
  throw const FormatException('Expected a catalog JSON list.');
}

List<String> catalogStringList(Object? value) {
  if (value == null) return const <String>[];
  return catalogList(value).map((Object? item) => item.toString()).toList();
}

String? catalogOptionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String catalogRequiredText(Map<String, dynamic> json, String key) {
  final String? value = catalogOptionalText(json[key]);
  if (value == null) throw FormatException('Missing catalog $key.');
  return value;
}

double? catalogNumber(Object? value) => value is num ? value.toDouble() : null;

double catalogRequiredNumber(Map<String, dynamic> json, String key) {
  final double? value = catalogNumber(json[key]);
  if (value == null) throw FormatException('Missing catalog $key.');
  return value;
}

int catalogRequiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! num) throw FormatException('Missing catalog $key.');
  return value.toInt();
}

double _money(double value) => (value * 100).round() / 100;
