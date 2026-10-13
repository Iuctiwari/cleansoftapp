// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get chooseLanguageSubtitle =>
      'You can change this anytime from your profile.';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSkipForNow => 'Skip for now';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonLocation => 'Location';

  @override
  String get commonBusiness => 'Business';

  @override
  String get commonOr => 'or';

  @override
  String get commonActive => 'Active';

  @override
  String get commonRequiredInformation => 'Required information';

  @override
  String get commonConnectionProblem => 'Connection problem';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonUnableToSignIn => 'Unable to sign in. Please try again.';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String stepFraction(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to your business account';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get createBusinessAccount => 'Create Business Account';

  @override
  String get companyAdmin => 'Company Admin';

  @override
  String get termsAgreementPrefix => 'By signing in you agree to our ';

  @override
  String get termsAgreementSuffix => '';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get loginMissingCredentials =>
      'Enter your email and password to continue.';

  @override
  String get loginInvalidCredentials => 'Invalid email or password';

  @override
  String get splashTagline => 'Business Management Platform';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get backToLoginTooltip => 'Back to login';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get forgotPasswordHeading => 'Forgot your password?';

  @override
  String get forgotPasswordBody =>
      'Enter your email address and we\'ll send you a 6-digit verification code to reset your password.';

  @override
  String get sendingCode => 'Sending code...';

  @override
  String get sendVerificationCode => 'Send verification code';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String codeSentTo(String email) {
    return 'If the account is eligible, a verification code has been sent to $email. Follow the instructions to reset your password.';
  }

  @override
  String get codeSentGeneric =>
      'If the account is eligible, a verification code has been sent.';

  @override
  String get enterEmailToContinue => 'Enter your email address to continue.';

  @override
  String get unableToSendCode =>
      'Unable to send verification code. Please try again.';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get resetPasswordBody =>
      'Enter the 6-digit verification code sent to your email and your new password.';

  @override
  String get verificationCodeLabel => '6-Digit Verification Code';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get resettingPassword => 'Resetting password...';

  @override
  String get enterSixDigitCode =>
      'Enter the 6-digit verification code sent to your email.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully. Please sign in.';

  @override
  String get passwordResetFailed =>
      'Failed to reset password. Please verify your code and try again.';

  @override
  String get passwordPolicyHint =>
      'At least 8 characters, with an uppercase letter, a lowercase letter, a number and a special character.';

  @override
  String get passwordRuleMinLength => 'At least 8 characters';

  @override
  String get passwordRuleUppercase => 'An uppercase letter (A–Z)';

  @override
  String get passwordRuleLowercase => 'A lowercase letter (a–z)';

  @override
  String get passwordRuleNumber => 'A number (0–9)';

  @override
  String get passwordRuleSpecial => 'A special character (e.g. ! @ # \$)';

  @override
  String passwordNeeds(String rule) {
    return 'Password needs: $rule.';
  }

  @override
  String get businessInfoTitle => 'Business Info';

  @override
  String get businessInfoHeading => 'Tell us about your business';

  @override
  String get businessInfoSubtitle =>
      'This helps us personalize your experience.';

  @override
  String get businessName => 'Business Name';

  @override
  String get businessNameHint => 'e.g. Ahmed Laundry & Cleaners';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get nameTooShort => 'Name is too short';

  @override
  String get businessType => 'Business Type';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get owner => 'Owner';

  @override
  String get fullNameHint => 'Full name';

  @override
  String get ownerNameRequired => 'Owner name is required';

  @override
  String get selectBusinessType => 'Please select a business type';

  @override
  String get businessSummaryIntro =>
      'Here\'s a summary of your business. You can update these later in Settings.';

  @override
  String get businessTypeLaundry => 'Laundry';

  @override
  String get businessTypeDryCleaning => 'Dry Cleaning';

  @override
  String get businessTypeTailoring => 'Tailoring';

  @override
  String get businessTypeShoeCleaning => 'Shoe Cleaning';

  @override
  String get businessTypeApplianceRepair => 'Appliance Repair';

  @override
  String get businessTypeMobileRepair => 'Mobile Repair';

  @override
  String get businessTypeVehicleWash => 'Vehicle Wash';

  @override
  String get businessTypeSalon => 'Salon';

  @override
  String get businessTypeGeneral => 'General';

  @override
  String get businessTypeCustom => 'Custom';

  @override
  String get serviceWashAndFold => 'Wash & Fold';

  @override
  String get accountDetailsTitle => 'Account Details';

  @override
  String get createAccountHeading => 'Create your account';

  @override
  String get createAccountSubtitle => 'You\'ll use these to sign in.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get passwordMinHint => 'Min. 8 characters';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMin8 => 'Minimum 8 characters';

  @override
  String get passwordNeedsUppercase => 'Must contain an uppercase letter';

  @override
  String get passwordNeedsNumber => 'Must contain a number';

  @override
  String get passwordNeedsSpecial => 'Must contain a special character';

  @override
  String get agreePrefix => 'I agree to the ';

  @override
  String get agreeAnd => ' and ';

  @override
  String get agreeSuffix => '';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registrationFillHighlighted =>
      'Please fill in the highlighted fields — email, phone number and password are required.';

  @override
  String get mustAgreeTerms => 'You must agree to the Terms of Service.';

  @override
  String alreadyRegisteredAdvice(String message) {
    return '$message. Log in with that account instead (use \"Forgot password?\" if needed), or use a different one.';
  }

  @override
  String get registrationFailed =>
      'Unable to complete registration. Please try again.';

  @override
  String get accountCreatedTitle => 'Account Created!';

  @override
  String get accountCreatedBody =>
      'Your business account is ready.\nLet\'s set up your workspace.';

  @override
  String get startSetup => 'Start Setup';

  @override
  String get firstBranchTitle => 'First Branch';

  @override
  String get firstBranchHeading => 'Add your first branch';

  @override
  String get firstBranchSubtitle =>
      'Enter the location and contact details for your main branch.';

  @override
  String get branchName => 'Branch Name';

  @override
  String get mainBranchHint => 'Main Branch';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get streetAddressHint => 'Street address';

  @override
  String get city => 'City';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get postalCodeHint => 'Postal code';

  @override
  String get invalidEmailAddress => 'Enter a valid email address';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesSubtitle =>
      'Select the services your business offers. You can add more later.';

  @override
  String get selectAtLeastOneService => 'Select at least one service';

  @override
  String servicesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services selected',
      one: '1 service selected',
    );
    return '$_temp0';
  }

  @override
  String get inviteStaffTitle => 'Invite Staff';

  @override
  String get inviteStaffSubtitle =>
      'Invite team members to join your workspace. Each person gets an email invitation.';

  @override
  String get staffEmailLabel => 'Email *';

  @override
  String staffEmailNumberedLabel(int number) {
    return 'Email $number *';
  }

  @override
  String get staffMobileLabel => 'Mobile Number (Optional)';

  @override
  String staffMobileNumberedLabel(int number) {
    return 'Mobile Number $number (Optional)';
  }

  @override
  String get emailRequiredForInvite =>
      'Email is required to send the invitation';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get emailEnteredTwice => 'This email is entered twice';

  @override
  String get invalidMobile => 'Enter a valid mobile number';

  @override
  String get addAnother => 'Add Another';

  @override
  String get inviteStaffNote =>
      'Each staff member gets an email with their login ID (their email). They set their own password by tapping \"Forgot password?\" in the app. You can add more staff later from the Staff screen.';

  @override
  String get inviteFixHighlighted =>
      'Please fix the highlighted fields. Each staff member needs an email address — the invitation is sent by email.';

  @override
  String get invitationsSent => 'Invitations sent';

  @override
  String get invitationsNeedAttention => 'Some invitations need attention';

  @override
  String inviteReportAllSent(String emails) {
    return 'Invitation sent to $emails. They\'ll set their own password using \"Forgot password?\" in the app.';
  }

  @override
  String inviteReportInvited(String emails) {
    return 'Invited: $emails.';
  }

  @override
  String inviteReportEmailFailed(String email) {
    return '$email — account created, but the email could not be sent. Ask them to open the app and tap \"Forgot password?\".';
  }

  @override
  String inviteReportFailed(String email, String reason) {
    return '$email — $reason';
  }

  @override
  String get inviteReportCouldNotInvite => 'could not be invited';

  @override
  String get inviteReportFooter =>
      'You can add or re-invite staff later from the Staff screen.';

  @override
  String get unableToSaveOnboarding =>
      'Unable to save onboarding. Please try again.';

  @override
  String get allSetTitle => 'All Set!';

  @override
  String get allSetHeading => 'You\'re all set!';

  @override
  String get allSetBody =>
      'Your workspace is configured and ready. Start adding orders and managing your business.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String branchCreated(String name) {
    return '$name created';
  }

  @override
  String get branchNotCreated => 'Branch not created';

  @override
  String servicesConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services configured',
      one: '1 service configured',
    );
    return '$_temp0';
  }

  @override
  String get servicesNotConfigured => 'Services not configured';

  @override
  String get staffInvitationSkipped => 'Staff invitation skipped';

  @override
  String staffInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staff invitations sent',
      one: '1 staff invitation sent',
    );
    return '$_temp0';
  }

  @override
  String get choosePlanTitle => 'Choose your plan';

  @override
  String get choosePlanSubtitle =>
      'Pick a plan to activate your workspace. You can change this anytime.';

  @override
  String get unableToLoadPlans => 'Unable to load plans. Please try again.';

  @override
  String get unableToSelectPlan =>
      'Unable to select this plan. Please try again.';

  @override
  String get noPlansTitle => 'No plans available';

  @override
  String get noPlansMessage =>
      'There are no active subscription plans configured yet.';

  @override
  String get billingMonthly => 'Monthly';

  @override
  String get billingAnnual => 'Annual';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get planFree => 'Free';

  @override
  String get perYear => ' / year';

  @override
  String get perMonth => ' / month';

  @override
  String freeTrialDays(int days) {
    return '$days-day free trial';
  }

  @override
  String planLimits(int branches, int staff, int orders) {
    return 'Up to $branches branches · $staff staff · $orders orders/mo';
  }

  @override
  String get myProfile => 'My Profile';

  @override
  String get editProfileTooltip => 'Edit profile';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get personalInformation => 'PERSONAL INFORMATION';

  @override
  String get securitySection => 'SECURITY';

  @override
  String get preferencesSection => 'PREFERENCES';

  @override
  String get changePassword => 'Change Password';

  @override
  String lastChanged(String when) {
    return 'Last changed $when';
  }

  @override
  String get accountCreatedLabel => 'Account Created';

  @override
  String get plan => 'Plan';

  @override
  String get branch => 'Branch';

  @override
  String get roleSwitch => 'ROLE SWITCH';

  @override
  String get roleSwitchSubtitle => 'Demo mode — switch dashboard view';

  @override
  String get roleOwnerDescription => 'Full access to all features';

  @override
  String get roleBranchManager => 'Branch Manager';

  @override
  String get roleBranchManagerDescription => 'Branch operations & staff';

  @override
  String get roleStaffMember => 'Staff Member';

  @override
  String get roleStaffMemberDescription => 'Assigned orders only';

  @override
  String get signOut => 'Sign Out';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get enterYourPhone => 'Enter your phone number';

  @override
  String get enterBusinessName => 'Enter your business name';

  @override
  String get enterLocationCityBranch => 'Enter your location (City/Branch)';

  @override
  String get enterLocation => 'Enter your location';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get fixHighlightedBeforeSaving =>
      'Please fix the highlighted fields before saving.';

  @override
  String get changePasswordIntro =>
      'Enter your current password, then choose a new one.';

  @override
  String get enterCurrentPassword => 'Enter your current password.';

  @override
  String get newPasswordsDoNotMatch => 'The new passwords do not match.';

  @override
  String get newPasswordMustDiffer =>
      'The new password must be different from the current one.';

  @override
  String get unableToChangePassword =>
      'Unable to change the password. Please try again.';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordChangedBody =>
      'Your password has been changed and your other devices were signed out. Please sign in again with your new password.';

  @override
  String get changingPassword => 'Changing password...';

  @override
  String get welcomeTitle => 'How would you like to use Nexoraa?';

  @override
  String get welcomeSubtitle => 'Choose one — you can switch any time.';

  @override
  String get welcomeCustomerTitle => 'I need a service';

  @override
  String get welcomeCustomerSubtitle =>
      'Find laundry, repair, salon and more near you';

  @override
  String get welcomeBusinessTitle => 'I run a business';

  @override
  String get welcomeBusinessSubtitle =>
      'Manage orders, staff and payments for your shop';

  @override
  String get consumerLoginTitle => 'Welcome';

  @override
  String get consumerLoginSubtitle => 'Sign in to find services near you';

  @override
  String get consumerIdentifierLabel => 'Email or mobile number';

  @override
  String get consumerNewHere => 'New here?';

  @override
  String get consumerCreateAccount => 'Create an account';

  @override
  String get consumerBusinessLink => 'Run a business? Sign in here';

  @override
  String get consumerSignupTitle => 'Create your account';

  @override
  String get consumerSignupSubtitle =>
      'It\'s free. We\'ll email you a code to verify.';

  @override
  String get consumerFullName => 'Full name';

  @override
  String get consumerMobileNumber => 'Mobile number';

  @override
  String get consumerConfirmPassword => 'Confirm password';

  @override
  String get consumerHaveAccount => 'Already have an account? Sign in';

  @override
  String get consumerVerifyTitle => 'Verify your email';

  @override
  String consumerVerifySubtitle(String email) {
    return 'Enter the 6-digit code we sent to $email';
  }

  @override
  String get consumerVerifyButton => 'Verify and continue';

  @override
  String get consumerResendCode => 'Send a new code';

  @override
  String consumerResendIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get consumerCodeSent => 'A new code has been sent to your email';

  @override
  String get consumerForgotTitle => 'Reset your password';

  @override
  String get consumerForgotSubtitle =>
      'Enter your email or mobile number and we\'ll email you a code.';

  @override
  String get consumerSendCode => 'Send code';

  @override
  String get consumerResetButton => 'Reset password';

  @override
  String get consumerPasswordResetDone => 'Password changed. Please sign in.';

  @override
  String get consumerErrEmailTaken =>
      'An account with this email already exists. Please sign in.';

  @override
  String get consumerErrMobileTaken =>
      'This mobile number is already registered.';

  @override
  String get consumerErrPasswordPolicy =>
      'Password must have at least 8 characters, with an uppercase letter, a lowercase letter, a number and a symbol.';

  @override
  String get consumerErrLoginDenied => 'Incorrect email/mobile or password.';

  @override
  String get consumerErrNotVerified => 'Please verify your email first.';

  @override
  String get consumerErrCodeInvalid => 'The code is incorrect or has expired.';

  @override
  String get consumerErrTooManyAttempts =>
      'Too many tries. Please wait a while and try again.';

  @override
  String get consumerErrEmailDelivery =>
      'We couldn\'t send the email right now. Please try again.';

  @override
  String get consumerErrNetwork =>
      'Unable to reach the server. Check your internet connection.';

  @override
  String get consumerErrSession =>
      'Your session has expired. Please sign in again.';

  @override
  String get consumerErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get consumerFullNameRequired => 'Enter your full name';

  @override
  String get consumerIdentifierRequired => 'Enter your email or mobile number';

  @override
  String get consumerAddressTitleNew => 'Add your address';

  @override
  String get consumerAddressTitleEdit => 'Edit address';

  @override
  String get consumerAddressRequiredNote =>
      'We need your address to show shops near you.';

  @override
  String get consumerUseCurrentLocation => 'Use my current location';

  @override
  String get consumerLocating => 'Finding your location…';

  @override
  String get consumerLocationPinned => 'Location pinned';

  @override
  String get consumerLocationNeeded =>
      'Tap “Use my current location” to pin your address.';

  @override
  String get consumerLocationOff =>
      'Location is turned off. Turn it on to pin your address.';

  @override
  String get consumerLocationDenied =>
      'Location permission is needed to pin your address.';

  @override
  String get consumerLocationUnavailable =>
      'Couldn\'t get your location. Please try again.';

  @override
  String get consumerOpenSettings => 'Open settings';

  @override
  String get consumerSaveAs => 'Save as';

  @override
  String get addressLabelHome => 'Home';

  @override
  String get addressLabelWork => 'Work';

  @override
  String get addressLabelOther => 'Other';

  @override
  String get consumerHouseFlat => 'House / flat / floor';

  @override
  String get consumerStreetArea => 'Street, area or locality';

  @override
  String get consumerLandmark => 'Landmark (optional)';

  @override
  String get consumerState => 'State';

  @override
  String get consumerPincode => 'PIN code';

  @override
  String get consumerInvalidPincode => 'Enter a valid 6-digit PIN code';

  @override
  String get consumerContactName => 'Contact name';

  @override
  String get consumerContactPhone => 'Contact phone';

  @override
  String get consumerMakeDefault => 'Make this my default address';

  @override
  String get consumerSaveAddress => 'Save address';

  @override
  String get consumerAddresses => 'My addresses';

  @override
  String get consumerAddAddress => 'Add new address';

  @override
  String get consumerDefault => 'Default';

  @override
  String get consumerSetDefault => 'Set as default';

  @override
  String get consumerEdit => 'Edit';

  @override
  String get consumerDelete => 'Delete';

  @override
  String get consumerDeleteAddressConfirm => 'Delete this address?';

  @override
  String get consumerCannotDeleteLastAddress =>
      'You need at least one address. Add another before deleting this one.';

  @override
  String get consumerTabShops => 'Shops';

  @override
  String get consumerTabRequests => 'My requests';

  @override
  String get consumerTabAccount => 'Account';

  @override
  String get consumerShowingNear => 'Shops near';

  @override
  String get consumerCurrentLocation => 'Current location';

  @override
  String get consumerChooseLocation => 'Search shops near…';

  @override
  String get consumerSearchShops => 'Search by shop name';

  @override
  String get consumerFilterAll => 'All';

  @override
  String get consumerFilterOpenNow => 'Open now';

  @override
  String get modeVisitShop => 'Visit shop';

  @override
  String get modeHomeService => 'Home service';

  @override
  String get modePickupDrop => 'Pickup & drop';

  @override
  String consumerDistanceKm(String km) {
    return '$km km';
  }

  @override
  String consumerWithinKm(int km) {
    return 'Within $km km';
  }

  @override
  String get consumerOpenNow => 'Open now';

  @override
  String get consumerClosedNow => 'Closed now';

  @override
  String consumerTodayHours(String open, String close) {
    return 'Today $open – $close';
  }

  @override
  String get consumerClosedToday => 'Closed today';

  @override
  String get consumerCall => 'Call';

  @override
  String get consumerBook => 'Book';

  @override
  String get consumerDirections => 'Directions';

  @override
  String get consumerServesYou => 'Comes to your area';

  @override
  String get consumerNoShopsTitle => 'No shops found nearby';

  @override
  String get consumerNoShopsMessage =>
      'Try another category, remove filters or search a bigger distance.';

  @override
  String get consumerCouldNotOpen => 'Couldn\'t open the app for this action';

  @override
  String get consumerAbout => 'About';

  @override
  String get consumerServices => 'Services';

  @override
  String get consumerHowTheyServe => 'How they serve';

  @override
  String consumerTravelsUpTo(int km) {
    return 'Comes to you within $km km';
  }

  @override
  String get consumerOpeningHours => 'Opening hours';

  @override
  String get consumerClosed => 'Closed';

  @override
  String get consumerAddressHeading => 'Address';

  @override
  String get consumerBookService => 'Book a service';

  @override
  String consumerBookTitle(String shop) {
    return 'Book at $shop';
  }

  @override
  String get consumerWhatService => 'What do you need?';

  @override
  String get consumerHowServed => 'How would you like it?';

  @override
  String get consumerWhen => 'When?';

  @override
  String get consumerPickDate => 'Pick a date';

  @override
  String get consumerTimeFrom => 'From';

  @override
  String get consumerTimeTo => 'To';

  @override
  String get consumerYourAddress => 'Your address';

  @override
  String get consumerDescribe => 'Describe what you need';

  @override
  String get consumerDescribeHint =>
      'e.g. Wash and iron 5 shirts, 2 bedsheets have stains';

  @override
  String get consumerItemsOptional => 'Items (optional)';

  @override
  String get consumerAddItem => 'Add item';

  @override
  String get consumerItemName => 'Item';

  @override
  String get consumerQty => 'Qty';

  @override
  String get consumerSendRequest => 'Send request';

  @override
  String get consumerRequestSentTitle => 'Request sent!';

  @override
  String consumerRequestSentMessage(String shop) {
    return '$shop will reply within 48 hours. You can follow it in My requests.';
  }

  @override
  String get consumerShopClosedThatDay =>
      'The shop is closed on that day. Please pick another date.';

  @override
  String get consumerSlotInvalid =>
      'The end time must be after the start time.';

  @override
  String get consumerDescribeMore =>
      'Please describe what you need (at least 5 characters).';

  @override
  String get consumerChooseAddress =>
      'Choose the address for home service or pickup.';

  @override
  String consumerOutsideArea(int km) {
    return 'This shop comes up to $km km away; your address is farther.';
  }

  @override
  String get requestStatusPending => 'Waiting';

  @override
  String get requestStatusAccepted => 'Accepted';

  @override
  String get requestStatusDeclined => 'Declined';

  @override
  String get requestStatusCancelled => 'Cancelled';

  @override
  String get requestStatusExpired => 'No reply';

  @override
  String get requestStatusCompleted => 'Completed';

  @override
  String get consumerNoRequestsTitle => 'No requests yet';

  @override
  String get consumerNoRequestsMessage =>
      'Find a shop and book a service — your requests show up here.';

  @override
  String get consumerRequestDetails => 'Request details';

  @override
  String get consumerPreferredTime => 'Preferred time';

  @override
  String get consumerConfirmedTime => 'Confirmed time';

  @override
  String get consumerShopMessage => 'Message from the shop';

  @override
  String get consumerReason => 'Reason';

  @override
  String consumerOrderCreated(String number) {
    return 'Order $number created';
  }

  @override
  String consumerReplyBy(String time) {
    return 'The shop has until $time to reply';
  }

  @override
  String get consumerCancelRequest => 'Cancel request';

  @override
  String get consumerCancelConfirm => 'Cancel this request?';

  @override
  String get consumerCancelReasonHint => 'Reason (optional)';

  @override
  String get consumerKeepRequest => 'Keep it';

  @override
  String get consumerHistory => 'History';

  @override
  String get consumerByYou => 'You';

  @override
  String get consumerByShop => 'Shop';

  @override
  String get consumerByAutomatic => 'Automatic';

  @override
  String get consumerCallShop => 'Call shop';

  @override
  String get consumerItems => 'Items';

  @override
  String get consumerAccountTitle => 'My account';

  @override
  String get consumerSignOutConfirm => 'Sign out of your account?';

  @override
  String get shopListingTitle => 'Shop listing';

  @override
  String get shopListingMenuSubtitle =>
      'Address, booking phone and hours customers see';

  @override
  String get shopListingVisible => 'Customers can find your shop';

  @override
  String get shopListingHiddenIncomplete =>
      'Hidden from customers — add the missing details below';

  @override
  String get shopListingHiddenUnlisted =>
      'Hidden from customers — you switched the listing off';

  @override
  String get shopListingHiddenInactive =>
      'Hidden from customers — your business account is not active';

  @override
  String get shopListingShowToCustomers => 'Show my shop to customers';

  @override
  String get shopListingAddressSection => 'Shop address';

  @override
  String get shopListingPinShop => 'Pin shop location';

  @override
  String get shopListingPinHint =>
      'Stand inside your shop and tap “Pin shop location”. Customers see distance from this point.';

  @override
  String get shopListingStreet => 'Shop no., building, street';

  @override
  String get shopListingArea => 'Area / locality';

  @override
  String get shopListingBookingPhone => 'Booking phone (shown to customers)';

  @override
  String shopListingBookingPhoneHint(String phone) {
    return 'Leave empty to use your phone: $phone';
  }

  @override
  String get shopListingInvalidPhone =>
      'Enter a 10-digit mobile or a landline with STD code';

  @override
  String get shopListingHowServe => 'How you serve customers';

  @override
  String get shopListingChooseMode => 'Choose at least one';

  @override
  String shopListingRadius(int km) {
    return 'You travel up to $km km for home service and pickup';
  }

  @override
  String get shopListingHours => 'Opening hours';

  @override
  String get shopListingOpen => 'Open';

  @override
  String get shopListingClosed => 'Closed';

  @override
  String get shopListingNeedOpenDay =>
      'The shop must be open on at least one day';

  @override
  String get shopListingAbout => 'About your shop (optional)';

  @override
  String get shopListingAboutHint =>
      'e.g. Same-day ironing, free pickup above ₹300';

  @override
  String get shopListingSave => 'Save listing';

  @override
  String get shopListingSaved => 'Listing saved';

  @override
  String get shopListingNeedPin => 'Pin your shop location first';

  @override
  String get shopListingNoPermission =>
      'Only the owner or a branch manager can change the shop listing.';

  @override
  String get shopAddressPromptTitle => 'Add your shop address';

  @override
  String get shopAddressPromptBody =>
      'Customers near you can find and book your shop once you add your address and location.';

  @override
  String get shopAddressPromptAction => 'Add address';

  @override
  String get shopAddressPromptLater => 'Later';

  @override
  String get onlineRequestsTitle => 'Online requests';

  @override
  String get onlineRequestsCardSubtitle => 'Bookings from customers on the app';

  @override
  String onlineRequestsWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get onlineRequestsNoneWaiting => 'No new requests';

  @override
  String get onlineRequestsEmptyTitle => 'No requests here';

  @override
  String get onlineRequestsEmptyMessage =>
      'Requests from customers appear here. Keep your shop listing complete so customers can find you.';

  @override
  String get onlineRequestCustomer => 'Customer';

  @override
  String get onlineRequestAccept => 'Accept';

  @override
  String get onlineRequestDecline => 'Decline';

  @override
  String get onlineRequestCreateOrder => 'Create order';

  @override
  String get onlineRequestComplete => 'Mark completed';

  @override
  String get onlineRequestAcceptTitle => 'Accept request';

  @override
  String get onlineRequestConfirmTime => 'Confirmed date and time';

  @override
  String get onlineRequestNoteHint => 'Message to the customer (optional)';

  @override
  String get onlineRequestDeclineTitle => 'Decline request';

  @override
  String get onlineRequestDeclineHint => 'Reason (the customer will see this)';

  @override
  String get onlineRequestDeclineNeedReason => 'Please give a reason';

  @override
  String get onlineRequestCompleteTitle => 'Mark as completed?';

  @override
  String get onlineRequestAccepted => 'Request accepted';

  @override
  String get onlineRequestDeclined => 'Request declined';

  @override
  String get onlineRequestCompleted => 'Request completed';

  @override
  String onlineRequestOrderLinked(String number) {
    return 'Order $number created and linked';
  }

  @override
  String get onlineRequestOrderNotLinked =>
      'The order was created but could not be linked to this request. Open the request again to retry.';

  @override
  String get onlineRequestOnlineBadge => 'Online';

  @override
  String onlineRequestReceived(String time) {
    return 'Received $time';
  }

  @override
  String onlineRequestExpiresAt(String time) {
    return 'Reply before $time or it expires';
  }

  @override
  String get onlineRequestCallCustomer => 'Call customer';

  @override
  String onlineRequestDistance(String km) {
    return '$km km from your shop';
  }

  @override
  String get onlineRequestStaffCannotCreate =>
      'Ask the owner or a manager to create the order.';

  @override
  String get pickupWorkerLabel => 'Who will go and collect it?';

  @override
  String get pickupChooseWorker => 'Choose a worker';

  @override
  String get pickupNoWorkers =>
      'No workers found for this branch. Add a worker in Staff first.';

  @override
  String get pickupWorkerRequired => 'Choose the worker who will collect';

  @override
  String get pickupChangeWorker => 'Change worker';

  @override
  String pickupBy(String name) {
    return 'Pickup by $name';
  }

  @override
  String get pickupCollectTitle => 'Record the pickup';

  @override
  String get pickupCollectAction => 'Collected';

  @override
  String get pickupItemsHeading => 'What did you collect?';

  @override
  String get pickupItemName => 'Item (e.g. Shirt)';

  @override
  String get pickupItemQty => 'Qty';

  @override
  String get pickupAddItem => 'Add item';

  @override
  String get pickupNeedItem => 'Add at least one item with a quantity';

  @override
  String get pickupDeliveryDate => 'Delivery date';

  @override
  String pickupAutoDate(String date) {
    return 'Automatic: $date';
  }

  @override
  String get pickupCustomDate => 'Pick another date';

  @override
  String get pickupBackToAuto => 'Use the automatic date';

  @override
  String get pickupCollectedToast =>
      'Pickup recorded. The customer has been told the delivery date.';

  @override
  String pickupDeliveryOn(String date) {
    return 'Delivery on $date';
  }

  @override
  String get pickupCollectedItems => 'Collected items';

  @override
  String get pickupPhotosHeading => 'Photos at pickup';

  @override
  String get pickupTakePhoto => 'Take photo';

  @override
  String get pickupPhotoLimit => 'Up to 6 photos';

  @override
  String get pickupUploading => 'Uploading photos…';

  @override
  String get pickupPhotosTitle => 'Photos taken at pickup';

  @override
  String get shopListingModesHint =>
      'Tap to switch each one on or off. You can change this any time and save again.';

  @override
  String get pickupTotalItems => 'Total items (optional)';

  @override
  String pickupTotalItemsLine(int count) {
    return 'Total items: $count';
  }

  @override
  String get pickupCollectAndCreate => 'Collected, create order';
}
