import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Translated labels and shared actions for the customer screens.
extension ConsumerLabels on BuildContext {
  String categoryLabel(ShopCategory category) => switch (category) {
    ShopCategory.laundry => l10n.businessTypeLaundry,
    ShopCategory.dryCleaning => l10n.businessTypeDryCleaning,
    ShopCategory.tailoring => l10n.businessTypeTailoring,
    ShopCategory.shoeCleaning => l10n.businessTypeShoeCleaning,
    ShopCategory.applianceRepair => l10n.businessTypeApplianceRepair,
    ShopCategory.mobileRepair => l10n.businessTypeMobileRepair,
    ShopCategory.vehicleWash => l10n.businessTypeVehicleWash,
    ShopCategory.salon => l10n.businessTypeSalon,
    ShopCategory.general => l10n.businessTypeGeneral,
    ShopCategory.custom => l10n.businessTypeCustom,
  };

  String modeLabel(ServiceMode mode) => switch (mode) {
    ServiceMode.visitShop => l10n.modeVisitShop,
    ServiceMode.homeService => l10n.modeHomeService,
    ServiceMode.pickupDrop => l10n.modePickupDrop,
  };

  String addressLabel(AddressLabel label) => switch (label) {
    AddressLabel.home => l10n.addressLabelHome,
    AddressLabel.work => l10n.addressLabelWork,
    AddressLabel.other => l10n.addressLabelOther,
  };

  String statusLabel(RequestStatus status) => switch (status) {
    RequestStatus.pending => l10n.requestStatusPending,
    RequestStatus.accepted => l10n.requestStatusAccepted,
    RequestStatus.declined => l10n.requestStatusDeclined,
    RequestStatus.cancelled => l10n.requestStatusCancelled,
    RequestStatus.expired => l10n.requestStatusExpired,
    RequestStatus.completed => l10n.requestStatusCompleted,
  };

  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// "Wed, 8 Oct" in the app language.
  String formatDay(DateTime date) => DateFormat('EEE, d MMM', _locale).format(date);

  /// "Wed, 8 Oct, 10:30 am" in the app language.
  String formatDateTime(DateTime date) =>
      DateFormat('EEE, d MMM, h:mm a', _locale).format(date);

  /// "10:00" → "10:00 am" in the app language.
  String formatClock(String clock) {
    final List<String> parts = clock.split(':');
    if (parts.length != 2) return clock;
    final DateTime time = DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    return DateFormat('h:mm a', _locale).format(time);
  }

  /// Full weekday name for 0 = Sunday … 6 = Saturday.
  String weekdayName(int day) =>
      DateFormat('EEEE', _locale).format(DateTime(2026, 10, 4 + day)); // 2026-10-04 is a Sunday

  /// A translated message for an API failure.
  String consumerError(Object error) {
    if (error is! ConsumerApiException) return l10n.consumerErrGeneric;
    if (error.isNetwork) return l10n.consumerErrNetwork;
    return switch (error.code) {
      'consumer.email_taken' || 'consumer.account_exists' => l10n.consumerErrEmailTaken,
      'consumer.mobile_taken' => l10n.consumerErrMobileTaken,
      'consumer.mobile_invalid' => l10n.invalidMobile,
      'auth.password_policy_failed' => l10n.consumerErrPasswordPolicy,
      'auth.login_denied' => l10n.consumerErrLoginDenied,
      'auth.email_not_verified' => l10n.consumerErrNotVerified,
      'consumer.verification_invalid' || 'auth.reset_invalid' => l10n.consumerErrCodeInvalid,
      'consumer.verification_attempts_exceeded' ||
      'auth.reset_attempts_exceeded' ||
      'auth.login_temporarily_blocked' => l10n.consumerErrTooManyAttempts,
      'auth.email_delivery_failed' => l10n.consumerErrEmailDelivery,
      'session_expired' || 'auth.session_expired' => l10n.consumerErrSession,
      // marketplace-service answers in readable sentences
      _ => error.message.isNotEmpty ? error.message : l10n.consumerErrGeneric,
    };
  }

  /// Shows an error pop-up; an expired session signs the customer out
  /// (the router then sends them to the sign-in screen).
  Future<void> showConsumerError(Object error) async {
    if (error is ConsumerApiException && error.isSessionExpired) {
      await ConsumerDependencies.controller.handleSessionExpired();
      return;
    }
    if (!mounted) return;
    final String message = consumerError(error);
    await AppAlertDialog.show(this, title: AppAlertDialog.titleFor(message), message: message);
  }

  void showConsumerToast(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> callPhone(String phone) => _launch(Uri(scheme: 'tel', path: phone));

  Future<void> openDirections(double latitude, double longitude) => _launch(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'),
  );

  Future<void> _launch(Uri uri) async {
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) showConsumerToast(l10n.consumerCouldNotOpen);
  }
}

AppBadgeTone statusTone(RequestStatus status) => switch (status) {
  RequestStatus.pending => AppBadgeTone.warning,
  RequestStatus.accepted => AppBadgeTone.info,
  RequestStatus.completed => AppBadgeTone.success,
  RequestStatus.declined => AppBadgeTone.error,
  RequestStatus.cancelled || RequestStatus.expired => AppBadgeTone.neutral,
};

IconData categoryIcon(ShopCategory category) => switch (category) {
  ShopCategory.laundry => AppIcons.washingMachine,
  ShopCategory.dryCleaning => AppIcons.dryCleaning,
  ShopCategory.tailoring => Icons.content_cut_rounded,
  ShopCategory.shoeCleaning => Icons.ice_skating_outlined,
  ShopCategory.applianceRepair => Icons.build_outlined,
  ShopCategory.mobileRepair => Icons.phone_android_rounded,
  ShopCategory.vehicleWash => Icons.local_car_wash_outlined,
  ShopCategory.salon => Icons.face_retouching_natural_outlined,
  ShopCategory.general || ShopCategory.custom => AppIcons.service,
};

IconData modeIcon(ServiceMode mode) => switch (mode) {
  ServiceMode.visitShop => Icons.storefront_outlined,
  ServiceMode.homeService => Icons.home_outlined,
  ServiceMode.pickupDrop => AppIcons.delivery,
};

/// Section heading used on the customer screens.
class ConsumerSectionTitle extends StatelessWidget {
  const ConsumerSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(text, style: AppTextStyles.headingSmall),
  );
}

/// Full-width primary button that shows a spinner while [busy].
class ConsumerPrimaryButton extends StatelessWidget {
  const ConsumerPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: <Widget>[
      PrimaryButton(label: busy ? '' : label, onPressed: busy ? null : onPressed),
      if (busy)
        const SizedBox.square(
          dimension: AppIconSizes.xl,
          child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: AppBorderWidths.medium),
        ),
    ],
  );
}
