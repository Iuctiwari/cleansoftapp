/// Module keys as defined by platform-admin-service's ModuleKey enum
/// (apps/backend/platform-admin-service/src/module-access/module-key.enum.ts).
/// Kept as a plain string list rather than a Dart enum so new backend values
/// never require a client rebuild to at least display correctly.
const List<String> kModuleKeys = <String>[
  'ORDER_MANAGEMENT',
  'PAYMENTS',
  'EXPENSES',
  'CASH_REGISTER',
  'MULTI_BRANCH',
  'CUSTOMER_CRM',
  'WHATSAPP_NOTIFICATIONS',
  'ADVANCED_REPORTS',
  'CUSTOM_THEME_BRANDING',
];

class AdminSession {
  const AdminSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  factory AdminSession.fromLoginResponse(Map<String, dynamic> json) {
    final int expiresInSeconds = (json['expiresInSeconds'] as num?)?.toInt() ?? 900;
    return AdminSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        Duration(seconds: expiresInSeconds),
      ),
    );
  }
}

class TenantSummaryModel {
  const TenantSummaryModel({
    required this.tenantId,
    required this.slug,
    required this.businessName,
    required this.businessType,
    required this.ownerName,
    required this.ownerEmail,
    required this.status,
  });

  final String tenantId;
  final String slug;
  final String businessName;
  final String businessType;
  final String ownerName;
  final String ownerEmail;
  final String status;

