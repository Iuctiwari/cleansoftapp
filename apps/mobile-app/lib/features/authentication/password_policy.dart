import 'package:nexoraa_mobile/l10n/app_localizations.dart';

/// One rule of the password policy auth-service enforces (assertStrongPassword).
enum PasswordRule {
  minLength,
  uppercase,
  lowercase,
  number,
  special;

  bool test(String password) => switch (this) {
    PasswordRule.minLength => password.length >= 8,
    PasswordRule.uppercase => RegExp('[A-Z]').hasMatch(password),
    PasswordRule.lowercase => RegExp('[a-z]').hasMatch(password),
    PasswordRule.number => RegExp(r'\d').hasMatch(password),
    PasswordRule.special => RegExp('[^A-Za-z0-9]').hasMatch(password),
  };

  String label(AppLocalizations l10n) => switch (this) {
    PasswordRule.minLength => l10n.passwordRuleMinLength,
    PasswordRule.uppercase => l10n.passwordRuleUppercase,
    PasswordRule.lowercase => l10n.passwordRuleLowercase,
    PasswordRule.number => l10n.passwordRuleNumber,
    PasswordRule.special => l10n.passwordRuleSpecial,
  };
}

/// The password rules auth-service enforces, checked in the app first so users
/// get a clear message before anything is submitted.
abstract final class PasswordPolicy {
  static const List<PasswordRule> rules = PasswordRule.values;

  /// The first unmet rule as a message, or null when the password is acceptable.
  static String? validate(String password, AppLocalizations l10n) {
    for (final PasswordRule rule in rules) {
      if (!rule.test(password)) {
        return l10n.passwordNeeds(rule.label(l10n).toLowerCase());
      }
    }
    return null;
  }
}
