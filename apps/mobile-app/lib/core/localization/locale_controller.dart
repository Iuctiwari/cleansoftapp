import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexoraa_mobile/core/localization/app_language.dart';

/// Holds the user's chosen app language and remembers it on the device.
///
/// The choice is per device, not per account: it is picked on the login /
/// sign-up screens before anyone is signed in, and survives sign-out.
class LocaleController extends ChangeNotifier {
  LocaleController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _storageKey = 'app.language';

  final FlutterSecureStorage _storage;
  AppLanguage _language = AppLanguage.fallback;

  AppLanguage get language => _language;

  /// Restores the saved language. Call once before runApp.
  Future<void> load() async {
    try {
      _language = AppLanguage.fromCode(await _storage.read(key: _storageKey));
    } catch (_) {
      // Unreadable storage just means the default language.
      _language = AppLanguage.fallback;
    }
    notifyListeners();
  }

  /// Applies [language] immediately; saving it to the device happens in the
  /// background so the UI never waits on storage.
  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    unawaited(_persist(language));
  }

  Future<void> _persist(AppLanguage language) async {
    try {
      await _storage.write(key: _storageKey, value: language.code);
    } catch (_) {
      // The change still applies for this session.
    }
  }
}

abstract final class LocaleDependencies {
  static final LocaleController controller = LocaleController();
}
