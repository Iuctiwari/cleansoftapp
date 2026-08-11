/// Holds all form data across the 2-step Create Business Account flow.
/// Passed between pages via GoRouter's `extra` parameter.
class RegistrationForm {
  String businessName;
  String businessType;
  String ownerName;
  String email;
  String mobileNumber;
  String password;
  bool agreedToTerms;

  RegistrationForm({
    this.businessName = '',
    this.businessType = '',
    this.ownerName = '',
    this.email = '',
    this.mobileNumber = '',
    this.password = '',
    this.agreedToTerms = false,
  });

  factory RegistrationForm.fromJson(Map<String, dynamic> json) {
    return RegistrationForm(
      businessName: _stringValue(json, 'businessName'),
      businessType: _stringValue(json, 'businessType'),
      ownerName: _stringValue(json, 'ownerName'),
      email: _stringValue(json, 'email'),
      mobileNumber: _stringValue(json, 'mobileNumber'),
      password: _stringValue(json, 'password'),
      agreedToTerms: json['agreedToTerms'] == true,
    );
  }

  /// Returns a copy with specific fields overridden.
  RegistrationForm copyWith({
    String? businessName,
    String? businessType,
    String? ownerName,
    String? email,
    String? mobileNumber,
    String? password,
    bool? agreedToTerms,
  }) {
    return RegistrationForm(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
    );
  }

  /// Converts to a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName.trim(),
      'businessType': businessType,
      'ownerName': ownerName.trim(),
      'email': email.trim().toLowerCase(),
      'mobileNumber': mobileNumber.trim(),
      'password': password,
      'agreedToTerms': agreedToTerms,
    };
  }

  static String _stringValue(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    return value is String ? value : '';
  }

  @override
  String toString() =>
      'RegistrationForm(businessName: $businessName, businessType: $businessType, '
      'ownerName: $ownerName, email: $email, mobileNumber: $mobileNumber)';
}
