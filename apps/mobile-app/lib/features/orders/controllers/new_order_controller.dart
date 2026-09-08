import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/models/order_catalog.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';

class NewOrderLineSelection {
  const NewOrderLineSelection({
    required this.category,
    required this.amount,
    this.services = const <String, OrderCatalogService>{},
    this.quotes = const <String, OrderCatalogQuote>{},
  });

  final OrderItemCategory category;
  final double amount;
  final Map<String, OrderCatalogService> services;
  final Map<String, OrderCatalogQuote> quotes;

  bool hasService(String serviceId) => services.containsKey(serviceId);
  OrderCatalogQuote? quoteFor(String serviceId) => quotes[serviceId];

  NewOrderLineSelection copyWith({
    double? amount,
    Map<String, OrderCatalogService>? services,
    Map<String, OrderCatalogQuote>? quotes,
    bool clearService = false,
  }) => NewOrderLineSelection(
    category: category,
    amount: amount ?? this.amount,
    services: clearService
        ? const <String, OrderCatalogService>{}
        : Map<String, OrderCatalogService>.unmodifiable(
            services ?? this.services,
          ),
    quotes: clearService
        ? const <String, OrderCatalogQuote>{}
        : Map<String, OrderCatalogQuote>.unmodifiable(quotes ?? this.quotes),
  );
}

class NewOrderItemGroup {
  const NewOrderItemGroup({
    required this.code,
    required this.label,
    required this.items,
  });

  final String code;
  final String label;
  final List<OrderItemCategory> items;
}

class NewOrderController extends ChangeNotifier {
  static const double additionalServiceSurcharge = 10;

  NewOrderController({
    required OrderCatalogApiService catalogService,
    required OrderController orderController,
    required PaymentApiService paymentService,
    required String branchId,
  }) : _catalogService = catalogService,
       _branchId = branchId,
       _paymentService = paymentService,
       _orderController = orderController {
    _catalogService.selectBranch(branchId);
    _paymentService.selectBranch(branchId);
  }

  final OrderCatalogApiService _catalogService;
  final String _branchId;
  final OrderController _orderController;
  final PaymentApiService _paymentService;
  final Map<String, NewOrderLineSelection> _selections =
      <String, NewOrderLineSelection>{};
  List<OrderItemCategory> _categories = const <OrderItemCategory>[];
  List<OrderCatalogService> _services = const <OrderCatalogService>[];
  Customer? _customer;
  Order? _createdOrder;
  int _step = 0;
  double _discountPercentage = 0;
  double _advancePayment = 0;
  PaymentMethod? _paymentMethod;
  String? _paymentIdempotencyKey;
  bool _loadingCatalog = false;
  bool _quoting = false;
  bool _saving = false;
  String? _error;

  int get step => _step;
  Customer? get customer => _customer;
  Order? get createdOrder => _createdOrder;
  List<OrderItemCategory> get categories => _categories;
  List<OrderItemCategory> get uniqueItems {
    final Map<String, OrderItemCategory> unique = <String, OrderItemCategory>{};
    for (final OrderItemCategory item in _categories) {
      final String key = item.code.trim().isNotEmpty
          ? item.code.trim().toLowerCase()
          : item.id;
      unique.putIfAbsent(key, () => item);
    }
    final List<OrderItemCategory> result = unique.values.toList()
      ..sort(_compareItemCategories);
    return List<OrderItemCategory>.unmodifiable(result);
  }

  List<NewOrderItemGroup> get itemGroups {
    final Map<String, List<OrderItemCategory>> grouped =
        <String, List<OrderItemCategory>>{};
    for (final OrderItemCategory item in _categories) {
      final List<String> codes = item.catalogGroupCodes.isNotEmpty
          ? item.catalogGroupCodes
          : <String>[item.category ?? 'OTHER'];
      for (final String code in codes) {
        grouped.putIfAbsent(code, () => <OrderItemCategory>[]).add(item);
      }
    }
    final List<NewOrderItemGroup> result = grouped.entries
        .map((entry) {
          final List<OrderItemCategory> items = <OrderItemCategory>[
            ...entry.value,
          ]..sort(_compareItemCategories);
          return NewOrderItemGroup(
            code: entry.key,
            label: _catalogGroupLabel(entry.key),
            items: List<OrderItemCategory>.unmodifiable(items),
          );
        })
        .toList(growable: false);
    result.sort((first, second) {
      final int byLabel = first.label.toLowerCase().compareTo(
        second.label.toLowerCase(),
      );
      return byLabel != 0 ? byLabel : first.code.compareTo(second.code);
    });
    return result;
  }

