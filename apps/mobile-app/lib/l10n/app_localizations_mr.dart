// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get language => 'भाषा';

  @override
  String get chooseLanguage => 'भाषा निवडा';

  @override
  String get chooseLanguageSubtitle =>
      'तुम्ही ही भाषा कधीही तुमच्या प्रोफाइलमधून बदलू शकता.';

  @override
  String get commonContinue => 'पुढे चला';

  @override
  String get commonBack => 'मागे';

  @override
  String get commonSkipForNow => 'आत्ता वगळा';

  @override
  String get commonRetry => 'पुन्हा प्रयत्न करा';

  @override
  String get commonEmail => 'ईमेल';

  @override
  String get commonPhone => 'फोन';

  @override
  String get commonLocation => 'ठिकाण';

  @override
  String get commonBusiness => 'व्यवसाय';

  @override
  String get commonOr => 'किंवा';

  @override
  String get commonActive => 'सक्रिय';

  @override
  String get commonRequiredInformation => 'आवश्यक माहिती';

  @override
  String get commonConnectionProblem => 'कनेक्शनमध्ये समस्या';

  @override
  String get commonSomethingWentWrong => 'काहीतरी चूक झाली';

  @override
  String get commonUnableToSignIn =>
      'साइन इन करता आले नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String fieldRequired(String field) {
    return '$field आवश्यक आहे';
  }

  @override
  String stepFraction(int current, int total) {
    return 'टप्पा $current/$total';
  }

  @override
  String stepOf(int current, int total) {
    return 'टप्पा $current / $total';
  }

  @override
  String get loginWelcomeBack => 'पुन्हा स्वागत आहे';

  @override
  String get loginSubtitle => 'तुमच्या व्यवसाय खात्यात साइन इन करा';

  @override
  String get emailAddress => 'ईमेल पत्ता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get signIn => 'साइन इन करा';

  @override
  String get createBusinessAccount => 'व्यवसाय खाते तयार करा';

  @override
  String get companyAdmin => 'कंपनी अ‍ॅडमिन';

  @override
  String get termsAgreementPrefix => 'साइन इन करून तुम्ही आमच्या ';

  @override
  String get termsAgreementSuffix => ' मान्य करता';

  @override
  String get termsOfService => 'सेवा अटी';

  @override
  String get privacyPolicy => 'गोपनीयता धोरण';

  @override
  String get loginMissingCredentials =>
      'पुढे जाण्यासाठी तुमचा ईमेल आणि पासवर्ड टाका.';

  @override
  String get loginInvalidCredentials => 'ईमेल किंवा पासवर्ड चुकीचा आहे';

  @override
  String get splashTagline => 'व्यवसाय व्यवस्थापन प्लॅटफॉर्म';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करा';

  @override
  String get backToLoginTooltip => 'लॉगिनवर परत जा';

  @override
  String get backToLogin => 'लॉगिनवर परत जा';

  @override
  String get forgotPasswordHeading => 'पासवर्ड विसरलात?';

  @override
  String get forgotPasswordBody =>
      'तुमचा ईमेल पत्ता टाका, पासवर्ड रीसेट करण्यासाठी आम्ही तुम्हाला 6 अंकी पडताळणी कोड पाठवू.';

  @override
  String get sendingCode => 'कोड पाठवत आहोत...';

  @override
  String get sendVerificationCode => 'पडताळणी कोड पाठवा';

  @override
  String get checkYourEmail => 'तुमचा ईमेल तपासा';

  @override
  String codeSentTo(String email) {
    return 'खाते पात्र असल्यास, $email वर पडताळणी कोड पाठवला आहे. पासवर्ड रीसेट करण्यासाठी सूचनांचे पालन करा.';
  }

  @override
  String get codeSentGeneric => 'खाते पात्र असल्यास, पडताळणी कोड पाठवला आहे.';

  @override
  String get enterEmailToContinue => 'पुढे जाण्यासाठी तुमचा ईमेल पत्ता टाका.';

  @override
  String get unableToSendCode =>
      'पडताळणी कोड पाठवता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get enterVerificationCode => 'पडताळणी कोड टाका';

  @override
  String get setNewPassword => 'नवीन पासवर्ड सेट करा';

  @override
  String get resetPasswordBody =>
      'तुमच्या ईमेलवर आलेला 6 अंकी पडताळणी कोड आणि तुमचा नवीन पासवर्ड टाका.';

  @override
  String get verificationCodeLabel => '6 अंकी पडताळणी कोड';

  @override
  String get currentPassword => 'सध्याचा पासवर्ड';

  @override
  String get newPassword => 'नवीन पासवर्ड';

  @override
  String get confirmNewPassword => 'नवीन पासवर्डची पुष्टी करा';

  @override
  String get resettingPassword => 'पासवर्ड रीसेट होत आहे...';

  @override
  String get enterSixDigitCode =>
      'तुमच्या ईमेलवर आलेला 6 अंकी पडताळणी कोड टाका.';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड जुळत नाहीत.';

  @override
  String get passwordResetSuccess =>
      'पासवर्ड यशस्वीरित्या रीसेट झाला. कृपया साइन इन करा.';

  @override
  String get passwordResetFailed =>
      'पासवर्ड रीसेट करता आला नाही. कृपया तुमचा कोड तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get passwordPolicyHint =>
      'किमान 8 अक्षरे, ज्यात एक कॅपिटल अक्षर, एक स्मॉल अक्षर, एक अंक आणि एक विशेष चिन्ह असावे.';

  @override
  String get passwordRuleMinLength => 'किमान 8 अक्षरे';

  @override
  String get passwordRuleUppercase => 'एक कॅपिटल अक्षर (A–Z)';

  @override
  String get passwordRuleLowercase => 'एक स्मॉल अक्षर (a–z)';

  @override
  String get passwordRuleNumber => 'एक अंक (0–9)';

  @override
  String get passwordRuleSpecial => 'एक विशेष चिन्ह (उदा. ! @ # \$)';

  @override
  String passwordNeeds(String rule) {
    return 'पासवर्डमध्ये हे असावे: $rule.';
  }

  @override
  String get businessInfoTitle => 'व्यवसाय माहिती';

  @override
  String get businessInfoHeading => 'तुमच्या व्यवसायाबद्दल सांगा';

  @override
  String get businessInfoSubtitle =>
      'यामुळे आम्हाला तुमचा अनुभव अधिक चांगला करता येतो.';

  @override
  String get businessName => 'व्यवसायाचे नाव';

  @override
  String get businessNameHint => 'उदा. पाटील लॉन्ड्री अँड क्लीनर्स';

  @override
  String get businessNameRequired => 'व्यवसायाचे नाव आवश्यक आहे';

  @override
  String get nameTooShort => 'नाव खूप लहान आहे';

  @override
  String get businessType => 'व्यवसायाचा प्रकार';

  @override
  String get ownerName => 'मालकाचे नाव';

  @override
  String get owner => 'मालक';

  @override
  String get fullNameHint => 'पूर्ण नाव';

  @override
  String get ownerNameRequired => 'मालकाचे नाव आवश्यक आहे';

  @override
  String get selectBusinessType => 'कृपया व्यवसायाचा प्रकार निवडा';

  @override
  String get businessSummaryIntro =>
      'हा तुमच्या व्यवसायाचा सारांश आहे. तुम्ही हे नंतर सेटिंग्जमध्ये बदलू शकता.';

  @override
  String get businessTypeLaundry => 'लॉन्ड्री';

  @override
  String get businessTypeDryCleaning => 'ड्राय क्लीनिंग';

  @override
  String get businessTypeTailoring => 'शिवणकाम';

  @override
  String get businessTypeShoeCleaning => 'बूट स्वच्छता';

  @override
  String get businessTypeApplianceRepair => 'उपकरण दुरुस्ती';

  @override
  String get businessTypeMobileRepair => 'मोबाइल दुरुस्ती';

  @override
  String get businessTypeVehicleWash => 'वाहन धुलाई';

  @override
  String get businessTypeSalon => 'सलून';

  @override
  String get businessTypeGeneral => 'सामान्य';

  @override
  String get businessTypeCustom => 'कस्टम';

  @override
  String get serviceWashAndFold => 'धुणे आणि घडी';

  @override
  String get accountDetailsTitle => 'खाते तपशील';

  @override
  String get createAccountHeading => 'तुमचे खाते तयार करा';

  @override
  String get createAccountSubtitle => 'साइन इन करण्यासाठी तुम्ही हेच वापराल.';

  @override
  String get emailRequired => 'ईमेल आवश्यक आहे';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get phoneRequired => 'फोन नंबर आवश्यक आहे';

  @override
  String get invalidPhone => 'वैध फोन नंबर टाका';

  @override
  String get passwordMinHint => 'किमान 8 अक्षरे';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक आहे';

  @override
  String get passwordMin8 => 'किमान 8 अक्षरे';

  @override
  String get passwordNeedsUppercase => 'यात एक कॅपिटल अक्षर असावे';

  @override
  String get passwordNeedsNumber => 'यात एक अंक असावा';

  @override
  String get passwordNeedsSpecial => 'यात एक विशेष चिन्ह असावे';

  @override
  String get agreePrefix => 'मी ';

  @override
  String get agreeAnd => ' आणि ';

  @override
  String get agreeSuffix => ' यांना सहमत आहे';

  @override
  String get createAccount => 'खाते तयार करा';

  @override
  String get registrationFillHighlighted =>
      'कृपया चिन्हांकित फील्ड भरा — ईमेल, फोन नंबर आणि पासवर्ड आवश्यक आहेत.';

  @override
  String get mustAgreeTerms => 'तुम्हाला सेवा अटी मान्य कराव्या लागतील.';

  @override
  String alreadyRegisteredAdvice(String message) {
    return '$message. त्याच खात्याने लॉग इन करा (गरज असल्यास \"पासवर्ड विसरलात?\" वापरा), किंवा दुसरे वापरा.';
  }

  @override
  String get registrationFailed =>
      'नोंदणी पूर्ण करता आली नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get accountCreatedTitle => 'खाते तयार झाले!';

  @override
  String get accountCreatedBody =>
      'तुमचे व्यवसाय खाते तयार आहे.\nचला तुमचे वर्कस्पेस सेट करूया.';

  @override
  String get startSetup => 'सेटअप सुरू करा';

  @override
  String get firstBranchTitle => 'पहिली शाखा';

  @override
  String get firstBranchHeading => 'तुमची पहिली शाखा जोडा';

  @override
  String get firstBranchSubtitle =>
      'तुमच्या मुख्य शाखेचा पत्ता आणि संपर्क तपशील टाका.';

  @override
  String get branchName => 'शाखेचे नाव';

  @override
  String get mainBranchHint => 'मुख्य शाखा';

  @override
  String get streetAddress => 'पत्ता';

  @override
  String get streetAddressHint => 'रस्त्याचा पत्ता';

  @override
  String get city => 'शहर';

  @override
  String get postalCode => 'पिन कोड';

  @override
  String get postalCodeHint => 'पिन कोड';

  @override
  String get invalidEmailAddress => 'वैध ईमेल पत्ता टाका';

  @override
  String get servicesTitle => 'सेवा';

  @override
  String get servicesSubtitle =>
      'तुमचा व्यवसाय देत असलेल्या सेवा निवडा. तुम्ही नंतर आणखी जोडू शकता.';

  @override
  String get selectAtLeastOneService => 'किमान एक सेवा निवडा';

  @override
  String servicesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेवा निवडल्या',
      one: '1 सेवा निवडली',
    );
    return '$_temp0';
  }

  @override
  String get inviteStaffTitle => 'कर्मचारी आमंत्रित करा';

  @override
  String get inviteStaffSubtitle =>
      'टीम सदस्यांना तुमच्या वर्कस्पेसमध्ये आमंत्रित करा. प्रत्येकाला ईमेलद्वारे आमंत्रण मिळेल.';

  @override
  String get staffEmailLabel => 'ईमेल *';

  @override
  String staffEmailNumberedLabel(int number) {
    return 'ईमेल $number *';
  }

  @override
  String get staffMobileLabel => 'मोबाइल नंबर (पर्यायी)';

  @override
  String staffMobileNumberedLabel(int number) {
    return 'मोबाइल नंबर $number (पर्यायी)';
  }

  @override
  String get emailRequiredForInvite => 'आमंत्रण पाठवण्यासाठी ईमेल आवश्यक आहे';

  @override
  String get invalidEmail => 'वैध ईमेल टाका';

  @override
  String get emailEnteredTwice => 'हा ईमेल दोनदा टाकला आहे';

  @override
  String get invalidMobile => 'वैध मोबाइल नंबर टाका';

  @override
  String get addAnother => 'आणखी एक जोडा';

  @override
  String get inviteStaffNote =>
      'प्रत्येक कर्मचाऱ्याला त्यांच्या लॉगिन आयडीसह (त्यांचा ईमेल) एक ईमेल मिळेल. ते अ‍ॅपमध्ये \"पासवर्ड विसरलात?\" वर टॅप करून स्वतःचा पासवर्ड सेट करतील. तुम्ही नंतर कर्मचारी स्क्रीनवरून आणखी कर्मचारी जोडू शकता.';

  @override
  String get inviteFixHighlighted =>
      'कृपया चिन्हांकित फील्ड दुरुस्त करा. प्रत्येक कर्मचाऱ्याचा ईमेल पत्ता आवश्यक आहे — आमंत्रण ईमेलने पाठवले जाते.';

  @override
  String get invitationsSent => 'आमंत्रणे पाठवली';

  @override
  String get invitationsNeedAttention =>
      'काही आमंत्रणांकडे लक्ष देणे आवश्यक आहे';

  @override
  String inviteReportAllSent(String emails) {
    return '$emails यांना आमंत्रण पाठवले. ते अ‍ॅपमध्ये \"पासवर्ड विसरलात?\" वापरून स्वतःचा पासवर्ड सेट करतील.';
  }

  @override
  String inviteReportInvited(String emails) {
    return 'आमंत्रित: $emails.';
  }

  @override
  String inviteReportEmailFailed(String email) {
    return '$email — खाते तयार झाले, पण ईमेल पाठवता आला नाही. त्यांना अ‍ॅप उघडून \"पासवर्ड विसरलात?\" वर टॅप करायला सांगा.';
  }

  @override
  String inviteReportFailed(String email, String reason) {
    return '$email — $reason';
  }

  @override
  String get inviteReportCouldNotInvite => 'आमंत्रित करता आले नाही';

  @override
  String get inviteReportFooter =>
      'तुम्ही नंतर कर्मचारी स्क्रीनवरून कर्मचारी जोडू किंवा पुन्हा आमंत्रित करू शकता.';

  @override
  String get unableToSaveOnboarding =>
      'ऑनबोर्डिंग जतन करता आले नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get allSetTitle => 'सर्व तयार!';

  @override
  String get allSetHeading => 'तुम्ही पूर्णपणे तयार आहात!';

  @override
  String get allSetBody =>
      'तुमचे वर्कस्पेस सेट झाले आहे आणि तयार आहे. ऑर्डर जोडणे आणि तुमचा व्यवसाय सांभाळणे सुरू करा.';

  @override
  String get goToDashboard => 'डॅशबोर्डवर जा';

  @override
  String branchCreated(String name) {
    return '$name तयार झाली';
  }

  @override
  String get branchNotCreated => 'शाखा तयार झाली नाही';

  @override
  String servicesConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेवा सेट केल्या',
      one: '1 सेवा सेट केली',
    );
    return '$_temp0';
  }

  @override
  String get servicesNotConfigured => 'सेवा सेट केल्या नाहीत';

  @override
  String get staffInvitationSkipped => 'कर्मचारी आमंत्रण वगळले';

  @override
  String staffInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कर्मचारी आमंत्रणे पाठवली',
      one: '1 कर्मचारी आमंत्रण पाठवले',
    );
    return '$_temp0';
  }

  @override
  String get choosePlanTitle => 'तुमचा प्लॅन निवडा';

  @override
  String get choosePlanSubtitle =>
      'तुमचे वर्कस्पेस सक्रिय करण्यासाठी एक प्लॅन निवडा. तुम्ही हे कधीही बदलू शकता.';

  @override
  String get unableToLoadPlans =>
      'प्लॅन लोड करता आले नाहीत. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get unableToSelectPlan =>
      'हा प्लॅन निवडता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get noPlansTitle => 'कोणताही प्लॅन उपलब्ध नाही';

  @override
  String get noPlansMessage =>
      'अद्याप कोणताही सक्रिय सबस्क्रिप्शन प्लॅन सेट केलेला नाही.';

  @override
  String get billingMonthly => 'मासिक';

  @override
  String get billingAnnual => 'वार्षिक';

  @override
  String get currentPlan => 'सध्याचा प्लॅन';

  @override
  String get planFree => 'मोफत';

  @override
  String get perYear => ' / वर्ष';

  @override
  String get perMonth => ' / महिना';

  @override
  String freeTrialDays(int days) {
    return '$days दिवसांची मोफत चाचणी';
  }

  @override
  String planLimits(int branches, int staff, int orders) {
    return 'कमाल $branches शाखा · $staff कर्मचारी · $orders ऑर्डर/महिना';
  }

  @override
  String get myProfile => 'माझे प्रोफाइल';

  @override
  String get editProfileTooltip => 'प्रोफाइल संपादित करा';

  @override
  String get loadingProfile => 'प्रोफाइल लोड होत आहे...';

  @override
  String get personalInformation => 'वैयक्तिक माहिती';

  @override
  String get securitySection => 'सुरक्षा';

  @override
  String get preferencesSection => 'प्राधान्ये';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String lastChanged(String when) {
    return 'शेवटचा बदल: $when';
  }

  @override
  String get accountCreatedLabel => 'खाते तयार केले';

  @override
  String get plan => 'प्लॅन';

  @override
  String get branch => 'शाखा';

  @override
  String get roleSwitch => 'भूमिका बदला';

  @override
  String get roleSwitchSubtitle => 'डेमो मोड — डॅशबोर्ड व्ह्यू बदला';

  @override
  String get roleOwnerDescription => 'सर्व वैशिष्ट्यांचा पूर्ण वापर';

  @override
  String get roleBranchManager => 'शाखा व्यवस्थापक';

  @override
  String get roleBranchManagerDescription => 'शाखा कामकाज आणि कर्मचारी';

  @override
  String get roleStaffMember => 'कर्मचारी';

  @override
  String get roleStaffMemberDescription => 'फक्त नेमून दिलेल्या ऑर्डर';

  @override
  String get signOut => 'साइन आउट करा';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get name => 'नाव';

  @override
  String get enterYourName => 'तुमचे नाव टाका';

  @override
  String get nameRequired => 'नाव आवश्यक आहे';

  @override
  String get enterYourPhone => 'तुमचा फोन नंबर टाका';

  @override
  String get enterBusinessName => 'तुमच्या व्यवसायाचे नाव टाका';

  @override
  String get enterLocationCityBranch => 'तुमचे ठिकाण टाका (शहर/शाखा)';

  @override
  String get enterLocation => 'तुमचे ठिकाण टाका';

  @override
  String get saveProfile => 'प्रोफाइल जतन करा';

  @override
  String get fixHighlightedBeforeSaving =>
      'जतन करण्यापूर्वी कृपया चिन्हांकित फील्ड दुरुस्त करा.';

  @override
  String get changePasswordIntro =>
      'तुमचा सध्याचा पासवर्ड टाका, नंतर नवीन पासवर्ड निवडा.';

  @override
  String get enterCurrentPassword => 'तुमचा सध्याचा पासवर्ड टाका.';

  @override
  String get newPasswordsDoNotMatch => 'नवीन पासवर्ड जुळत नाहीत.';

  @override
  String get newPasswordMustDiffer =>
      'नवीन पासवर्ड सध्याच्या पासवर्डपेक्षा वेगळा असावा.';

  @override
  String get unableToChangePassword =>
      'पासवर्ड बदलता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get passwordChanged => 'पासवर्ड बदलला';

  @override
  String get passwordChangedBody =>
      'तुमचा पासवर्ड बदलला आहे आणि तुमच्या इतर डिव्हाइसेसमधून साइन आउट केले आहे. कृपया नवीन पासवर्डने पुन्हा साइन इन करा.';

  @override
  String get changingPassword => 'पासवर्ड बदलत आहे...';

  @override
  String get welcomeTitle => 'तुम्ही Nexoraa कसे वापरू इच्छिता?';

  @override
  String get welcomeSubtitle => 'एक निवडा — तुम्ही कधीही बदलू शकता.';

  @override
  String get welcomeCustomerTitle => 'मला सेवा हवी आहे';

  @override
  String get welcomeCustomerSubtitle =>
      'तुमच्या जवळ लॉन्ड्री, दुरुस्ती, सलून आणि बरेच काही शोधा';

  @override
  String get welcomeBusinessTitle => 'माझा व्यवसाय आहे';

  @override
  String get welcomeBusinessSubtitle =>
      'तुमच्या दुकानाचे ऑर्डर, कर्मचारी आणि पेमेंट व्यवस्थापित करा';

  @override
  String get consumerLoginTitle => 'स्वागत आहे';

  @override
  String get consumerLoginSubtitle => 'जवळच्या सेवा शोधण्यासाठी साइन इन करा';

  @override
  String get consumerIdentifierLabel => 'ईमेल किंवा मोबाइल नंबर';

  @override
  String get consumerNewHere => 'नवीन आहात?';

  @override
  String get consumerCreateAccount => 'खाते तयार करा';

  @override
  String get consumerBusinessLink => 'व्यवसाय चालवता? येथे साइन इन करा';

  @override
  String get consumerSignupTitle => 'तुमचे खाते तयार करा';

  @override
  String get consumerSignupSubtitle =>
      'हे मोफत आहे. पडताळणीसाठी आम्ही तुम्हाला ईमेलवर कोड पाठवू.';

  @override
  String get consumerFullName => 'पूर्ण नाव';

  @override
  String get consumerMobileNumber => 'मोबाइल नंबर';

  @override
  String get consumerConfirmPassword => 'पासवर्डची पुष्टी करा';

  @override
  String get consumerHaveAccount => 'आधीच खाते आहे? साइन इन करा';

  @override
  String get consumerVerifyTitle => 'तुमचा ईमेल पडताळा';

  @override
  String consumerVerifySubtitle(String email) {
    return '$email वर पाठवलेला 6 अंकी कोड टाका';
  }

  @override
  String get consumerVerifyButton => 'पडताळा आणि पुढे चला';

  @override
  String get consumerResendCode => 'नवीन कोड पाठवा';

  @override
  String consumerResendIn(int seconds) {
    return '$seconds सेकंदात नवीन कोड पाठवा';
  }

  @override
  String get consumerCodeSent => 'तुमच्या ईमेलवर नवीन कोड पाठवला आहे';

  @override
  String get consumerForgotTitle => 'तुमचा पासवर्ड रीसेट करा';

  @override
  String get consumerForgotSubtitle =>
      'तुमचा ईमेल किंवा मोबाइल नंबर टाका, आम्ही तुम्हाला ईमेलवर कोड पाठवू.';

  @override
  String get consumerSendCode => 'कोड पाठवा';

  @override
  String get consumerResetButton => 'पासवर्ड रीसेट करा';

  @override
  String get consumerPasswordResetDone => 'पासवर्ड बदलला. कृपया साइन इन करा.';

  @override
  String get consumerErrEmailTaken =>
      'या ईमेलने खाते आधीच आहे. कृपया साइन इन करा.';

  @override
  String get consumerErrMobileTaken => 'हा मोबाइल नंबर आधीच नोंदणीकृत आहे.';

  @override
  String get consumerErrPasswordPolicy =>
      'पासवर्डमध्ये किमान 8 अक्षरे असावीत, ज्यात एक मोठे अक्षर, एक लहान अक्षर, एक अंक आणि एक चिन्ह असावे.';

  @override
  String get consumerErrLoginDenied => 'ईमेल/मोबाइल किंवा पासवर्ड चुकीचा आहे.';

  @override
  String get consumerErrNotVerified => 'कृपया आधी तुमचा ईमेल पडताळा.';

  @override
  String get consumerErrCodeInvalid =>
      'कोड चुकीचा आहे किंवा त्याची मुदत संपली आहे.';

  @override
  String get consumerErrTooManyAttempts =>
      'खूप प्रयत्न झाले. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.';

  @override
  String get consumerErrEmailDelivery =>
      'आम्ही आत्ता ईमेल पाठवू शकलो नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get consumerErrNetwork =>
      'सर्व्हरपर्यंत पोहोचता आले नाही. तुमचे इंटरनेट कनेक्शन तपासा.';

  @override
  String get consumerErrSession =>
      'तुमचे सत्र संपले आहे. कृपया पुन्हा साइन इन करा.';

  @override
  String get consumerErrGeneric => 'काहीतरी चुकले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get consumerFullNameRequired => 'तुमचे पूर्ण नाव टाका';

  @override
  String get consumerIdentifierRequired => 'तुमचा ईमेल किंवा मोबाइल नंबर टाका';

  @override
  String get consumerAddressTitleNew => 'तुमचा पत्ता जोडा';

  @override
  String get consumerAddressTitleEdit => 'पत्ता बदला';

  @override
  String get consumerAddressRequiredNote =>
      'तुमच्या जवळची दुकाने दाखवण्यासाठी आम्हाला तुमचा पत्ता हवा आहे.';

  @override
  String get consumerUseCurrentLocation => 'माझे सध्याचे ठिकाण वापरा';

  @override
  String get consumerLocating => 'तुमचे ठिकाण शोधत आहोत…';

  @override
  String get consumerLocationPinned => 'ठिकाण पिन झाले';

  @override
  String get consumerLocationNeeded =>
      'तुमचा पत्ता पिन करण्यासाठी “माझे सध्याचे ठिकाण वापरा” दाबा.';

  @override
  String get consumerLocationOff =>
      'लोकेशन बंद आहे. पत्ता पिन करण्यासाठी ते सुरू करा.';

  @override
  String get consumerLocationDenied =>
      'पत्ता पिन करण्यासाठी लोकेशनची परवानगी हवी आहे.';

  @override
  String get consumerLocationUnavailable =>
      'तुमचे ठिकाण मिळाले नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get consumerOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get consumerSaveAs => 'म्हणून जतन करा';

  @override
  String get addressLabelHome => 'घर';

  @override
  String get addressLabelWork => 'काम';

  @override
  String get addressLabelOther => 'इतर';

  @override
  String get consumerHouseFlat => 'घर / फ्लॅट / मजला';

  @override
  String get consumerStreetArea => 'रस्ता, परिसर किंवा भाग';

  @override
  String get consumerLandmark => 'खूण (ऐच्छिक)';

  @override
  String get consumerState => 'राज्य';

  @override
  String get consumerPincode => 'पिन कोड';

  @override
  String get consumerInvalidPincode => 'वैध 6 अंकी पिन कोड टाका';

  @override
  String get consumerContactName => 'संपर्क नाव';

  @override
  String get consumerContactPhone => 'संपर्क फोन';

  @override
  String get consumerMakeDefault => 'हा माझा मुख्य पत्ता करा';

  @override
  String get consumerSaveAddress => 'पत्ता जतन करा';

  @override
  String get consumerAddresses => 'माझे पत्ते';

  @override
  String get consumerAddAddress => 'नवीन पत्ता जोडा';

  @override
  String get consumerDefault => 'मुख्य';

  @override
  String get consumerSetDefault => 'मुख्य करा';

  @override
  String get consumerEdit => 'बदला';

  @override
  String get consumerDelete => 'हटवा';

  @override
  String get consumerDeleteAddressConfirm => 'हा पत्ता हटवायचा?';

  @override
  String get consumerCannotDeleteLastAddress =>
      'किमान एक पत्ता आवश्यक आहे. हा हटवण्यापूर्वी दुसरा पत्ता जोडा.';

  @override
  String get consumerTabShops => 'दुकाने';

  @override
  String get consumerTabRequests => 'माझ्या विनंत्या';

  @override
  String get consumerTabAccount => 'खाते';

  @override
  String get consumerShowingNear => 'जवळची दुकाने';

  @override
  String get consumerCurrentLocation => 'सध्याचे ठिकाण';

  @override
  String get consumerChooseLocation => 'यांच्या जवळ दुकाने शोधा…';

  @override
  String get consumerSearchShops => 'दुकानाच्या नावाने शोधा';

  @override
  String get consumerFilterAll => 'सर्व';

  @override
  String get consumerFilterOpenNow => 'आता उघडी';

  @override
  String get modeVisitShop => 'दुकानात जा';

  @override
  String get modeHomeService => 'घरी सेवा';

  @override
  String get modePickupDrop => 'पिकअप आणि ड्रॉप';

  @override
  String consumerDistanceKm(String km) {
    return '$km किमी';
  }

  @override
  String consumerWithinKm(int km) {
    return '$km किमी अंतरात';
  }

  @override
  String get consumerOpenNow => 'आता उघडी';

  @override
  String get consumerClosedNow => 'आता बंद';

  @override
  String consumerTodayHours(String open, String close) {
    return 'आज $open – $close';
  }

  @override
  String get consumerClosedToday => 'आज बंद';

  @override
  String get consumerCall => 'कॉल करा';

  @override
  String get consumerBook => 'बुक करा';

  @override
  String get consumerDirections => 'मार्ग';

  @override
  String get consumerServesYou => 'तुमच्या भागात येते';

  @override
  String get consumerNoShopsTitle => 'जवळ कोणतेही दुकान सापडले नाही';

  @override
  String get consumerNoShopsMessage =>
      'दुसरी श्रेणी निवडा, फिल्टर काढा किंवा जास्त अंतरापर्यंत शोधा.';

  @override
  String get consumerCouldNotOpen => 'या कामासाठी अ‍ॅप उघडता आले नाही';

  @override
  String get consumerAbout => 'माहिती';

  @override
  String get consumerServices => 'सेवा';

  @override
  String get consumerHowTheyServe => 'ते कशी सेवा देतात';

  @override
  String consumerTravelsUpTo(int km) {
    return '$km किमीपर्यंत तुमच्याकडे येतात';
  }

  @override
  String get consumerOpeningHours => 'उघडण्याची वेळ';

  @override
  String get consumerClosed => 'बंद';

  @override
  String get consumerAddressHeading => 'पत्ता';

  @override
  String get consumerBookService => 'सेवा बुक करा';

  @override
  String consumerBookTitle(String shop) {
    return '$shop येथे बुक करा';
  }

  @override
  String get consumerWhatService => 'तुम्हाला काय हवे आहे?';

  @override
  String get consumerHowServed => 'तुम्हाला हे कसे हवे आहे?';

  @override
  String get consumerWhen => 'केव्हा?';

  @override
  String get consumerPickDate => 'तारीख निवडा';

  @override
  String get consumerTimeFrom => 'पासून';

  @override
  String get consumerTimeTo => 'पर्यंत';

  @override
  String get consumerYourAddress => 'तुमचा पत्ता';

  @override
  String get consumerDescribe => 'तुम्हाला काय हवे ते सांगा';

  @override
  String get consumerDescribeHint =>
      'उदा. 5 शर्ट धुवून इस्त्री करा, 2 चादरींवर डाग आहेत';

  @override
  String get consumerItemsOptional => 'वस्तू (ऐच्छिक)';

  @override
  String get consumerAddItem => 'वस्तू जोडा';

  @override
  String get consumerItemName => 'वस्तू';

  @override
  String get consumerQty => 'संख्या';

  @override
  String get consumerSendRequest => 'विनंती पाठवा';

  @override
  String get consumerRequestSentTitle => 'विनंती पाठवली!';

  @override
  String consumerRequestSentMessage(String shop) {
    return '$shop 48 तासांत उत्तर देईल. तुम्ही हे माझ्या विनंत्या मध्ये पाहू शकता.';
  }

  @override
  String get consumerShopClosedThatDay =>
      'त्या दिवशी दुकान बंद आहे. कृपया दुसरी तारीख निवडा.';

  @override
  String get consumerSlotInvalid =>
      'संपण्याची वेळ सुरू होण्याच्या वेळेनंतर असावी.';

  @override
  String get consumerDescribeMore =>
      'कृपया तुम्हाला काय हवे ते सांगा (किमान 5 अक्षरे).';

  @override
  String get consumerChooseAddress => 'घरी सेवा किंवा पिकअपसाठी पत्ता निवडा.';

  @override
  String consumerOutsideArea(int km) {
    return 'हे दुकान $km किमीपर्यंत येते; तुमचा पत्ता त्याहून दूर आहे.';
  }

  @override
  String get requestStatusPending => 'प्रतीक्षेत';

  @override
  String get requestStatusAccepted => 'स्वीकारली';

  @override
  String get requestStatusDeclined => 'नाकारली';

  @override
  String get requestStatusCancelled => 'रद्द';

  @override
  String get requestStatusExpired => 'उत्तर नाही';

  @override
  String get requestStatusCompleted => 'पूर्ण';

  @override
  String get consumerNoRequestsTitle => 'अजून कोणतीही विनंती नाही';

  @override
  String get consumerNoRequestsMessage =>
      'दुकान शोधा आणि सेवा बुक करा — तुमच्या विनंत्या येथे दिसतील.';

  @override
  String get consumerRequestDetails => 'विनंतीचा तपशील';

  @override
  String get consumerPreferredTime => 'पसंतीची वेळ';

  @override
  String get consumerConfirmedTime => 'निश्चित वेळ';

  @override
  String get consumerShopMessage => 'दुकानाचा संदेश';

  @override
  String get consumerReason => 'कारण';

  @override
  String consumerOrderCreated(String number) {
    return 'ऑर्डर $number तयार झाला';
  }

  @override
  String consumerReplyBy(String time) {
    return 'दुकानाला $time पर्यंत उत्तर द्यायचे आहे';
  }

  @override
  String get consumerCancelRequest => 'विनंती रद्द करा';

  @override
  String get consumerCancelConfirm => 'ही विनंती रद्द करायची?';

  @override
  String get consumerCancelReasonHint => 'कारण (ऐच्छिक)';

  @override
  String get consumerKeepRequest => 'राहू द्या';

  @override
  String get consumerHistory => 'इतिहास';

  @override
  String get consumerByYou => 'तुम्ही';

  @override
  String get consumerByShop => 'दुकान';

  @override
  String get consumerByAutomatic => 'स्वयंचलित';

  @override
  String get consumerCallShop => 'दुकानाला कॉल करा';

  @override
  String get consumerItems => 'वस्तू';

  @override
  String get consumerAccountTitle => 'माझे खाते';

  @override
  String get consumerSignOutConfirm => 'तुमच्या खात्यातून साइन आउट करायचे?';

  @override
  String get shopListingTitle => 'दुकान लिस्टिंग';

  @override
  String get shopListingMenuSubtitle =>
      'ग्राहकांना दिसणारा पत्ता, बुकिंग फोन आणि वेळ';

  @override
  String get shopListingVisible => 'ग्राहक तुमचे दुकान शोधू शकतात';

  @override
  String get shopListingHiddenIncomplete =>
      'ग्राहकांपासून लपलेले — खाली उरलेली माहिती भरा';

  @override
  String get shopListingHiddenUnlisted =>
      'ग्राहकांपासून लपलेले — तुम्ही लिस्टिंग बंद केली आहे';

  @override
  String get shopListingHiddenInactive =>
      'ग्राहकांपासून लपलेले — तुमचे व्यवसाय खाते सक्रिय नाही';

  @override
  String get shopListingShowToCustomers => 'माझे दुकान ग्राहकांना दाखवा';

  @override
  String get shopListingAddressSection => 'दुकानाचा पत्ता';

  @override
  String get shopListingPinShop => 'दुकानाचे ठिकाण पिन करा';

  @override
  String get shopListingPinHint =>
      'दुकानाच्या आत उभे राहून “दुकानाचे ठिकाण पिन करा” दाबा. ग्राहकांना याच ठिकाणापासूनचे अंतर दिसते.';

  @override
  String get shopListingStreet => 'दुकान क्र., इमारत, रस्ता';

  @override
  String get shopListingArea => 'परिसर / भाग';

  @override
  String get shopListingBookingPhone => 'बुकिंग फोन (ग्राहकांना दिसेल)';

  @override
  String shopListingBookingPhoneHint(String phone) {
    return 'रिकामे ठेवल्यास तुमचा फोन दिसेल: $phone';
  }

  @override
  String get shopListingInvalidPhone =>
      '10 अंकी मोबाइल किंवा STD कोडसह लँडलाइन टाका';

  @override
  String get shopListingHowServe => 'तुम्ही ग्राहकांना कशी सेवा देता';

  @override
  String get shopListingChooseMode => 'किमान एक निवडा';

  @override
  String shopListingRadius(int km) {
    return 'घरी सेवा आणि पिकअपसाठी तुम्ही $km किमीपर्यंत जाता';
  }

  @override
  String get shopListingHours => 'उघडण्याची वेळ';

  @override
  String get shopListingOpen => 'उघडे';

  @override
  String get shopListingClosed => 'बंद';

  @override
  String get shopListingNeedOpenDay => 'दुकान किमान एक दिवस उघडे असावे';

  @override
  String get shopListingAbout => 'तुमच्या दुकानाबद्दल (ऐच्छिक)';

  @override
  String get shopListingAboutHint =>
      'उदा. त्याच दिवशी इस्त्री, ₹300 वर मोफत पिकअप';

  @override
  String get shopListingSave => 'लिस्टिंग जतन करा';

  @override
  String get shopListingSaved => 'लिस्टिंग जतन झाली';

  @override
  String get shopListingNeedPin => 'आधी तुमच्या दुकानाचे ठिकाण पिन करा';

  @override
  String get shopListingNoPermission =>
      'दुकान लिस्टिंग फक्त मालक किंवा शाखा व्यवस्थापक बदलू शकतात.';

  @override
  String get shopAddressPromptTitle => 'तुमच्या दुकानाचा पत्ता जोडा';

  @override
  String get shopAddressPromptBody =>
      'पत्ता आणि ठिकाण जोडताच तुमच्या जवळचे ग्राहक तुमचे दुकान शोधू आणि बुक करू शकतील.';

  @override
  String get shopAddressPromptAction => 'पत्ता जोडा';

  @override
  String get shopAddressPromptLater => 'नंतर';

  @override
  String get onlineRequestsTitle => 'ऑनलाइन विनंत्या';

  @override
  String get onlineRequestsCardSubtitle => 'अ‍ॅपवरील ग्राहकांच्या बुकिंग';

  @override
  String onlineRequestsWaiting(int count) {
    return '$count प्रतीक्षेत';
  }

  @override
  String get onlineRequestsNoneWaiting => 'नवीन विनंती नाही';

  @override
  String get onlineRequestsEmptyTitle => 'येथे विनंती नाही';

  @override
  String get onlineRequestsEmptyMessage =>
      'ग्राहकांच्या विनंत्या येथे दिसतील. ग्राहकांना तुम्ही सापडावे म्हणून दुकान लिस्टिंग पूर्ण ठेवा.';

  @override
  String get onlineRequestCustomer => 'ग्राहक';

  @override
  String get onlineRequestAccept => 'स्वीकारा';

  @override
  String get onlineRequestDecline => 'नाकारा';

  @override
  String get onlineRequestCreateOrder => 'ऑर्डर तयार करा';

  @override
  String get onlineRequestComplete => 'पूर्ण म्हणून चिन्हांकित करा';

  @override
  String get onlineRequestAcceptTitle => 'विनंती स्वीकारा';

  @override
  String get onlineRequestConfirmTime => 'निश्चित तारीख आणि वेळ';

  @override
  String get onlineRequestNoteHint => 'ग्राहकासाठी संदेश (ऐच्छिक)';

  @override
  String get onlineRequestDeclineTitle => 'विनंती नाकारा';

  @override
  String get onlineRequestDeclineHint => 'कारण (ग्राहकाला हे दिसेल)';

  @override
  String get onlineRequestDeclineNeedReason => 'कृपया कारण द्या';

  @override
  String get onlineRequestCompleteTitle => 'पूर्ण म्हणून चिन्हांकित करायचे?';

  @override
  String get onlineRequestAccepted => 'विनंती स्वीकारली';

  @override
  String get onlineRequestDeclined => 'विनंती नाकारली';

  @override
  String get onlineRequestCompleted => 'विनंती पूर्ण झाली';

  @override
  String onlineRequestOrderLinked(String number) {
    return 'ऑर्डर $number तयार होऊन जोडला';
  }

  @override
  String get onlineRequestOrderNotLinked =>
      'ऑर्डर तयार झाला पण या विनंतीशी जोडता आला नाही. पुन्हा प्रयत्न करण्यासाठी विनंती पुन्हा उघडा.';

  @override
  String get onlineRequestOnlineBadge => 'ऑनलाइन';

  @override
  String onlineRequestReceived(String time) {
    return 'मिळाली $time';
  }

  @override
  String onlineRequestExpiresAt(String time) {
    return '$time पूर्वी उत्तर द्या, नाहीतर ती संपेल';
  }

  @override
  String get onlineRequestCallCustomer => 'ग्राहकाला कॉल करा';

  @override
  String onlineRequestDistance(String km) {
    return 'तुमच्या दुकानापासून $km किमी';
  }

  @override
  String get onlineRequestStaffCannotCreate =>
      'ऑर्डर तयार करण्यासाठी मालक किंवा व्यवस्थापकाला सांगा.';

  @override
  String get pickupWorkerLabel => 'घ्यायला कोण जाईल?';

  @override
  String get pickupChooseWorker => 'कर्मचारी निवडा';

  @override
  String get pickupNoWorkers =>
      'या शाखेत कर्मचारी सापडला नाही. आधी स्टाफमध्ये जोडा.';

  @override
  String get pickupWorkerRequired => 'घ्यायला जाणारा कर्मचारी निवडा';

  @override
  String get pickupChangeWorker => 'कर्मचारी बदला';

  @override
  String pickupBy(String name) {
    return '$name घ्यायला जातील';
  }

  @override
  String get pickupCollectTitle => 'पिकअप नोंदवा';

  @override
  String get pickupCollectAction => 'घेतले';

  @override
  String get pickupItemsHeading => 'तुम्ही काय घेतले?';

  @override
  String get pickupItemName => 'वस्तू (उदा. शर्ट)';

  @override
  String get pickupItemQty => 'संख्या';

  @override
  String get pickupAddItem => 'वस्तू जोडा';

  @override
  String get pickupNeedItem => 'संख्येसह किमान एक वस्तू जोडा';

  @override
  String get pickupDeliveryDate => 'डिलिव्हरीची तारीख';

  @override
  String pickupAutoDate(String date) {
    return 'आपोआप: $date';
  }

  @override
  String get pickupCustomDate => 'दुसरी तारीख निवडा';

  @override
  String get pickupBackToAuto => 'आपोआप तारीख वापरा';

  @override
  String get pickupCollectedToast =>
      'पिकअप नोंदवला. ग्राहकाला डिलिव्हरीची तारीख कळवली आहे.';

  @override
  String pickupDeliveryOn(String date) {
    return '$date रोजी डिलिव्हरी';
  }

  @override
  String get pickupCollectedItems => 'घेतलेल्या वस्तू';

  @override
  String get pickupPhotosHeading => 'पिकअपचे फोटो';

  @override
  String get pickupTakePhoto => 'फोटो घ्या';

  @override
  String get pickupPhotoLimit => 'जास्तीत जास्त 6 फोटो';

  @override
  String get pickupUploading => 'फोटो अपलोड होत आहेत…';

  @override
  String get pickupPhotosTitle => 'पिकअपच्या वेळी घेतलेले फोटो';

  @override
  String get shopListingModesHint =>
      'प्रत्येक पर्याय चालू/बंद करण्यासाठी टॅप करा. तुम्ही हे कधीही बदलून पुन्हा सेव्ह करू शकता.';

  @override
  String get pickupTotalItems => 'एकूण वस्तू (ऐच्छिक)';

  @override
  String pickupTotalItemsLine(int count) {
    return 'एकूण वस्तू: $count';
  }

  @override
  String get pickupCollectAndCreate => 'घेतले, ऑर्डर तयार करा';
}
