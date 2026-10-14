/// Shop-side data for the marketplace: the branch listing and online requests.
library;

import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';

/// The branch's public listing as the shop sees it (GET /v1/shop-listing/me).
class ShopListing {
  const ShopListing({
    required this.branchId,
    required this.shopName,
    required this.branchName,
    required this.categories,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.ownerPhone,
    required this.phoneShownToCustomers,
    required this.serviceModes,
    required this.serviceRadiusKm,
    required this.openingHours,
    required this.isListed,
    required this.saved,
    required this.missingFields,
    required this.isVisibleToCustomers,
    this.area,
    this.landmark,
    this.latitude,
    this.longitude,
    this.bookingPhone,
    this.about,
    this.hiddenReason,
  });

  factory ShopListing.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> address = json['address'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ShopListing(
      branchId: json['branchId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic c) => ShopCategory.fromCode(c as String?))
          .whereType<ShopCategory>()
          .toList(growable: false),
      streetAddress: address['streetAddress'] as String? ?? '',
      area: address['area'] as String?,
      landmark: address['landmark'] as String?,
      city: address['city'] as String? ?? '',
      state: address['state'] as String? ?? '',
      postalCode: address['postalCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bookingPhone: json['bookingPhone'] as String?,
      ownerPhone: json['ownerPhone'] as String? ?? '',
      phoneShownToCustomers: json['phoneShownToCustomers'] as String? ?? '',
      serviceModes: (json['serviceModes'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic m) => ServiceMode.fromCode(m as String?))
          .whereType<ServiceMode>()
          .toList(growable: false),
      serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toInt() ?? 5,
      openingHours: (json['openingHours'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OpeningHoursDay.fromJson)
          .toList(growable: false),
      about: json['about'] as String?,
      isListed: json['isListed'] as bool? ?? true,
      saved: json['saved'] as bool? ?? false,
      missingFields: (json['missingFields'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      isVisibleToCustomers: json['isVisibleToCustomers'] as bool? ?? false,
      hiddenReason: json['hiddenReason'] as String?,
    );
  }

  final String branchId;
  final String shopName;
  final String branchName;
  final List<ShopCategory> categories;
  final String streetAddress;
  final String? area;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final String? bookingPhone;
  final String ownerPhone;
  final String phoneShownToCustomers;
  final List<ServiceMode> serviceModes;
  final int serviceRadiusKm;
  final List<OpeningHoursDay> openingHours;
  final String? about;
  final bool isListed;
  final bool saved;
  final List<String> missingFields;
  final bool isVisibleToCustomers;

  /// incomplete | unlisted | business_inactive
  final String? hiddenReason;

  bool get needsAddress => missingFields.isNotEmpty;
}

/// What the listing form saves (PUT /v1/shop-listing/me, a full replace).
class ShopListingDraft {
  const ShopListingDraft({
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.serviceModes,
    required this.serviceRadiusKm,
    required this.openingHours,
    required this.isListed,
    this.area,
    this.landmark,
    this.bookingPhone,
    this.about,
  });

  final String streetAddress;
  final String? area;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String? bookingPhone;
  final List<ServiceMode> serviceModes;
  final int serviceRadiusKm;
  final List<OpeningHoursDay> openingHours;
  final String? about;
  final bool isListed;

  Map<String, Object?> toJson() => <String, Object?>{
    'streetAddress': streetAddress.trim(),
    if ((area ?? '').trim().isNotEmpty) 'area': area!.trim(),
    if ((landmark ?? '').trim().isNotEmpty) 'landmark': landmark!.trim(),
    'city': city.trim(),
    'state': state.trim(),
    'postalCode': postalCode.trim(),
    'latitude': latitude,
    'longitude': longitude,
    if ((bookingPhone ?? '').trim().isNotEmpty) 'bookingPhone': bookingPhone!.trim(),
    'serviceModes': serviceModes.map((ServiceMode m) => m.code).toList(),
    'serviceRadiusKm': serviceRadiusKm,
    'openingHours': openingHours
        .map(
          (OpeningHoursDay d) => <String, Object>{
            'day': d.day,
            'closed': d.closed,
            if (!d.closed && d.open != null) 'open': d.open!,
            if (!d.closed && d.close != null) 'close': d.close!,
          },
        )
        .toList(),
    if ((about ?? '').trim().isNotEmpty) 'about': about!.trim(),
    'isListed': isListed,
  };
}

class ShopRequestSummary {
  const ShopRequestSummary({required this.pending, required this.accepted});

  factory ShopRequestSummary.fromJson(Map<String, dynamic> json) => ShopRequestSummary(
    pending: (json['pending'] as num?)?.toInt() ?? 0,
    accepted: (json['accepted'] as num?)?.toInt() ?? 0,
  );

  final int pending;
  final int accepted;
}

/// A request as the shop sees it: customer details and allowed actions.
class ShopRequest {
  const ShopRequest({
    required this.base,
    required this.customerName,
    required this.customerMobile,
    required this.customerEmail,
    required this.canAccept,
    required this.canDecline,
    required this.canLinkOrder,
    required this.canComplete,
    this.canAssignWorker = false,
    this.canCollect = false,
    this.canAssignStaff = false,
    this.pickupWorkerId,
    this.shopCustomerId,
    this.distanceKm,
    this.addressContactName,
    this.addressContactPhone,
    this.addressLandmark,
    this.addressLatitude,
    this.addressLongitude,
    this.orderId,
  });

  factory ShopRequest.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> customer = json['customer'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final Map<String, dynamic> actions = json['actions'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final Map<String, dynamic>? address = json['address'] as Map<String, dynamic>?;
    return ShopRequest(
      // The shared fields parse exactly like the customer's view.
      base: ServiceRequest.fromJson(<String, dynamic>{
        ...json,
        'canCancel': false,
        'history': json['history'] ?? const <dynamic>[],
      }),
      customerName: customer['name'] as String? ?? '',
      customerMobile: customer['mobile'] as String? ?? '',
      customerEmail: customer['email'] as String? ?? '',
      shopCustomerId: json['shopCustomerId'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      addressContactName: address?['contactName'] as String?,
      addressContactPhone: address?['contactPhone'] as String?,
      addressLandmark: address?['landmark'] as String?,
      addressLatitude: (address?['latitude'] as num?)?.toDouble(),
      addressLongitude: (address?['longitude'] as num?)?.toDouble(),
      orderId: json['orderId'] as String?,
      canAccept: actions['accept'] as bool? ?? false,
      canDecline: actions['decline'] as bool? ?? false,
      canLinkOrder: actions['linkOrder'] as bool? ?? false,
      canComplete: actions['complete'] as bool? ?? false,
      canAssignWorker: actions['assignWorker'] as bool? ?? false,
      canCollect: actions['collect'] as bool? ?? false,
      canAssignStaff: actions['assignStaff'] as bool? ?? false,
      pickupWorkerId: (json['pickupWorker'] as Map<String, dynamic>?)?['userId'] as String?,
    );
  }

  final ServiceRequest base;
  final String customerName;
  final String customerMobile;
  final String customerEmail;
  final String? shopCustomerId;
  final double? distanceKm;
  final String? addressContactName;
  final String? addressContactPhone;
  final String? addressLandmark;
  final double? addressLatitude;
  final double? addressLongitude;
  final String? orderId;
  final bool canAccept;
  final bool canDecline;
  final bool canLinkOrder;
  final bool canComplete;
  final bool canAssignWorker;
  final bool canCollect;

  /// Salon appointments: owner/manager can change who does each service.
  final bool canAssignStaff;
  final String? pickupWorkerId;

  String get requestId => base.requestId;
  RequestStatus get status => base.status;
}

class ShopRequestPage {
  const ShopRequestPage({required this.items, required this.page, required this.total});

  factory ShopRequestPage.fromJson(Map<String, dynamic> json) => ShopRequestPage(
    items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ShopRequest.fromJson)
        .toList(growable: false),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final List<ShopRequest> items;
  final int page;
  final int total;
}