  List<OrderCatalogService> get services => _services;
  List<NewOrderLineSelection> get selections => _categories
      .where(
        (OrderItemCategory category) => _selections.containsKey(category.id),
      )
      .map((OrderItemCategory category) => _selections[category.id]!)
      .toList(growable: false);
  bool get isLoadingCatalog => _loadingCatalog;
  bool get isQuoting => _quoting;
  bool get isSaving => _saving;
  String? get error => _error;
  double get discountPercentage => _discountPercentage;
  double get discountAmount =>
      _money(previewBaseSubtotal * (_discountPercentage / 100));
  double get previewBaseSubtotal => _money(
    selections.fold<double>(
      0,
      (double total, NewOrderLineSelection line) =>
          total +
          line.services.keys.fold<double>(
            0,
            (double lineTotal, String serviceId) =>
                lineTotal + serviceBaseAmount(line, serviceId),
          ),
    ),
  );
  double get previewTax {
    final double undiscountedTax = selections.fold<double>(
      0,
      (double total, NewOrderLineSelection line) =>
          total +
          line.services.keys.fold<double>(
            0,
            (double lineTotal, String serviceId) =>
                lineTotal + serviceTaxAmount(line, serviceId),
          ),
    );
    if (previewBaseSubtotal == 0) return 0;
    return _money(
      undiscountedTax *
          ((previewBaseSubtotal - discountAmount) / previewBaseSubtotal),
    );
  }

  double get previewTaxableAmount =>
      _money(previewBaseSubtotal - discountAmount);
  double get previewGrandTotal => _money(previewTaxableAmount + previewTax);
  double get advancePayment => _advancePayment;
  double get previewOutstanding => _money(previewGrandTotal - _advancePayment);
  PaymentMethod? get paymentMethod => _paymentMethod;

