import 'registration_form.dart';

/// In-memory data collected during tenant workspace setup.
///
/// This object is passed between onboarding routes so navigating back and forth
/// does not discard entered values. It is intentionally not an API model.
class TenantOnboardingData {
  RegistrationForm registrationForm;
  String tenantId;
  String ownerUserId;
  String slug;
  String branchName;
  String streetAddress;
  String city;
  String postalCode;
  String phone;
  String email;
  final Set<String> selectedServices;
  final List<String> staffEmails;

  TenantOnboardingData({
    required this.registrationForm,
    this.tenantId = '',
    this.ownerUserId = '',
    this.slug = '',
    this.branchName = '',
    this.streetAddress = '',
    this.city = '',
    this.postalCode = '',
    this.phone = '',
    this.email = '',
    Set<String>? selectedServices,
    List<String>? staffEmails,
  }) : selectedServices = selectedServices ?? <String>{},
       staffEmails = staffEmails ?? <String>[];

  Map<String, dynamic> toOnboardingJson() {
    return {
      'businessName': registrationForm.businessName.trim(),
      'businessType': registrationForm.businessType,
      'ownerName': registrationForm.ownerName.trim(),
      'email': registrationForm.email.trim().toLowerCase(),
      'mobileNumber': registrationForm.mobileNumber.trim(),
      'branch': {
        'branchName': branchName.trim(),
        'streetAddress': streetAddress.trim(),
        'city': city.trim(),
        'postalCode': postalCode.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
      },
      'services': selectedServices.toList(growable: false),
      'staff': const <String>[],
    };
  }
}
