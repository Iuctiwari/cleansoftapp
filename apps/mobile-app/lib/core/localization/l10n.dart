import 'package:flutter/widgets.dart';
import 'package:nexoraa_mobile/l10n/app_localizations.dart';

export 'package:nexoraa_mobile/core/localization/app_language.dart';
export 'package:nexoraa_mobile/core/localization/language_picker.dart';
export 'package:nexoraa_mobile/core/localization/locale_controller.dart';
export 'package:nexoraa_mobile/l10n/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Translated strings for the current app language.
  ///
  /// Falls back to English when no localization delegate is in the tree
  /// (e.g. a widget test that pumps a bare MaterialApp), instead of crashing.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
