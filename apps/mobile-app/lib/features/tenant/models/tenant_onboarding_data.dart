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
  String state;
  String country;
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
    this.state = '',
    this.country = '',
    this.postalCode = '',
    this.phone = '',
    this.email = '',
    Set<String>? selectedServices,
    List<String>? staffEmails,
  }) : selectedServices = selectedServices ?? <String>{},
       staffEmails = staffEmails ?? <String>[];
}
