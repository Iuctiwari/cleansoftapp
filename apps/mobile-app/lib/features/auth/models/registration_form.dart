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

  @override
  String toString() =>
      'RegistrationForm(businessName: $businessName, businessType: $businessType, '
      'ownerName: $ownerName, email: $email, mobileNumber: $mobileNumber)';
}
