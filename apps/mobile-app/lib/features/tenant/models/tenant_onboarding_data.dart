import 'registration_form.dart';

class StaffInvitationData {
  String mobileNumber;
  String email;

  StaffInvitationData({this.mobileNumber = '', this.email = ''});

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (mobileNumber.trim().isNotEmpty) 'mobileNumber': mobileNumber.trim(),
    if (email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
  };
}

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
  final List<StaffInvitationData> staff;
  bool branchCreated;
  bool servicesConfigured;
  bool staffInvitationSubmitted;

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
    List<StaffInvitationData>? staff,
    this.branchCreated = false,
    this.servicesConfigured = false,
    this.staffInvitationSubmitted = false,
  }) : selectedServices = selectedServices ?? <String>{},
       staff = staff ?? <StaffInvitationData>[];

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
      'staff': staff.map((invitation) => invitation.toJson()).toList(),
    };
  }
}
