import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from your profile.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get commonSkipForNow;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get commonPhone;

  /// No description provided for @commonLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get commonLocation;

  /// No description provided for @commonBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get commonBusiness;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonRequiredInformation.
  ///
  /// In en, this message translates to:
  /// **'Required information'**
  String get commonRequiredInformation;

  /// No description provided for @commonConnectionProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get commonConnectionProblem;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonUnableToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get commonUnableToSignIn;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(String field);

  /// No description provided for @stepFraction.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String stepFraction(int current, int total);

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your business account'**
  String get loginSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createBusinessAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Business Account'**
  String get createBusinessAccount;

  /// No description provided for @companyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Company Admin'**
  String get companyAdmin;

  /// No description provided for @termsAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to our '**
  String get termsAgreementPrefix;

  /// No description provided for @termsAgreementSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get termsAgreementSuffix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @loginMissingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue.'**
  String get loginMissingCredentials;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginInvalidCredentials;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Business Management Platform'**
  String get splashTagline;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @backToLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLoginTooltip;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @forgotPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordHeading;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a 6-digit verification code to reset your password.'**
  String get forgotPasswordBody;

  /// No description provided for @sendingCode.
  ///
  /// In en, this message translates to:
  /// **'Sending code...'**
  String get sendingCode;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get sendVerificationCode;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'If the account is eligible, a verification code has been sent to {email}. Follow the instructions to reset your password.'**
  String codeSentTo(String email);

  /// No description provided for @codeSentGeneric.
  ///
  /// In en, this message translates to:
  /// **'If the account is eligible, a verification code has been sent.'**
  String get codeSentGeneric;

  /// No description provided for @enterEmailToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to continue.'**
  String get enterEmailToContinue;

  /// No description provided for @unableToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Unable to send verification code. Please try again.'**
  String get unableToSendCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code sent to your email and your new password.'**
  String get resetPasswordBody;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-Digit Verification Code'**
  String get verificationCodeLabel;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Resetting password...'**
  String get resettingPassword;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code sent to your email.'**
  String get enterSixDigitCode;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully. Please sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password. Please verify your code and try again.'**
  String get passwordResetFailed;

  /// No description provided for @passwordPolicyHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with an uppercase letter, a lowercase letter, a number and a special character.'**
  String get passwordPolicyHint;

  /// No description provided for @passwordRuleMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleMinLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'An uppercase letter (A–Z)'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'A lowercase letter (a–z)'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'A number (0–9)'**
  String get passwordRuleNumber;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In en, this message translates to:
  /// **'A special character (e.g. ! @ # \$)'**
  String get passwordRuleSpecial;

  /// No description provided for @passwordNeeds.
  ///
  /// In en, this message translates to:
  /// **'Password needs: {rule}.'**
  String passwordNeeds(String rule);

  /// No description provided for @businessInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get businessInfoTitle;

  /// No description provided for @businessInfoHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get businessInfoHeading;

  /// No description provided for @businessInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us personalize your experience.'**
  String get businessInfoSubtitle;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Laundry & Cleaners'**
  String get businessNameHint;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get nameTooShort;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameHint;

  /// No description provided for @ownerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Owner name is required'**
  String get ownerNameRequired;

  /// No description provided for @selectBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Please select a business type'**
  String get selectBusinessType;

  /// No description provided for @businessSummaryIntro.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a summary of your business. You can update these later in Settings.'**
  String get businessSummaryIntro;

  /// No description provided for @businessTypeLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get businessTypeLaundry;

  /// No description provided for @businessTypeDryCleaning.
  ///
  /// In en, this message translates to:
  /// **'Dry Cleaning'**
  String get businessTypeDryCleaning;

  /// No description provided for @businessTypeTailoring.
  ///
  /// In en, this message translates to:
  /// **'Tailoring'**
  String get businessTypeTailoring;

  /// No description provided for @businessTypeShoeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Shoe Cleaning'**
  String get businessTypeShoeCleaning;

  /// No description provided for @businessTypeApplianceRepair.
  ///
  /// In en, this message translates to:
  /// **'Appliance Repair'**
  String get businessTypeApplianceRepair;

  /// No description provided for @businessTypeMobileRepair.
  ///
  /// In en, this message translates to:
  /// **'Mobile Repair'**
  String get businessTypeMobileRepair;

  /// No description provided for @businessTypeVehicleWash.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Wash'**
  String get businessTypeVehicleWash;

  /// No description provided for @businessTypeSalon.
  ///
  /// In en, this message translates to:
  /// **'Salon'**
  String get businessTypeSalon;

  /// No description provided for @businessTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get businessTypeGeneral;

  /// No description provided for @businessTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get businessTypeCustom;

  /// No description provided for @serviceWashAndFold.
  ///
  /// In en, this message translates to:
  /// **'Wash & Fold'**
  String get serviceWashAndFold;

  /// No description provided for @accountDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetailsTitle;

  /// No description provided for @createAccountHeading.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountHeading;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use these to sign in.'**
  String get createAccountSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @passwordMinHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordMinHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordMin8;

  /// No description provided for @passwordNeedsUppercase.
  ///
  /// In en, this message translates to:
  /// **'Must contain an uppercase letter'**
  String get passwordNeedsUppercase;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Must contain a number'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordNeedsSpecial.
  ///
  /// In en, this message translates to:
  /// **'Must contain a special character'**
  String get passwordNeedsSpecial;

  /// No description provided for @agreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreePrefix;

  /// No description provided for @agreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get agreeAnd;

  /// No description provided for @agreeSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get agreeSuffix;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registrationFillHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the highlighted fields — email, phone number and password are required.'**
  String get registrationFillHighlighted;

  /// No description provided for @mustAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Service.'**
  String get mustAgreeTerms;

  /// No description provided for @alreadyRegisteredAdvice.
  ///
  /// In en, this message translates to:
  /// **'{message}. Log in with that account instead (use \"Forgot password?\" if needed), or use a different one.'**
  String alreadyRegisteredAdvice(String message);

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete registration. Please try again.'**
  String get registrationFailed;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreatedTitle;

  /// No description provided for @accountCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your business account is ready.\nLet\'s set up your workspace.'**
  String get accountCreatedBody;

  /// No description provided for @startSetup.
  ///
  /// In en, this message translates to:
  /// **'Start Setup'**
  String get startSetup;

  /// No description provided for @firstBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'First Branch'**
  String get firstBranchTitle;

  /// No description provided for @firstBranchHeading.
  ///
  /// In en, this message translates to:
  /// **'Add your first branch'**
  String get firstBranchHeading;

  /// No description provided for @firstBranchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the location and contact details for your main branch.'**
  String get firstBranchSubtitle;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchName;

  /// No description provided for @mainBranchHint.
  ///
  /// In en, this message translates to:
  /// **'Main Branch'**
  String get mainBranchHint;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddressHint;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @postalCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCodeHint;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmailAddress;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @servicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the services your business offers. You can add more later.'**
  String get servicesSubtitle;

  /// No description provided for @selectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Select at least one service'**
  String get selectAtLeastOneService;

  /// No description provided for @servicesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 service selected} other{{count} services selected}}'**
  String servicesSelected(int count);

  /// No description provided for @inviteStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Staff'**
  String get inviteStaffTitle;

  /// No description provided for @inviteStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite team members to join your workspace. Each person gets an email invitation.'**
  String get inviteStaffSubtitle;

  /// No description provided for @staffEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email *'**
  String get staffEmailLabel;

  /// No description provided for @staffEmailNumberedLabel.
  ///
  /// In en, this message translates to:
  /// **'Email {number} *'**
  String staffEmailNumberedLabel(int number);

  /// No description provided for @staffMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number (Optional)'**
  String get staffMobileLabel;

  /// No description provided for @staffMobileNumberedLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number {number} (Optional)'**
  String staffMobileNumberedLabel(int number);

  /// No description provided for @emailRequiredForInvite.
  ///
  /// In en, this message translates to:
  /// **'Email is required to send the invitation'**
  String get emailRequiredForInvite;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @emailEnteredTwice.
  ///
  /// In en, this message translates to:
  /// **'This email is entered twice'**
  String get emailEnteredTwice;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get invalidMobile;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another'**
  String get addAnother;

  /// No description provided for @inviteStaffNote.
  ///
  /// In en, this message translates to:
  /// **'Each staff member gets an email with their login ID (their email). They set their own password by tapping \"Forgot password?\" in the app. You can add more staff later from the Staff screen.'**
  String get inviteStaffNote;

  /// No description provided for @inviteFixHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields. Each staff member needs an email address — the invitation is sent by email.'**
  String get inviteFixHighlighted;

  /// No description provided for @invitationsSent.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent'**
  String get invitationsSent;

  /// No description provided for @invitationsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Some invitations need attention'**
  String get invitationsNeedAttention;

  /// No description provided for @inviteReportAllSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {emails}. They\'ll set their own password using \"Forgot password?\" in the app.'**
  String inviteReportAllSent(String emails);

  /// No description provided for @inviteReportInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited: {emails}.'**
  String inviteReportInvited(String emails);

  /// No description provided for @inviteReportEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'{email} — account created, but the email could not be sent. Ask them to open the app and tap \"Forgot password?\".'**
  String inviteReportEmailFailed(String email);

  /// No description provided for @inviteReportFailed.
  ///
  /// In en, this message translates to:
  /// **'{email} — {reason}'**
  String inviteReportFailed(String email, String reason);

  /// No description provided for @inviteReportCouldNotInvite.
  ///
  /// In en, this message translates to:
  /// **'could not be invited'**
  String get inviteReportCouldNotInvite;

  /// No description provided for @inviteReportFooter.
  ///
  /// In en, this message translates to:
  /// **'You can add or re-invite staff later from the Staff screen.'**
  String get inviteReportFooter;

  /// No description provided for @unableToSaveOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Unable to save onboarding. Please try again.'**
  String get unableToSaveOnboarding;

  /// No description provided for @allSetTitle.
  ///
  /// In en, this message translates to:
  /// **'All Set!'**
  String get allSetTitle;

  /// No description provided for @allSetHeading.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get allSetHeading;

  /// No description provided for @allSetBody.
  ///
  /// In en, this message translates to:
  /// **'Your workspace is configured and ready. Start adding orders and managing your business.'**
  String get allSetBody;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @branchCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String branchCreated(String name);

  /// No description provided for @branchNotCreated.
  ///
  /// In en, this message translates to:
  /// **'Branch not created'**
  String get branchNotCreated;

  /// No description provided for @servicesConfigured.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 service configured} other{{count} services configured}}'**
  String servicesConfigured(int count);

  /// No description provided for @servicesNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Services not configured'**
  String get servicesNotConfigured;

  /// No description provided for @staffInvitationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Staff invitation skipped'**
  String get staffInvitationSkipped;

  /// No description provided for @staffInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 staff invitation sent} other{{count} staff invitations sent}}'**
  String staffInvitationsSent(int count);

  /// No description provided for @choosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get choosePlanTitle;

  /// No description provided for @choosePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a plan to activate your workspace. You can change this anytime.'**
  String get choosePlanSubtitle;

  /// No description provided for @unableToLoadPlans.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans. Please try again.'**
  String get unableToLoadPlans;

  /// No description provided for @unableToSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'Unable to select this plan. Please try again.'**
  String get unableToSelectPlan;

  /// No description provided for @noPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlansTitle;

  /// No description provided for @noPlansMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no active subscription plans configured yet.'**
  String get noPlansMessage;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get billingAnnual;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **' / year'**
  String get perYear;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **' / month'**
  String get perMonth;

  /// No description provided for @freeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String freeTrialDays(int days);

  /// No description provided for @planLimits.
  ///
  /// In en, this message translates to:
  /// **'Up to {branches} branches · {staff} staff · {orders} orders/mo'**
  String planLimits(int branches, int staff, int orders);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTooltip;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get personalInformation;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get securitySection;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferencesSection;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @lastChanged.
  ///
  /// In en, this message translates to:
  /// **'Last changed {when}'**
  String lastChanged(String when);

  /// No description provided for @accountCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Created'**
  String get accountCreatedLabel;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @roleSwitch.
  ///
  /// In en, this message translates to:
  /// **'ROLE SWITCH'**
  String get roleSwitch;

  /// No description provided for @roleSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — switch dashboard view'**
  String get roleSwitchSubtitle;

  /// No description provided for @roleOwnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Full access to all features'**
  String get roleOwnerDescription;

  /// No description provided for @roleBranchManager.
  ///
  /// In en, this message translates to:
  /// **'Branch Manager'**
  String get roleBranchManager;

  /// No description provided for @roleBranchManagerDescription.
  ///
  /// In en, this message translates to:
  /// **'Branch operations & staff'**
  String get roleBranchManagerDescription;

  /// No description provided for @roleStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Staff Member'**
  String get roleStaffMember;

  /// No description provided for @roleStaffMemberDescription.
  ///
  /// In en, this message translates to:
  /// **'Assigned orders only'**
  String get roleStaffMemberDescription;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @enterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhone;

  /// No description provided for @enterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get enterBusinessName;

  /// No description provided for @enterLocationCityBranch.
  ///
  /// In en, this message translates to:
  /// **'Enter your location (City/Branch)'**
  String get enterLocationCityBranch;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter your location'**
  String get enterLocation;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @fixHighlightedBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields before saving.'**
  String get fixHighlightedBeforeSaving;

  /// No description provided for @changePasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password, then choose a new one.'**
  String get changePasswordIntro;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get enterCurrentPassword;

  /// No description provided for @newPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get newPasswordsDoNotMatch;

  /// No description provided for @newPasswordMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get newPasswordMustDiffer;

  /// No description provided for @unableToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Unable to change the password. Please try again.'**
  String get unableToChangePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @passwordChangedBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed and your other devices were signed out. Please sign in again with your new password.'**
  String get passwordChangedBody;

  /// No description provided for @changingPassword.
  ///
  /// In en, this message translates to:
  /// **'Changing password...'**
  String get changingPassword;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to use Nexoraa?'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one — you can switch any time.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'I need a service'**
  String get welcomeCustomerTitle;

  /// No description provided for @welcomeCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find laundry, repair, salon and more near you'**
  String get welcomeCustomerSubtitle;

  /// No description provided for @welcomeBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'I run a business'**
  String get welcomeBusinessTitle;

  /// No description provided for @welcomeBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage orders, staff and payments for your shop'**
  String get welcomeBusinessSubtitle;

  /// No description provided for @consumerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get consumerLoginTitle;

  /// No description provided for @consumerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find services near you'**
  String get consumerLoginSubtitle;

  /// No description provided for @consumerIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get consumerIdentifierLabel;

  /// No description provided for @consumerNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get consumerNewHere;

  /// No description provided for @consumerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get consumerCreateAccount;

  /// No description provided for @consumerBusinessLink.
  ///
  /// In en, this message translates to:
  /// **'Run a business? Sign in here'**
  String get consumerBusinessLink;

  /// No description provided for @consumerSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get consumerSignupTitle;

  /// No description provided for @consumerSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s free. We\'ll email you a code to verify.'**
  String get consumerSignupSubtitle;

  /// No description provided for @consumerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get consumerFullName;

  /// No description provided for @consumerMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get consumerMobileNumber;

  /// No description provided for @consumerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get consumerConfirmPassword;

  /// No description provided for @consumerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get consumerHaveAccount;

  /// No description provided for @consumerVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get consumerVerifyTitle;

  /// No description provided for @consumerVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {email}'**
  String consumerVerifySubtitle(String email);

  /// No description provided for @consumerVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get consumerVerifyButton;

  /// No description provided for @consumerResendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get consumerResendCode;

  /// No description provided for @consumerResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String consumerResendIn(int seconds);

  /// No description provided for @consumerCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent to your email'**
  String get consumerCodeSent;

  /// No description provided for @consumerForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get consumerForgotTitle;

  /// No description provided for @consumerForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number and we\'ll email you a code.'**
  String get consumerForgotSubtitle;

  /// No description provided for @consumerSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get consumerSendCode;

  /// No description provided for @consumerResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get consumerResetButton;

  /// No description provided for @consumerPasswordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Please sign in.'**
  String get consumerPasswordResetDone;

  /// No description provided for @consumerErrEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please sign in.'**
  String get consumerErrEmailTaken;

  /// No description provided for @consumerErrMobileTaken.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already registered.'**
  String get consumerErrMobileTaken;

  /// No description provided for @consumerErrPasswordPolicy.
  ///
  /// In en, this message translates to:
  /// **'Password must have at least 8 characters, with an uppercase letter, a lowercase letter, a number and a symbol.'**
  String get consumerErrPasswordPolicy;

  /// No description provided for @consumerErrLoginDenied.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email/mobile or password.'**
  String get consumerErrLoginDenied;

  /// No description provided for @consumerErrNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first.'**
  String get consumerErrNotVerified;

  /// No description provided for @consumerErrCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect or has expired.'**
  String get consumerErrCodeInvalid;

  /// No description provided for @consumerErrTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Please wait a while and try again.'**
  String get consumerErrTooManyAttempts;

  /// No description provided for @consumerErrEmailDelivery.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the email right now. Please try again.'**
  String get consumerErrEmailDelivery;

  /// No description provided for @consumerErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server. Check your internet connection.'**
  String get consumerErrNetwork;

  /// No description provided for @consumerErrSession.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get consumerErrSession;

  /// No description provided for @consumerErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get consumerErrGeneric;

  /// No description provided for @consumerFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get consumerFullNameRequired;

  /// No description provided for @consumerIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number'**
  String get consumerIdentifierRequired;

  /// No description provided for @consumerAddressTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add your address'**
  String get consumerAddressTitleNew;

  /// No description provided for @consumerAddressTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get consumerAddressTitleEdit;

  /// No description provided for @consumerAddressRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'We need your address to show shops near you.'**
  String get consumerAddressRequiredNote;

  /// No description provided for @consumerUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get consumerUseCurrentLocation;

  /// No description provided for @consumerLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get consumerLocating;

  /// No description provided for @consumerLocationPinned.
  ///
  /// In en, this message translates to:
  /// **'Location pinned'**
  String get consumerLocationPinned;

  /// No description provided for @consumerLocationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Tap “Use my current location” to pin your address.'**
  String get consumerLocationNeeded;

  /// No description provided for @consumerLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off. Turn it on to pin your address.'**
  String get consumerLocationOff;

  /// No description provided for @consumerLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to pin your address.'**
  String get consumerLocationDenied;

  /// No description provided for @consumerLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Please try again.'**
  String get consumerLocationUnavailable;

  /// No description provided for @consumerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get consumerOpenSettings;

  /// No description provided for @consumerSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get consumerSaveAs;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressLabelWork;

  /// No description provided for @addressLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// No description provided for @consumerHouseFlat.
  ///
  /// In en, this message translates to:
  /// **'House / flat / floor'**
  String get consumerHouseFlat;

  /// No description provided for @consumerStreetArea.
  ///
  /// In en, this message translates to:
  /// **'Street, area or locality'**
  String get consumerStreetArea;

  /// No description provided for @consumerLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get consumerLandmark;

  /// No description provided for @consumerState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get consumerState;

  /// No description provided for @consumerPincode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get consumerPincode;

  /// No description provided for @consumerInvalidPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit PIN code'**
  String get consumerInvalidPincode;

  /// No description provided for @consumerContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get consumerContactName;

  /// No description provided for @consumerContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get consumerContactPhone;

  /// No description provided for @consumerMakeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make this my default address'**
  String get consumerMakeDefault;

  /// No description provided for @consumerSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get consumerSaveAddress;

  /// No description provided for @consumerAddresses.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get consumerAddresses;

  /// No description provided for @consumerAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get consumerAddAddress;

  /// No description provided for @consumerDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get consumerDefault;

  /// No description provided for @consumerSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get consumerSetDefault;

  /// No description provided for @consumerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get consumerEdit;

  /// No description provided for @consumerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get consumerDelete;

  /// No description provided for @consumerDeleteAddressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get consumerDeleteAddressConfirm;

  /// No description provided for @consumerCannotDeleteLastAddress.
  ///
  /// In en, this message translates to:
  /// **'You need at least one address. Add another before deleting this one.'**
  String get consumerCannotDeleteLastAddress;

  /// No description provided for @consumerTabShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get consumerTabShops;

  /// No description provided for @consumerTabRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get consumerTabRequests;

  /// No description provided for @consumerTabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get consumerTabAccount;

  /// No description provided for @consumerShowingNear.
  ///
  /// In en, this message translates to:
  /// **'Shops near'**
  String get consumerShowingNear;

  /// No description provided for @consumerCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get consumerCurrentLocation;

  /// No description provided for @consumerChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Search shops near…'**
  String get consumerChooseLocation;

  /// No description provided for @consumerSearchShops.
  ///
  /// In en, this message translates to:
  /// **'Search by shop name'**
  String get consumerSearchShops;

  /// No description provided for @consumerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get consumerFilterAll;

  /// No description provided for @consumerFilterOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get consumerFilterOpenNow;

  /// No description provided for @modeVisitShop.
  ///
  /// In en, this message translates to:
  /// **'Visit shop'**
  String get modeVisitShop;

  /// No description provided for @modeHomeService.
  ///
  /// In en, this message translates to:
  /// **'Home service'**
  String get modeHomeService;

  /// No description provided for @modePickupDrop.
  ///
  /// In en, this message translates to:
  /// **'Pickup & drop'**
  String get modePickupDrop;

  /// No description provided for @consumerDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String consumerDistanceKm(String km);

  /// No description provided for @consumerWithinKm.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String consumerWithinKm(int km);

  /// No description provided for @consumerOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get consumerOpenNow;

  /// No description provided for @consumerClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed now'**
  String get consumerClosedNow;

  /// No description provided for @consumerTodayHours.
  ///
  /// In en, this message translates to:
  /// **'Today {open} – {close}'**
  String consumerTodayHours(String open, String close);

  /// No description provided for @consumerClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today'**
  String get consumerClosedToday;

  /// No description provided for @consumerCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get consumerCall;

  /// No description provided for @consumerBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get consumerBook;

  /// No description provided for @consumerDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get consumerDirections;

  /// No description provided for @consumerServesYou.
  ///
  /// In en, this message translates to:
  /// **'Comes to your area'**
  String get consumerServesYou;

  /// No description provided for @consumerNoShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'No shops found nearby'**
  String get consumerNoShopsTitle;

  /// No description provided for @consumerNoShopsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another category, remove filters or search a bigger distance.'**
  String get consumerNoShopsMessage;

  /// No description provided for @consumerCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the app for this action'**
  String get consumerCouldNotOpen;

  /// No description provided for @consumerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get consumerAbout;

  /// No description provided for @consumerServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get consumerServices;

  /// No description provided for @consumerHowTheyServe.
  ///
  /// In en, this message translates to:
  /// **'How they serve'**
  String get consumerHowTheyServe;

  /// No description provided for @consumerTravelsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Comes to you within {km} km'**
  String consumerTravelsUpTo(int km);

  /// No description provided for @consumerOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get consumerOpeningHours;

  /// No description provided for @consumerClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get consumerClosed;

  /// No description provided for @consumerAddressHeading.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get consumerAddressHeading;

  /// No description provided for @consumerBookService.
  ///
  /// In en, this message translates to:
  /// **'Book a service'**
  String get consumerBookService;

  /// No description provided for @consumerBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book at {shop}'**
  String consumerBookTitle(String shop);

  /// No description provided for @consumerWhatService.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get consumerWhatService;

  /// No description provided for @consumerHowServed.
  ///
  /// In en, this message translates to:
  /// **'How would you like it?'**
  String get consumerHowServed;

  /// No description provided for @consumerWhen.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get consumerWhen;

  /// No description provided for @consumerPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get consumerPickDate;

  /// No description provided for @consumerTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get consumerTimeFrom;

  /// No description provided for @consumerTimeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get consumerTimeTo;

  /// No description provided for @consumerYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get consumerYourAddress;

  /// No description provided for @consumerDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need'**
  String get consumerDescribe;

  /// No description provided for @consumerDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wash and iron 5 shirts, 2 bedsheets have stains'**
  String get consumerDescribeHint;

  /// No description provided for @consumerItemsOptional.
  ///
  /// In en, this message translates to:
  /// **'Items (optional)'**
  String get consumerItemsOptional;

  /// No description provided for @consumerAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get consumerAddItem;

  /// No description provided for @consumerItemName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get consumerItemName;

  /// No description provided for @consumerQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get consumerQty;

  /// No description provided for @consumerSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get consumerSendRequest;

  /// No description provided for @consumerRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get consumerRequestSentTitle;

  /// No description provided for @consumerRequestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'{shop} will reply within 48 hours. You can follow it in My requests.'**
  String consumerRequestSentMessage(String shop);

  /// No description provided for @consumerShopClosedThatDay.
  ///
  /// In en, this message translates to:
  /// **'The shop is closed on that day. Please pick another date.'**
  String get consumerShopClosedThatDay;

  /// No description provided for @consumerSlotInvalid.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start time.'**
  String get consumerSlotInvalid;

  /// No description provided for @consumerDescribeMore.
  ///
  /// In en, this message translates to:
  /// **'Please describe what you need (at least 5 characters).'**
  String get consumerDescribeMore;

  /// No description provided for @consumerChooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose the address for home service or pickup.'**
  String get consumerChooseAddress;

  /// No description provided for @consumerOutsideArea.
  ///
  /// In en, this message translates to:
  /// **'This shop comes up to {km} km away; your address is farther.'**
  String consumerOutsideArea(int km);

  /// No description provided for @requestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get requestStatusPending;

  /// No description provided for @requestStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get requestStatusAccepted;

  /// No description provided for @requestStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get requestStatusDeclined;

  /// No description provided for @requestStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get requestStatusCancelled;

  /// No description provided for @requestStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'No reply'**
  String get requestStatusExpired;

  /// No description provided for @requestStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get requestStatusCompleted;

  /// No description provided for @consumerNoRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get consumerNoRequestsTitle;

  /// No description provided for @consumerNoRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Find a shop and book a service — your requests show up here.'**
  String get consumerNoRequestsMessage;

  /// No description provided for @consumerRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get consumerRequestDetails;

  /// No description provided for @consumerPreferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get consumerPreferredTime;

  /// No description provided for @consumerConfirmedTime.
  ///
  /// In en, this message translates to:
  /// **'Confirmed time'**
  String get consumerConfirmedTime;

  /// No description provided for @consumerShopMessage.
  ///
  /// In en, this message translates to:
  /// **'Message from the shop'**
  String get consumerShopMessage;

  /// No description provided for @consumerReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get consumerReason;

  /// No description provided for @consumerOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order {number} created'**
  String consumerOrderCreated(String number);

  /// No description provided for @consumerReplyBy.
  ///
  /// In en, this message translates to:
  /// **'The shop has until {time} to reply'**
  String consumerReplyBy(String time);

  /// No description provided for @consumerCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get consumerCancelRequest;

  /// No description provided for @consumerCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get consumerCancelConfirm;

  /// No description provided for @consumerCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get consumerCancelReasonHint;

  /// No description provided for @consumerKeepRequest.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get consumerKeepRequest;

  /// No description provided for @consumerHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get consumerHistory;

  /// No description provided for @consumerByYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get consumerByYou;

  /// No description provided for @consumerByShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get consumerByShop;

  /// No description provided for @consumerByAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get consumerByAutomatic;

  /// No description provided for @consumerCallShop.
  ///
  /// In en, this message translates to:
  /// **'Call shop'**
  String get consumerCallShop;

  /// No description provided for @consumerItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get consumerItems;

  /// No description provided for @consumerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get consumerAccountTitle;

  /// No description provided for @consumerSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account?'**
  String get consumerSignOutConfirm;

  /// No description provided for @shopListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop listing'**
  String get shopListingTitle;

  /// No description provided for @shopListingMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Address, booking phone and hours customers see'**
  String get shopListingMenuSubtitle;

  /// No description provided for @shopListingVisible.
  ///
  /// In en, this message translates to:
  /// **'Customers can find your shop'**
  String get shopListingVisible;

  /// No description provided for @shopListingHiddenIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Hidden from customers — add the missing details below'**
  String get shopListingHiddenIncomplete;

  /// No description provided for @shopListingHiddenUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Hidden from customers — you switched the listing off'**
  String get shopListingHiddenUnlisted;

  /// No description provided for @shopListingHiddenInactive.
  ///
  /// In en, this message translates to:
  /// **'Hidden from customers — your business account is not active'**
  String get shopListingHiddenInactive;

  /// No description provided for @shopListingShowToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Show my shop to customers'**
  String get shopListingShowToCustomers;

  /// No description provided for @shopListingAddressSection.
  ///
  /// In en, this message translates to:
  /// **'Shop address'**
  String get shopListingAddressSection;

  /// No description provided for @shopListingPinShop.
  ///
  /// In en, this message translates to:
  /// **'Pin shop location'**
  String get shopListingPinShop;

  /// No description provided for @shopListingPinHint.
  ///
  /// In en, this message translates to:
  /// **'Stand inside your shop and tap “Pin shop location”. Customers see distance from this point.'**
  String get shopListingPinHint;

  /// No description provided for @shopListingStreet.
  ///
  /// In en, this message translates to:
  /// **'Shop no., building, street'**
  String get shopListingStreet;

  /// No description provided for @shopListingArea.
  ///
  /// In en, this message translates to:
  /// **'Area / locality'**
  String get shopListingArea;

  /// No description provided for @shopListingBookingPhone.
  ///
  /// In en, this message translates to:
  /// **'Booking phone (shown to customers)'**
  String get shopListingBookingPhone;

  /// No description provided for @shopListingBookingPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use your phone: {phone}'**
  String shopListingBookingPhoneHint(String phone);

  /// No description provided for @shopListingInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile or a landline with STD code'**
  String get shopListingInvalidPhone;

  /// No description provided for @shopListingHowServe.
  ///
  /// In en, this message translates to:
  /// **'How you serve customers'**
  String get shopListingHowServe;

  /// No description provided for @shopListingChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one'**
  String get shopListingChooseMode;

  /// No description provided for @shopListingRadius.
  ///
  /// In en, this message translates to:
  /// **'You travel up to {km} km for home service and pickup'**
  String shopListingRadius(int km);

  /// No description provided for @shopListingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get shopListingHours;

  /// No description provided for @shopListingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get shopListingOpen;

  /// No description provided for @shopListingClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get shopListingClosed;

  /// No description provided for @shopListingNeedOpenDay.
  ///
  /// In en, this message translates to:
  /// **'The shop must be open on at least one day'**
  String get shopListingNeedOpenDay;

  /// No description provided for @shopListingAbout.
  ///
  /// In en, this message translates to:
  /// **'About your shop (optional)'**
  String get shopListingAbout;

  /// No description provided for @shopListingAboutHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Same-day ironing, free pickup above ₹300'**
  String get shopListingAboutHint;

  /// No description provided for @shopListingSave.
  ///
  /// In en, this message translates to:
  /// **'Save listing'**
  String get shopListingSave;

  /// No description provided for @shopListingSaved.
  ///
  /// In en, this message translates to:
  /// **'Listing saved'**
  String get shopListingSaved;

  /// No description provided for @shopListingNeedPin.
  ///
  /// In en, this message translates to:
  /// **'Pin your shop location first'**
  String get shopListingNeedPin;

  /// No description provided for @shopListingNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or a branch manager can change the shop listing.'**
  String get shopListingNoPermission;

  /// No description provided for @shopAddressPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your shop address'**
  String get shopAddressPromptTitle;

  /// No description provided for @shopAddressPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Customers near you can find and book your shop once you add your address and location.'**
  String get shopAddressPromptBody;

  /// No description provided for @shopAddressPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get shopAddressPromptAction;

  /// No description provided for @shopAddressPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get shopAddressPromptLater;

  /// No description provided for @onlineRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Online requests'**
  String get onlineRequestsTitle;

  /// No description provided for @onlineRequestsCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings from customers on the app'**
  String get onlineRequestsCardSubtitle;

  /// No description provided for @onlineRequestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String onlineRequestsWaiting(int count);

  /// No description provided for @onlineRequestsNoneWaiting.
  ///
  /// In en, this message translates to:
  /// **'No new requests'**
  String get onlineRequestsNoneWaiting;

  /// No description provided for @onlineRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests here'**
  String get onlineRequestsEmptyTitle;

  /// No description provided for @onlineRequestsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Requests from customers appear here. Keep your shop listing complete so customers can find you.'**
  String get onlineRequestsEmptyMessage;

  /// No description provided for @onlineRequestCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get onlineRequestCustomer;

  /// No description provided for @onlineRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get onlineRequestAccept;

  /// No description provided for @onlineRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get onlineRequestDecline;

  /// No description provided for @onlineRequestCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get onlineRequestCreateOrder;

  /// No description provided for @onlineRequestComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get onlineRequestComplete;

  /// No description provided for @onlineRequestAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get onlineRequestAcceptTitle;

  /// No description provided for @onlineRequestConfirmTime.
  ///
  /// In en, this message translates to:
  /// **'Confirmed date and time'**
  String get onlineRequestConfirmTime;

  /// No description provided for @onlineRequestNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Message to the customer (optional)'**
  String get onlineRequestNoteHint;

  /// No description provided for @onlineRequestDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get onlineRequestDeclineTitle;

  /// No description provided for @onlineRequestDeclineHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (the customer will see this)'**
  String get onlineRequestDeclineHint;

  /// No description provided for @onlineRequestDeclineNeedReason.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason'**
  String get onlineRequestDeclineNeedReason;

  /// No description provided for @onlineRequestCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed?'**
  String get onlineRequestCompleteTitle;

  /// No description provided for @onlineRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get onlineRequestAccepted;

  /// No description provided for @onlineRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get onlineRequestDeclined;

  /// No description provided for @onlineRequestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Request completed'**
  String get onlineRequestCompleted;

  /// No description provided for @onlineRequestOrderLinked.
  ///
  /// In en, this message translates to:
  /// **'Order {number} created and linked'**
  String onlineRequestOrderLinked(String number);

  /// No description provided for @onlineRequestOrderNotLinked.
  ///
  /// In en, this message translates to:
  /// **'The order was created but could not be linked to this request. Open the request again to retry.'**
  String get onlineRequestOrderNotLinked;

  /// No description provided for @onlineRequestOnlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineRequestOnlineBadge;

  /// No description provided for @onlineRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {time}'**
  String onlineRequestReceived(String time);

  /// No description provided for @onlineRequestExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Reply before {time} or it expires'**
  String onlineRequestExpiresAt(String time);

  /// No description provided for @onlineRequestCallCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get onlineRequestCallCustomer;

  /// No description provided for @onlineRequestDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km from your shop'**
  String onlineRequestDistance(String km);

  /// No description provided for @onlineRequestStaffCannotCreate.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner or a manager to create the order.'**
  String get onlineRequestStaffCannotCreate;

  /// No description provided for @pickupWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Who will go and collect it?'**
  String get pickupWorkerLabel;

  /// No description provided for @pickupChooseWorker.
  ///
  /// In en, this message translates to:
  /// **'Choose a worker'**
  String get pickupChooseWorker;

  /// No description provided for @pickupNoWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers found for this branch. Add a worker in Staff first.'**
  String get pickupNoWorkers;

  /// No description provided for @pickupWorkerRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the worker who will collect'**
  String get pickupWorkerRequired;

  /// No description provided for @pickupChangeWorker.
  ///
  /// In en, this message translates to:
  /// **'Change worker'**
  String get pickupChangeWorker;

  /// No description provided for @pickupBy.
  ///
  /// In en, this message translates to:
  /// **'Pickup by {name}'**
  String pickupBy(String name);

  /// No description provided for @pickupCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Record the pickup'**
  String get pickupCollectTitle;

  /// No description provided for @pickupCollectAction.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get pickupCollectAction;

  /// No description provided for @pickupItemsHeading.
  ///
  /// In en, this message translates to:
  /// **'What did you collect?'**
  String get pickupItemsHeading;

  /// No description provided for @pickupItemName.
  ///
  /// In en, this message translates to:
  /// **'Item (e.g. Shirt)'**
  String get pickupItemName;

  /// No description provided for @pickupItemQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get pickupItemQty;

  /// No description provided for @pickupAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get pickupAddItem;

  /// No description provided for @pickupNeedItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item with a quantity'**
  String get pickupNeedItem;

  /// No description provided for @pickupDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get pickupDeliveryDate;

  /// No description provided for @pickupAutoDate.
  ///
  /// In en, this message translates to:
  /// **'Automatic: {date}'**
  String pickupAutoDate(String date);

  /// No description provided for @pickupCustomDate.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get pickupCustomDate;

  /// No description provided for @pickupBackToAuto.
  ///
  /// In en, this message translates to:
  /// **'Use the automatic date'**
  String get pickupBackToAuto;

  /// No description provided for @pickupCollectedToast.
  ///
  /// In en, this message translates to:
  /// **'Pickup recorded. The customer has been told the delivery date.'**
  String get pickupCollectedToast;

  /// No description provided for @pickupDeliveryOn.
  ///
  /// In en, this message translates to:
  /// **'Delivery on {date}'**
  String pickupDeliveryOn(String date);

  /// No description provided for @pickupCollectedItems.
  ///
  /// In en, this message translates to:
  /// **'Collected items'**
  String get pickupCollectedItems;

  /// No description provided for @pickupPhotosHeading.
  ///
  /// In en, this message translates to:
  /// **'Photos at pickup'**
  String get pickupPhotosHeading;

  /// No description provided for @pickupTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get pickupTakePhoto;

  /// No description provided for @pickupPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 6 photos'**
  String get pickupPhotoLimit;

  /// No description provided for @pickupUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get pickupUploading;

  /// No description provided for @pickupPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos taken at pickup'**
  String get pickupPhotosTitle;

  /// No description provided for @shopListingModesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch each one on or off. You can change this any time and save again.'**
  String get shopListingModesHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
