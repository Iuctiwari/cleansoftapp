/// A subscription plan as offered to a tenant (GET /tenant/subscription/plans).
class TenantPlan {
  const TenantPlan({
    required this.planKey,
    required this.displayName,
    required this.monthlyPriceInPaise,
    required this.annualPriceInPaise,
    required this.trialDays,
    required this.includedModuleKeys,
    required this.maxBranches,
    required this.maxStaff,
    required this.maxMonthlyOrders,
  });

  factory TenantPlan.fromJson(Map<String, dynamic> json) {
    return TenantPlan(
      planKey: json['planKey'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      monthlyPriceInPaise: (json['monthlyPriceInPaise'] as num?)?.toInt() ?? 0,
      annualPriceInPaise: (json['annualPriceInPaise'] as num?)?.toInt() ?? 0,
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 0,
      includedModuleKeys: (json['includedModuleKeys'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      maxBranches: (json['maxBranches'] as num?)?.toInt() ?? 0,
      maxStaff: (json['maxStaff'] as num?)?.toInt() ?? 0,
      maxMonthlyOrders: (json['maxMonthlyOrders'] as num?)?.toInt() ?? 0,
    );
  }

  final String planKey;
  final String displayName;
  final int monthlyPriceInPaise;
  final int annualPriceInPaise;
  final int trialDays;
  final List<String> includedModuleKeys;
  final int maxBranches;
  final int maxStaff;
  final int maxMonthlyOrders;

  /// A plan is free for a cycle purely because its price for that cycle is
  /// zero — not tied to any specific planKey (e.g. FREE_TRIAL). Paid plans
  /// go through Razorpay create-order; free plans are assigned immediately.
  int priceForCycle(String billingCycle) =>
      billingCycle == 'ANNUAL' ? annualPriceInPaise : monthlyPriceInPaise;

  bool isFreeForCycle(String billingCycle) => priceForCycle(billingCycle) == 0;
}

class TenantSubscriptionSummary {
  const TenantSubscriptionSummary({
    required this.planKey,
    required this.status,
    required this.billingCycle,
    required this.startDate,
    required this.autoRenew,
    this.endDate,
    this.trialEndsAt,
    this.daysRemaining,
  });

  factory TenantSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return TenantSubscriptionSummary(
      planKey: json['planKey'] as String? ?? '',
      status: json['status'] as String? ?? '',
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'] as String),
      trialEndsAt: json['trialEndsAt'] == null
          ? null
          : DateTime.tryParse(json['trialEndsAt'] as String),
      autoRenew: json['autoRenew'] as bool? ?? false,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );
  }

  final String planKey;
  final String status;
  final String billingCycle;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndsAt;
  final bool autoRenew;
  final int? daysRemaining;
}

/// GET /tenant/subscription/status — also what select-plan returns after a change.
class TenantSubscriptionStatus {
  const TenantSubscriptionStatus({
    required this.hasSubscription,
    this.subscription,
    this.plan,
  });

  factory TenantSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return TenantSubscriptionStatus(
      hasSubscription: json['hasSubscription'] as bool? ?? false,
      subscription: json['subscription'] == null
          ? null
          : TenantSubscriptionSummary.fromJson(
              json['subscription'] as Map<String, dynamic>,
            ),
      plan: json['plan'] == null ? null : TenantPlan.fromJson(json['plan'] as Map<String, dynamic>),
    );
  }

  final bool hasSubscription;
  final TenantSubscriptionSummary? subscription;
  final TenantPlan? plan;
}

/// POST /tenant/subscription/create-order.
class TenantBillingOrder {
  const TenantBillingOrder({
    required this.razorpayOrderId,
    required this.amountInPaise,
    required this.currency,
    required this.billingCycle,
  });

  factory TenantBillingOrder.fromJson(Map<String, dynamic> json) {
    return TenantBillingOrder(
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
    );
  }

  final String razorpayOrderId;
  final int amountInPaise;
  final String currency;
  final String billingCycle;
}

class SubscriptionApiException implements Exception {
  const SubscriptionApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
