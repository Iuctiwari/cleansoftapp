/// Data for the customer (marketplace) side of the app.
library;

/// A signed-in customer. Kept apart from the shop [AuthenticationSession] so
/// the two kinds of login can never be mixed up.
class ConsumerSession {
  const ConsumerSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.consumerId,
    required this.displayName,
    required this.email,
    required this.mobileNumber,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final String consumerId;
  final String displayName;
  final String email;
  final String mobileNumber;

  Map<String, String> toStorage() => <String, String>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
    'consumerId': consumerId,
    'displayName': displayName,
    'email': email,
    'mobileNumber': mobileNumber,
  };

  static ConsumerSession? fromStorage(Map<String, dynamic> json) {
    try {
      return ConsumerSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
        refreshTokenExpiresAt: DateTime.parse(json['refreshTokenExpiresAt'] as String),
        consumerId: json['consumerId'] as String,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }

  ConsumerSession withTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
  }) => ConsumerSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: accessTokenExpiresAt,
    refreshTokenExpiresAt: refreshTokenExpiresAt,
    consumerId: consumerId,
    displayName: displayName,
    email: email,
    mobileNumber: mobileNumber,
  );
}

/// The shop categories, in the order shown as filter chips.
enum ShopCategory {
  laundry('laundry'),
  dryCleaning('dry_cleaning'),
  tailoring('tailoring'),
  shoeCleaning('shoe_cleaning'),
  applianceRepair('appliance_repair'),
  mobileRepair('mobile_repair'),
  vehicleWash('vehicle_wash'),
  salon('salon'),
  general('general'),
  custom('custom');

  const ShopCategory(this.code);
  final String code;

