/// The password rules auth-service enforces (assertStrongPassword), checked in
/// the app first so users get a clear message before anything is submitted.
abstract final class PasswordPolicy {
  static const String hint =
      'At least 8 characters, with an uppercase letter, a lowercase letter, a number and a special character.';

  static final List<({String label, bool Function(String) test})> rules =
      <({String label, bool Function(String) test})>[
        (label: 'At least 8 characters', test: (String p) => p.length >= 8),
        (label: 'An uppercase letter (A–Z)', test: (String p) => RegExp('[A-Z]').hasMatch(p)),
        (label: 'A lowercase letter (a–z)', test: (String p) => RegExp('[a-z]').hasMatch(p)),
        (label: 'A number (0–9)', test: (String p) => RegExp(r'\d').hasMatch(p)),
        (label: 'A special character (e.g. ! @ # \$)', test: (String p) => RegExp('[^A-Za-z0-9]').hasMatch(p)),
      ];

  /// The first unmet rule as a message, or null when the password is acceptable.
  static String? validate(String password) {
    for (final rule in rules) {
      if (!rule.test(password)) return 'Password needs: ${rule.label.toLowerCase()}.';
    }
    return null;
  }
}