  factory TenantSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenantSummaryModel(
      tenantId: json['tenantId'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class TenantDirectoryPageModel {
  const TenantDirectoryPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<TenantSummaryModel> items;
  final int page;
  final int limit;
  final int total;

  factory TenantDirectoryPageModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? const [];
    return TenantDirectoryPageModel(
      items: rawItems
          .map((e) => TenantSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class BusinessTypeTerminologyModel {
  const BusinessTypeTerminologyModel({
    required this.customerLabel,
    required this.orderLabel,
    required this.itemLabel,
    required this.deliveryLabel,
  });

  final String customerLabel;
  final String orderLabel;
  final String itemLabel;
  final String deliveryLabel;

  factory BusinessTypeTerminologyModel.fromJson(Map<String, dynamic> json) {
    return BusinessTypeTerminologyModel(
      customerLabel: json['customerLabel'] as String? ?? 'Customer',
      orderLabel: json['orderLabel'] as String? ?? 'Order',
      itemLabel: json['itemLabel'] as String? ?? 'Item',
      deliveryLabel: json['deliveryLabel'] as String? ?? 'Delivery',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'customerLabel': customerLabel,
    'orderLabel': orderLabel,
    'itemLabel': itemLabel,
    'deliveryLabel': deliveryLabel,
  };

  static const BusinessTypeTerminologyModel fallback = BusinessTypeTerminologyModel(
    customerLabel: 'Customer',
    orderLabel: 'Order',
    itemLabel: 'Item',
    deliveryLabel: 'Delivery',
  );
}

class BusinessTypeModel {
  const BusinessTypeModel({
    required this.id,
    required this.value,
    required this.label,
    this.description,
    required this.isActive,
    required this.defaultTerminology,
    required this.defaultOrderStatuses,
    required this.defaultServices,
    required this.defaultItemCategories,
    required this.defaultExpenseCategories,
  });

  final String id;
  final String value;
  final String label;
  final String? description;
  final bool isActive;
  final BusinessTypeTerminologyModel defaultTerminology;
  final List<String> defaultOrderStatuses;
  final List<String> defaultServices;
  final List<String> defaultItemCategories;
  final List<String> defaultExpenseCategories;

  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) =>
        (json[key] as List<dynamic>? ?? const []).whereType<String>().toList(growable: false);
    return BusinessTypeModel(
      id: json['id'] as String? ?? '',
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      defaultTerminology: json['defaultTerminology'] is Map<String, dynamic>
          ? BusinessTypeTerminologyModel.fromJson(
              json['defaultTerminology'] as Map<String, dynamic>,
            )
          : BusinessTypeTerminologyModel.fallback,
      defaultOrderStatuses: stringList('defaultOrderStatuses'),
      defaultServices: stringList('defaultServices'),
      defaultItemCategories: stringList('defaultItemCategories'),
      defaultExpenseCategories: stringList('defaultExpenseCategories'),
    );
  }
}

class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.planKey,
    required this.displayName,
    required this.monthlyPriceInPaise,
    required this.annualPriceInPaise,
    required this.maxBranches,
    required this.maxStaff,
    required this.maxMonthlyOrders,
    required this.trialDays,
    required this.includedModuleKeys,
    required this.isActive,
  });

  final String id;
  final String planKey;
  final String displayName;
  final int monthlyPriceInPaise;
  final int annualPriceInPaise;
  final int maxBranches;
  final int maxStaff;
  final int maxMonthlyOrders;
  final int trialDays;
  final List<String> includedModuleKeys;
  final bool isActive;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      planKey: json['planKey'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      monthlyPriceInPaise: (json['monthlyPriceInPaise'] as num?)?.toInt() ?? 0,
      annualPriceInPaise: (json['annualPriceInPaise'] as num?)?.toInt() ?? 0,
      maxBranches: (json['maxBranches'] as num?)?.toInt() ?? 0,
      maxStaff: (json['maxStaff'] as num?)?.toInt() ?? 0,
      maxMonthlyOrders: (json['maxMonthlyOrders'] as num?)?.toInt() ?? 0,
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 0,
      includedModuleKeys:
          (json['includedModuleKeys'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(growable: false),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class TenantSubscriptionModel {
  const TenantSubscriptionModel({
    required this.id,
    required this.tenantId,
    required this.planKey,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.billingCycle,
    required this.autoRenew,
    this.notes,
  });

  final String id;
  final String tenantId;
  final String planKey;
  final String status;
  final String startDate;
  final String? endDate;
  final String billingCycle;
  final bool autoRenew;
  final String? notes;

  factory TenantSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return TenantSubscriptionModel(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      planKey: json['planKey'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String?,
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
      autoRenew: json['autoRenew'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class SubscriptionHistoryModel {
  const SubscriptionHistoryModel({
    required this.id,
    required this.action,
    this.reason,
    required this.actorAdminUserId,
    required this.timestamp,
    this.newValue,
  });

  final String id;
  final String action;
  final String? reason;
  final String actorAdminUserId;
  final String timestamp;
  /// For PAYMENT_SUCCESS: amountInPaise, razorpayPaymentId, razorpayOrderId.
  /// For PAYMENT_FAILED: razorpayOrderId, razorpayPaymentId, failureReason.
  final Map<String, dynamic>? newValue;

  bool get isSystemGenerated => actorAdminUserId.startsWith('system:');

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryModel(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String?,
      actorAdminUserId: json['actorAdminUserId'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      newValue: json['newValue'] is Map<String, dynamic>
          ? json['newValue'] as Map<String, dynamic>
          : null,
    );
  }
}

class ModuleMatrixEntryModel {
  const ModuleMatrixEntryModel({required this.moduleKey, required this.isEnabled});

  final String moduleKey;
  final bool isEnabled;

  factory ModuleMatrixEntryModel.fromJson(Map<String, dynamic> json) {
    return ModuleMatrixEntryModel(
      moduleKey: json['moduleKey'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}

class EffectiveTenantThemeModel {
  const EffectiveTenantThemeModel({
    required this.tenantId,
    required this.isCustomized,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.darkThemeEnabled,
    required this.customAppTitle,
    this.logoUrl,
    this.bannerUrl,
    required this.allowShopThemeOverride,
  });

  final String tenantId;
  final bool isCustomized;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final bool darkThemeEnabled;
  final String customAppTitle;
  final String? logoUrl;
  final String? bannerUrl;
  final bool allowShopThemeOverride;

  factory EffectiveTenantThemeModel.fromJson(Map<String, dynamic> json) {
    return EffectiveTenantThemeModel(
      tenantId: json['tenantId'] as String? ?? '',
      isCustomized: json['isCustomized'] as bool? ?? false,
      primaryColorHex: json['primaryColorHex'] as String? ?? '#2563EB',
      secondaryColorHex: json['secondaryColorHex'] as String? ?? '#7C3AED',
      accentColorHex: json['accentColorHex'] as String? ?? '#0EA5E9',
      darkThemeEnabled: json['darkThemeEnabled'] as bool? ?? false,
      customAppTitle: json['customAppTitle'] as String? ?? 'Nexoraa CleanSoft',
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      allowShopThemeOverride: json['allowShopThemeOverride'] as bool? ?? false,
    );
  }
}

/// TenantSummaryModel enriched with this tenant's subscription plan/status/
/// days-remaining — backs the Clients tab list and "tenants on this plan".
class TenantOverviewEntryModel {
  const TenantOverviewEntryModel({
    required this.tenantId,
    required this.slug,
    required this.businessName,
    required this.businessType,
    required this.ownerName,
    required this.ownerEmail,
    required this.status,
    this.planKey,
    this.subscriptionStatus,
    this.daysRemaining,
  });

  final String tenantId;
  final String slug;
  final String businessName;
  final String businessType;
  final String ownerName;
  final String ownerEmail;
  final String status;
  final String? planKey;
  final String? subscriptionStatus;
  final int? daysRemaining;

  factory TenantOverviewEntryModel.fromJson(Map<String, dynamic> json) {
    return TenantOverviewEntryModel(
      tenantId: json['tenantId'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      status: json['status'] as String? ?? '',
      planKey: json['planKey'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );
  }
}

class TenantOverviewPageModel {
  const TenantOverviewPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<TenantOverviewEntryModel> items;
  final int page;
  final int limit;
  final int total;

  factory TenantOverviewPageModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? const [];
    return TenantOverviewPageModel(
      items: rawItems
          .map((e) => TenantOverviewEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class BillingAttemptModel {
  const BillingAttemptModel({
    required this.id,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amountInPaise,
    required this.currency,
    required this.billingCycle,
    required this.planKeyAtCreation,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final int amountInPaise;
  final String currency;
  final String billingCycle;
  final String planKeyAtCreation;
  final String status;
  final String createdAt;

  factory BillingAttemptModel.fromJson(Map<String, dynamic> json) {
    return BillingAttemptModel(
      id: json['id'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
      planKeyAtCreation: json['planKeyAtCreation'] as String? ?? '',
      status: json['status'] as String? ?? 'CREATED',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// null means that lookup failed/timed out/service is down — not that the
/// real value is zero.
class TenantOrderSummaryModel {
  const TenantOrderSummaryModel({
    required this.totalOrders,
    required this.ordersThisMonth,
    required this.outstandingMinor,
    this.lastOrderDate,
  });

  final int totalOrders;
  final int ordersThisMonth;
  final String? lastOrderDate;

  /// True accounts-receivable balance — live sum of every order's own
  /// outstandingAmount. See [TenantPaymentSummaryModel.pendingPaymentsMinor]
  /// for the (different) "payments awaiting confirmation" figure.
  final int outstandingMinor;

  factory TenantOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenantOrderSummaryModel(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      ordersThisMonth: (json['ordersThisMonth'] as num?)?.toInt() ?? 0,
      lastOrderDate: json['lastOrderDate'] as String?,
      outstandingMinor: (json['outstandingMinor'] as num?)?.toInt() ?? 0,
    );
  }
}

class TenantPaymentSummaryModel {
  const TenantPaymentSummaryModel({
    required this.totalRevenueMinor,
    required this.revenueThisMonthMinor,
    required this.pendingPaymentsMinor,
  });

  final int totalRevenueMinor;
  final int revenueThisMonthMinor;

  /// Payments recorded but not yet confirmed — NOT accounts-receivable.
  final int pendingPaymentsMinor;

  factory TenantPaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenantPaymentSummaryModel(
      totalRevenueMinor: (json['totalRevenueMinor'] as num?)?.toInt() ?? 0,
      revenueThisMonthMinor: (json['revenueThisMonthMinor'] as num?)?.toInt() ?? 0,
      pendingPaymentsMinor: (json['pendingPaymentsMinor'] as num?)?.toInt() ?? 0,
    );
  }
}

class TenantResourceCountsModel {
  const TenantResourceCountsModel({
    this.branchCount,
    this.staffCount,
    this.customerCount,
    this.orderSummary,
    this.paymentSummary,
  });

  final int? branchCount;
  final int? staffCount;
  final int? customerCount;
  final TenantOrderSummaryModel? orderSummary;
  final TenantPaymentSummaryModel? paymentSummary;

  factory TenantResourceCountsModel.fromJson(Map<String, dynamic> json) {
    return TenantResourceCountsModel(
      branchCount: (json['branchCount'] as num?)?.toInt(),
      staffCount: (json['staffCount'] as num?)?.toInt(),
      customerCount: (json['customerCount'] as num?)?.toInt(),
      orderSummary: json['orderSummary'] is Map<String, dynamic>
          ? TenantOrderSummaryModel.fromJson(json['orderSummary'] as Map<String, dynamic>)
          : null,
      paymentSummary: json['paymentSummary'] is Map<String, dynamic>
          ? TenantPaymentSummaryModel.fromJson(json['paymentSummary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActiveTenantConfigModel {
  const ActiveTenantConfigModel({
    required this.theme,
    required this.enabledModuleKeys,
  });

  final EffectiveTenantThemeModel theme;
  final List<String> enabledModuleKeys;

  factory ActiveTenantConfigModel.fromJson(Map<String, dynamic> json) {
    return ActiveTenantConfigModel(
      theme: EffectiveTenantThemeModel.fromJson(
        json['theme'] as Map<String, dynamic>? ?? const {},
      ),
      enabledModuleKeys: (json['enabledModuleKeys'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