  static ShopCategory? fromCode(String? code) {
    for (final ShopCategory value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// How a shop serves customers.
enum ServiceMode {
  visitShop('visit_shop'),
  homeService('home_service'),
  pickupDrop('pickup_drop');

  const ServiceMode(this.code);
  final String code;

  /// Home service and pickup need the customer's address.
  bool get needsAddress => this != ServiceMode.visitShop;

  static ServiceMode? fromCode(String? code) {
    for (final ServiceMode value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

enum AddressLabel {
  home('Home'),
  work('Work'),
  other('Other');

  const AddressLabel(this.code);
  final String code;

  static AddressLabel fromCode(String? code) =>
      values.firstWhere((AddressLabel v) => v.code == code, orElse: () => AddressLabel.other);
}

class ConsumerAddress {
  const ConsumerAddress({
    required this.addressId,
    required this.label,
    required this.contactName,
    required this.contactPhone,
    required this.houseFlat,
    required this.streetArea,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.formatted,
    this.landmark,
  });

  factory ConsumerAddress.fromJson(Map<String, dynamic> json) => ConsumerAddress(
    addressId: json['addressId'] as String,
    label: AddressLabel.fromCode(json['label'] as String?),
    contactName: json['contactName'] as String? ?? '',
    contactPhone: json['contactPhone'] as String? ?? '',
    houseFlat: json['houseFlat'] as String? ?? '',
    streetArea: json['streetArea'] as String? ?? '',
    landmark: json['landmark'] as String?,
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    pincode: json['pincode'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    isDefault: json['isDefault'] as bool? ?? false,
    formatted: json['formatted'] as String? ?? '',
  );

  final String addressId;
  final AddressLabel label;
  final String contactName;
  final String contactPhone;
  final String houseFlat;
  final String streetArea;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String formatted;
}

/// What the address form sends; [toJson] matches the API's field names.
class AddressDraft {
  const AddressDraft({
    required this.label,
    required this.houseFlat,
    required this.streetArea,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.landmark,
    this.contactName,
    this.contactPhone,
    this.isDefault = false,
  });

  final AddressLabel label;
  final String houseFlat;
  final String streetArea;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? contactName;
  final String? contactPhone;
  final bool isDefault;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label.code,
    'houseFlat': houseFlat.trim(),
    'streetArea': streetArea.trim(),
    'landmark': landmark?.trim() ?? '',
    'city': city.trim(),
    'state': state.trim(),
    'pincode': pincode.trim(),
    'latitude': latitude,
    'longitude': longitude,
    if (contactName != null && contactName!.trim().isNotEmpty) 'contactName': contactName!.trim(),
    if (contactPhone != null && contactPhone!.trim().isNotEmpty) 'contactPhone': contactPhone!.trim(),
    if (isDefault) 'isDefault': true,
  };
}

class OpeningHoursDay {
  const OpeningHoursDay({required this.day, required this.closed, this.open, this.close});

  factory OpeningHoursDay.fromJson(Map<String, dynamic> json) => OpeningHoursDay(
    day: (json['day'] as num).toInt(),
    closed: json['closed'] as bool? ?? false,
    open: json['open'] as String?,
    close: json['close'] as String?,
  );

  /// 0 = Sunday … 6 = Saturday
  final int day;
  final bool closed;
  final String? open;
  final String? close;
}

/// One row of the "shops near me" list.
class ShopSummary {
  const ShopSummary({
    required this.shopId,
    required this.shopName,
    required this.branchName,
    required this.categories,
    required this.distanceKm,
    required this.city,
    required this.addressLine,
    required this.phone,
    required this.serviceModes,
    required this.servesYourLocation,
    required this.isOpenNow,
    required this.latitude,
    required this.longitude,
    this.area,
    this.todayHours,
  });

  factory ShopSummary.fromJson(Map<String, dynamic> json) => ShopSummary(
    shopId: json['shopId'] as String,
    shopName: json['shopName'] as String? ?? '',
    branchName: json['branchName'] as String? ?? '',
    categories: _categories(json['categories']),
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    area: json['area'] as String?,
    city: json['city'] as String? ?? '',
    addressLine: json['addressLine'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    serviceModes: _modes(json['serviceModes']),
    servesYourLocation: json['servesYourLocation'] as bool? ?? false,
    isOpenNow: json['isOpenNow'] as bool? ?? false,
    todayHours: json['todayHours'] is Map<String, dynamic>
        ? OpeningHoursDay.fromJson(json['todayHours'] as Map<String, dynamic>)
        : null,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );

  final String shopId;
  final String shopName;
  final String branchName;
  final List<ShopCategory> categories;
  final double distanceKm;
  final String? area;
  final String city;
  final String addressLine;
  final String phone;
  final List<ServiceMode> serviceModes;
  final bool servesYourLocation;
  final bool isOpenNow;
  final OpeningHoursDay? todayHours;
  final double latitude;
  final double longitude;
}

class ShopDetail extends ShopSummary {
  const ShopDetail({
    required super.shopId,
    required super.shopName,
    required super.branchName,
    required super.categories,
    required super.distanceKm,
    required super.city,
    required super.addressLine,
    required super.phone,
    required super.serviceModes,
    required super.servesYourLocation,
    required super.isOpenNow,
    required super.latitude,
    required super.longitude,
    required this.openingHours,
    required this.serviceRadiusKm,
    required this.directionsUrl,
    required this.streetAddress,
    required this.state,
    required this.postalCode,
    super.area,
    super.todayHours,
    this.landmark,
    this.about,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    final ShopSummary summary = ShopSummary.fromJson(json);
    final Map<String, dynamic> address = json['address'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ShopDetail(
      shopId: summary.shopId,
      shopName: summary.shopName,
      branchName: summary.branchName,
      categories: summary.categories,
      distanceKm: summary.distanceKm,
      area: summary.area,
      city: summary.city,
      addressLine: summary.addressLine,
      phone: summary.phone,
      serviceModes: summary.serviceModes,
      servesYourLocation: summary.servesYourLocation,
      isOpenNow: summary.isOpenNow,
      todayHours: summary.todayHours,
      latitude: summary.latitude,
      longitude: summary.longitude,
      openingHours: (json['openingHours'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OpeningHoursDay.fromJson)
          .toList(growable: false),
      serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toInt() ?? 0,
      about: json['about'] as String?,
      directionsUrl: json['directionsUrl'] as String? ?? '',
      streetAddress: address['streetAddress'] as String? ?? '',
      landmark: address['landmark'] as String?,
      state: address['state'] as String? ?? '',
      postalCode: address['postalCode'] as String? ?? '',
    );
  }

  final List<OpeningHoursDay> openingHours;
  final int serviceRadiusKm;
  final String? about;
  final String directionsUrl;
  final String streetAddress;
  final String? landmark;
  final String state;
  final String postalCode;

  OpeningHoursDay? hoursFor(int weekday) {
    for (final OpeningHoursDay day in openingHours) {
      if (day.day == weekday) return day;
    }
    return null;
  }
}

class ShopSearchPage {
  const ShopSearchPage({
    required this.items,
    required this.page,
    required this.total,
    required this.radiusKm,
    this.originAddressId,
  });

  factory ShopSearchPage.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> origin = json['origin'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ShopSearchPage(
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ShopSummary.fromJson)
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      radiusKm: (json['radiusKm'] as num?)?.toInt() ?? 10,
      originAddressId: origin['addressId'] as String?,
    );
  }

  final List<ShopSummary> items;
  final int page;
  final int total;
  final int radiusKm;
  final String? originAddressId;
}

/// Filters for the shop list. Search starts from [addressId], or from
/// [latitude]/[longitude] when the customer chose "current location".
class ShopSearchFilters {
  const ShopSearchFilters({
    this.addressId,
    this.latitude,
    this.longitude,
    this.category,
    this.mode,
    this.openNow = false,
    this.radiusKm = 10,
    this.query = '',
  });

  final String? addressId;
  final double? latitude;
  final double? longitude;
  final ShopCategory? category;
  final ServiceMode? mode;
  final bool openNow;
  final int radiusKm;
  final String query;

  bool get usesCurrentLocation => latitude != null && longitude != null;

  ShopSearchFilters copyWith({
    String? addressId,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    ShopCategory? category,
    bool clearCategory = false,
    ServiceMode? mode,
    bool clearMode = false,
    bool? openNow,
    int? radiusKm,
    String? query,
  }) => ShopSearchFilters(
    addressId: clearLocation ? addressId : (addressId ?? this.addressId),
    latitude: clearLocation ? latitude : (latitude ?? this.latitude),
    longitude: clearLocation ? longitude : (longitude ?? this.longitude),
    category: clearCategory ? null : (category ?? this.category),
    mode: clearMode ? null : (mode ?? this.mode),
    openNow: openNow ?? this.openNow,
    radiusKm: radiusKm ?? this.radiusKm,
    query: query ?? this.query,
  );

  Map<String, String> toQuery({int page = 1, int limit = 20}) => <String, String>{
    if (usesCurrentLocation) ...<String, String>{
      'latitude': '$latitude',
      'longitude': '$longitude',
    } else if (addressId != null)
      'addressId': addressId!,
    if (category != null) 'category': category!.code,
    if (mode != null) 'mode': mode!.code,
    if (openNow) 'openNow': 'true',
    'radiusKm': '$radiusKm',
    if (query.trim().isNotEmpty) 'q': query.trim(),
    'page': '$page',
    'limit': '$limit',
  };
}

enum RequestStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  cancelled('Cancelled'),
  expired('Expired'),
  completed('Completed');

  const RequestStatus(this.code);
  final String code;

  static RequestStatus fromCode(String? code) =>
      values.firstWhere((RequestStatus v) => v.code == code, orElse: () => RequestStatus.pending);
}

class RequestItem {
  const RequestItem({required this.name, required this.quantity});

  factory RequestItem.fromJson(Map<String, dynamic> json) =>
      RequestItem(name: json['name'] as String? ?? '', quantity: (json['quantity'] as num?)?.toInt() ?? 1);

  final String name;
  final int quantity;

  Map<String, Object> toJson() => <String, Object>{'name': name.trim(), 'quantity': quantity};
}

class RequestHistoryEntry {
  const RequestHistoryEntry({required this.status, required this.at, required this.by, this.note});

  factory RequestHistoryEntry.fromJson(Map<String, dynamic> json) => RequestHistoryEntry(
    status: RequestStatus.fromCode(json['status'] as String?),
    at: DateTime.parse(json['at'] as String).toLocal(),
    by: json['by'] as String? ?? 'system',
    note: json['note'] as String?,
  );

  final RequestStatus status;
  final DateTime at;

  /// customer, shop or system
  final String by;
  final String? note;
}

/// A request as the customer sees it.
class ServiceRequest {
  const ServiceRequest({
    required this.requestId,
    required this.requestNumber,
    required this.shopId,
    required this.shopName,
    required this.branchName,
    required this.shopPhone,
    required this.category,
    required this.requestType,
    required this.description,
    required this.items,
    required this.preferredDate,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    required this.canCancel,
    required this.history,
    required this.createdAt,
    this.addressLabel,
    this.addressFormatted,
    this.confirmedAt,
    this.shopNote,
    this.declineReason,
    this.cancelReason,
    this.orderNumber,
    this.expiresAt,
    this.pickupWorkerName,
    this.collectedAt,
    this.collectedItems = const <RequestItem>[],
    this.deliveryDate,
    this.deliveryDateIsCustom = false,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> shop = json['shop'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final Map<String, dynamic> slot = json['preferredSlot'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final Map<String, dynamic>? address = json['address'] as Map<String, dynamic>?;
    DateTime? date(String key) {
      final Object? value = json[key];
      return value is String ? DateTime.tryParse(value)?.toLocal() : null;
    }

    return ServiceRequest(
      requestId: json['requestId'] as String,
      requestNumber: json['requestNumber'] as String? ?? '',
      shopId: shop['shopId'] as String? ?? '',
      shopName: shop['shopName'] as String? ?? '',
      branchName: shop['branchName'] as String? ?? '',
      shopPhone: shop['phone'] as String? ?? '',
      category: ShopCategory.fromCode(json['category'] as String?) ?? ShopCategory.general,
      requestType: ServiceMode.fromCode(json['requestType'] as String?) ?? ServiceMode.visitShop,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RequestItem.fromJson)
          .toList(growable: false),
      preferredDate: json['preferredDate'] as String? ?? '',
      slotStart: slot['start'] as String? ?? '',
      slotEnd: slot['end'] as String? ?? '',
      addressLabel: address?['label'] as String?,
      addressFormatted: address?['formatted'] as String?,
      status: RequestStatus.fromCode(json['status'] as String?),
      confirmedAt: date('confirmedAt'),
      shopNote: json['shopNote'] as String?,
      declineReason: json['declineReason'] as String?,
      cancelReason: json['cancelReason'] as String?,
      orderNumber: json['orderNumber'] as String?,
      expiresAt: date('expiresAt'),
      pickupWorkerName: json['pickupWorkerName'] as String?,
      collectedAt: date('collectedAt'),
      collectedItems: (json['collectedItems'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RequestItem.fromJson)
          .toList(growable: false),
      deliveryDate: json['deliveryDate'] as String?,
      deliveryDateIsCustom: json['deliveryDateIsCustom'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
      history: (json['history'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RequestHistoryEntry.fromJson)
          .toList(growable: false),
      createdAt: date('createdAt') ?? DateTime.now(),
    );
  }

  final String requestId;
  final String requestNumber;
  final String shopId;
  final String shopName;
  final String branchName;
  final String shopPhone;
  final ShopCategory category;
  final ServiceMode requestType;
  final String description;
  final List<RequestItem> items;

  /// YYYY-MM-DD
  final String preferredDate;
  final String slotStart;
  final String slotEnd;
  final String? addressLabel;
  final String? addressFormatted;
  final RequestStatus status;
  final DateTime? confirmedAt;
  final String? shopNote;
  final String? declineReason;
  final String? cancelReason;
  final String? orderNumber;
  final DateTime? expiresAt;
  final String? pickupWorkerName;
  final DateTime? collectedAt;
  final List<RequestItem> collectedItems;

  /// YYYY-MM-DD: when the clothes come back (set when the worker collects).
  final String? deliveryDate;
  final bool deliveryDateIsCustom;
  final bool canCancel;
  final List<RequestHistoryEntry> history;
  final DateTime createdAt;
}

class ServiceRequestPage {
  const ServiceRequestPage({required this.items, required this.page, required this.total});

  factory ServiceRequestPage.fromJson(Map<String, dynamic> json) => ServiceRequestPage(
    items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ServiceRequest.fromJson)
        .toList(growable: false),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final List<ServiceRequest> items;
  final int page;
  final int total;
}

class ServiceRequestDraft {
  const ServiceRequestDraft({
    required this.shopId,
    required this.category,
    required this.requestType,
    required this.description,
    required this.preferredDate,
    required this.slotStart,
    required this.slotEnd,
    this.items = const <RequestItem>[],
    this.addressId,
  });

  final String shopId;
  final ShopCategory category;
  final ServiceMode requestType;
  final String description;

  /// YYYY-MM-DD
  final String preferredDate;
  final String slotStart;
  final String slotEnd;
  final List<RequestItem> items;
  final String? addressId;

  Map<String, Object?> toJson() => <String, Object?>{
    'shopId': shopId,
    'category': category.code,
    'requestType': requestType.code,
    'description': description.trim(),
    'preferredDate': preferredDate,
    'preferredSlot': <String, String>{'start': slotStart, 'end': slotEnd},
    if (items.isNotEmpty) 'items': items.map((RequestItem i) => i.toJson()).toList(),
    if (addressId != null) 'addressId': addressId,
  };
}

List<ShopCategory> _categories(Object? value) => (value as List<dynamic>? ?? const <dynamic>[])
    .map((dynamic code) => ShopCategory.fromCode(code as String?))
    .whereType<ShopCategory>()
    .toList(growable: false);

List<ServiceMode> _modes(Object? value) => (value as List<dynamic>? ?? const <dynamic>[])
    .map((dynamic code) => ServiceMode.fromCode(code as String?))
    .whereType<ServiceMode>()
    .toList(growable: false);
