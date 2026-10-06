import 'package:flutter/widgets.dart';

/// Languages the app ships translations for (see lib/l10n/app_*.arb).
enum AppLanguage {
  english(code: 'en', nativeName: 'English', englishName: 'English'),
  hindi(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  marathi(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi');

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;

  /// The language's name written in that language — what the picker shows, so
  /// a user can find their language whatever the app is currently set to.
  final String nativeName;
  final String englishName;

  Locale get locale => Locale(code);

  static const AppLanguage fallback = AppLanguage.english;

  static AppLanguage fromCode(String? code) {
    for (final AppLanguage language in values) {
      if (language.code == code) return language;
    }
    return fallback;
  }
}