  Future<void> loadCatalog() async {
    if (_loadingCatalog) return;
    _loadingCatalog = true;
    _error = null;
    notifyListeners();
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _catalogService.allItemCategories(),
        _catalogService.allServices(),
      ]);
      _categories =
          (results[0] as List<OrderItemCategory>)
              .where(
                (OrderItemCategory category) =>
                    category.branchIds.isEmpty ||
                    category.branchIds.contains(_branchId),
              )
              .toList(growable: false)
            ..sort(_compareItemCategories);
      _services = (results[1] as List<OrderCatalogService>)
          .where(
            (OrderCatalogService service) =>
                service.branchIds.isEmpty ||
                service.branchIds.contains(_branchId),
          )
          .toList(growable: false);
    } on OrderCatalogApiException catch (error) {
      _error = error.message;
      _categories = const <OrderItemCategory>[];
      _services = const <OrderCatalogService>[];
    } finally {
      _loadingCatalog = false;
      notifyListeners();
    }
  }

  void selectCustomer(Customer customer) {
    _customer = customer;
    _error = null;
    notifyListeners();
  }

  NewOrderLineSelection? selectionFor(String categoryId) =>
      _selections[categoryId];

  bool isBaseService(NewOrderLineSelection line, String serviceId) =>
      line.services.keys.firstOrNull == serviceId;

  double serviceUnitPrice(NewOrderLineSelection line, String serviceId) {
    final OrderCatalogQuote? quote = line.quoteFor(serviceId);
    if (quote == null) return 0;
    return isBaseService(line, serviceId)
        ? quote.unitPrice
        : additionalServiceSurcharge;
  }

  double serviceBaseAmount(NewOrderLineSelection line, String serviceId) {
    final OrderCatalogQuote? quote = line.quoteFor(serviceId);
    if (quote == null) return 0;
    if (isBaseService(line, serviceId)) return quote.baseAmount;
    final double units = quote.weight ?? quote.quantity ?? 1;
    return _money(units * additionalServiceSurcharge);
  }

  double serviceTaxAmount(NewOrderLineSelection line, String serviceId) {
    final OrderCatalogQuote? quote = line.quoteFor(serviceId);
    if (quote == null) return 0;
    return _money(serviceBaseAmount(line, serviceId) * quote.taxPercent / 100);
  }

  double serviceTotal(NewOrderLineSelection line, String serviceId) => _money(
    serviceBaseAmount(line, serviceId) + serviceTaxAmount(line, serviceId),
  );

  void changeAmount(OrderItemCategory category, double amount) {
    final double normalized = _measurement(category, amount);
    if (normalized <= 0) {
      _selections.remove(category.id);
    } else {
      final NewOrderLineSelection? existing = _selections[category.id];
      _selections[category.id] = existing == null
          ? NewOrderLineSelection(category: category, amount: normalized)
          : existing.copyWith(amount: normalized, clearService: true);
    }
    _error = null;
    notifyListeners();
  }

  List<OrderCatalogService> servicesFor(OrderItemCategory category) => _services
      .where(
        (OrderCatalogService service) =>
            service.tenantId == category.tenantId &&
            (category.serviceIds.contains(service.id) ||
                service.itemCategoryIds.contains(category.id)),
      )
      .toList(growable: false);

  List<OrderCatalogPrice> pricesFor(OrderItemCategory category) =>
      servicesFor(category)
          .expand((OrderCatalogService service) => service.currentPricing)
          .where(
            (OrderCatalogPrice price) =>
                price.tenantId == category.tenantId &&
                price.itemCategoryId == category.id &&
                (price.branchId == null || price.branchId == _branchId),
          )
          .toList(growable: false);

  Future<bool> toggleService(
    NewOrderLineSelection line,
    OrderCatalogService service,
  ) async {
    if (line.hasService(service.id)) {
      final Map<String, OrderCatalogService> services =
          Map<String, OrderCatalogService>.of(line.services)
            ..remove(service.id);
      final Map<String, OrderCatalogQuote> quotes =
          Map<String, OrderCatalogQuote>.of(line.quotes)..remove(service.id);
      _selections[line.category.id] = line.copyWith(
        services: services,
        quotes: quotes,
      );
      _error = null;
      notifyListeners();
      return true;
    }
    _quoting = true;
    _error = null;
    notifyListeners();
    try {
      final ({double? quantity, double? weight}) measurement =
          _quoteMeasurement(line, service.pricingType);
      final OrderCatalogQuote quote = await _catalogService.quote(
        serviceId: service.id,
        itemCategoryId: line.category.id,
        quantity: measurement.quantity,
        weight: measurement.weight,
      );
      _selections[line.category.id] = line.copyWith(
        services: <String, OrderCatalogService>{
          ...line.services,
          service.id: service,
        },
        quotes: <String, OrderCatalogQuote>{...line.quotes, service.id: quote},
      );
      return true;
    } on OrderCatalogApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _quoting = false;
      notifyListeners();
    }
  }

  void setDiscount(String value) {
    final double parsed = double.tryParse(value.trim()) ?? 0;
    _discountPercentage = parsed.isFinite && parsed >= 0 ? _money(parsed) : 0;
    _error = null;
    notifyListeners();
  }

  void setAdvancePayment(String value) {
    final double parsed = double.tryParse(value.trim()) ?? 0;
    _advancePayment = parsed.isFinite ? _money(parsed) : 0;
    _error = null;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    _error = null;
    notifyListeners();
  }

  String? nextValidation() {
    if (_step == 0 && _customer == null)
      return 'Select a customer to continue.';
    if (_step == 1 && selections.isEmpty) {
      return 'Add at least one item to continue.';
    }
    if (_step == 2 &&
        selections.any(
          (NewOrderLineSelection line) =>
              line.services.isEmpty ||
              line.quotes.length != line.services.length,
        )) {
      return 'Select at least one available service for every item.';
    }
    if (_step == 3 && (_discountPercentage < 0 || _discountPercentage > 100)) {
      return 'Discount percentage must be between 0 and 100.';
    }
    if (_step == 4 &&
        (_advancePayment < 0 || _advancePayment > previewGrandTotal)) {
      return 'Advance payment must be between Rs. 0 and the grand total.';
    }
    if (_step == 4 && _advancePayment > 0 && _paymentMethod == null) {
      return 'Select a payment method for the advance payment.';
    }
    return null;
  }

  bool next() {
    final String? validation = nextValidation();
    if (validation != null) {
      _error = validation;
      notifyListeners();
      return false;
    }
    if (_step < 4) _step += 1;
    _error = null;
    notifyListeners();
    return true;
  }

  void back() {
    if (_step > 0 && _step < 5) {
      _step -= 1;
      _error = null;
      notifyListeners();
    }
  }

  Future<Order?> save() async {
    if (_saving || _customer == null) return null;
    final String? validation = nextValidation();
    if (validation != null) {
      _error = validation;
      notifyListeners();
      return null;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      Order order =
          _createdOrder ??
          await _orderController.create(
            CreateOrderInput(
              customerId: _customer!.id,
              discountPercentage: _discountPercentage,
              items: selections.expand(_createItems).toList(growable: false),
            ),
          );
      _createdOrder = order;
      if (_advancePayment > 0 && order.paidAmount < _advancePayment) {
        _paymentIdempotencyKey ??=
            'advance-${order.id}-${DateTime.now().microsecondsSinceEpoch}';
        order = await _paymentService.createAdvance(
          idempotencyKey: _paymentIdempotencyKey!,
          orderId: order.id,
          customerId: order.customerId,
          amount: _advancePayment,
          method: _paymentMethod!,
        );
        _createdOrder = order;
      }
      _step = 5;
      return order;
    } on OrderApiException catch (error) {
      _error = error.message;
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Iterable<CreateOrderItemInput> _createItems(NewOrderLineSelection line) =>
      line.services.values.map((OrderCatalogService service) {
        final ({double? quantity, double? weight}) measurement =
            _quoteMeasurement(line, service.pricingType);
        return CreateOrderItemInput(
          itemCategoryId: line.category.id,
          serviceId: service.id,
          quantity: measurement.quantity,
          weight: measurement.weight,
        );
      });

  ({double? quantity, double? weight}) _quoteMeasurement(
    NewOrderLineSelection line,
    CatalogPricingType pricingType,
  ) {
    if (pricingType == CatalogPricingType.fixed) {
      return (quantity: 1, weight: null);
    }
    if (pricingType == CatalogPricingType.perKg ||
        (pricingType == CatalogPricingType.custom &&
            line.category.unitType == CatalogUnitType.kg)) {
      return (quantity: null, weight: line.amount);
    }
    return (quantity: line.amount, weight: null);
  }

  double _measurement(OrderItemCategory category, double value) {
    if (!value.isFinite) return 0;
    final double nonNegative = value.clamp(0, 999999).toDouble();
    return category.unitType == CatalogUnitType.kg
        ? (nonNegative * 1000).round() / 1000
        : nonNegative.roundToDouble();
  }

  double _money(double value) => (value * 100).round() / 100;

  static int _compareItemCategories(
    OrderItemCategory first,
    OrderItemCategory second,
  ) {
    final int byName = first.name.toLowerCase().compareTo(
      second.name.toLowerCase(),
    );
    if (byName != 0) return byName;
    final int byCode = first.code.compareTo(second.code);
    return byCode != 0 ? byCode : first.id.compareTo(second.id);
  }

  static String _catalogGroupLabel(String code) => code
      .trim()
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part.substring(0, 1).toUpperCase()}'
            '${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
