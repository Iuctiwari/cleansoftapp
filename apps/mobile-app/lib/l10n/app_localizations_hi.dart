// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get language => 'भाषा';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get chooseLanguageSubtitle =>
      'आप इसे कभी भी अपनी प्रोफ़ाइल से बदल सकते हैं।';

  @override
  String get commonContinue => 'आगे बढ़ें';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonSkipForNow => 'अभी छोड़ें';

  @override
  String get commonRetry => 'फिर से कोशिश करें';

  @override
  String get commonEmail => 'ईमेल';

  @override
  String get commonPhone => 'फ़ोन';

  @override
  String get commonLocation => 'स्थान';

  @override
  String get commonBusiness => 'व्यवसाय';

  @override
  String get commonOr => 'या';

  @override
  String get commonActive => 'सक्रिय';

  @override
  String get commonRequiredInformation => 'आवश्यक जानकारी';

  @override
  String get commonConnectionProblem => 'कनेक्शन में समस्या';

  @override
  String get commonSomethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get commonUnableToSignIn =>
      'साइन इन नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String fieldRequired(String field) {
    return '$field आवश्यक है';
  }

  @override
  String stepFraction(int current, int total) {
    return 'चरण $current/$total';
  }

  @override
  String stepOf(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get loginWelcomeBack => 'फिर से स्वागत है';

  @override
  String get loginSubtitle => 'अपने व्यवसाय खाते में साइन इन करें';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get createBusinessAccount => 'व्यवसाय खाता बनाएं';

  @override
  String get companyAdmin => 'कंपनी एडमिन';

  @override
  String get termsAgreementPrefix => 'साइन इन करके आप हमारी ';

  @override
  String get termsAgreementSuffix => ' से सहमत होते हैं';

  @override
  String get termsOfService => 'सेवा की शर्तों';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get loginMissingCredentials =>
      'आगे बढ़ने के लिए अपना ईमेल और पासवर्ड दर्ज करें।';

  @override
  String get loginInvalidCredentials => 'ईमेल या पासवर्ड गलत है';

  @override
  String get splashTagline => 'व्यवसाय प्रबंधन प्लेटफ़ॉर्म';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get backToLoginTooltip => 'लॉगिन पर वापस जाएं';

  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get forgotPasswordHeading => 'पासवर्ड भूल गए?';

  @override
  String get forgotPasswordBody =>
      'अपना ईमेल पता दर्ज करें, हम पासवर्ड रीसेट करने के लिए आपको 6 अंकों का सत्यापन कोड भेजेंगे।';

  @override
  String get sendingCode => 'कोड भेजा जा रहा है...';

  @override
  String get sendVerificationCode => 'सत्यापन कोड भेजें';

  @override
  String get checkYourEmail => 'अपना ईमेल देखें';

  @override
  String codeSentTo(String email) {
    return 'यदि खाता पात्र है, तो $email पर सत्यापन कोड भेज दिया गया है। पासवर्ड रीसेट करने के लिए निर्देशों का पालन करें।';
  }

  @override
  String get codeSentGeneric =>
      'यदि खाता पात्र है, तो सत्यापन कोड भेज दिया गया है।';

  @override
  String get enterEmailToContinue =>
      'आगे बढ़ने के लिए अपना ईमेल पता दर्ज करें।';

  @override
  String get unableToSendCode =>
      'सत्यापन कोड नहीं भेजा जा सका। कृपया फिर से कोशिश करें।';

  @override
  String get enterVerificationCode => 'सत्यापन कोड दर्ज करें';

  @override
  String get setNewPassword => 'नया पासवर्ड सेट करें';

  @override
  String get resetPasswordBody =>
      'अपने ईमेल पर भेजा गया 6 अंकों का सत्यापन कोड और अपना नया पासवर्ड दर्ज करें।';

  @override
  String get verificationCodeLabel => '6 अंकों का सत्यापन कोड';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmNewPassword => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get resettingPassword => 'पासवर्ड रीसेट हो रहा है...';

  @override
  String get enterSixDigitCode =>
      'अपने ईमेल पर भेजा गया 6 अंकों का सत्यापन कोड दर्ज करें।';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get passwordResetSuccess =>
      'पासवर्ड सफलतापूर्वक रीसेट हो गया। कृपया साइन इन करें।';

  @override
  String get passwordResetFailed =>
      'पासवर्ड रीसेट नहीं हो सका। कृपया अपना कोड जांचें और फिर से कोशिश करें।';

  @override
  String get passwordPolicyHint =>
      'कम से कम 8 अक्षर, जिनमें एक बड़ा अक्षर, एक छोटा अक्षर, एक अंक और एक विशेष चिह्न हो।';

  @override
  String get passwordRuleMinLength => 'कम से कम 8 अक्षर';

  @override
  String get passwordRuleUppercase => 'एक बड़ा अक्षर (A–Z)';

  @override
  String get passwordRuleLowercase => 'एक छोटा अक्षर (a–z)';

  @override
  String get passwordRuleNumber => 'एक अंक (0–9)';

  @override
  String get passwordRuleSpecial => 'एक विशेष चिह्न (जैसे ! @ # \$)';

  @override
  String passwordNeeds(String rule) {
    return 'पासवर्ड में यह होना चाहिए: $rule।';
  }

  @override
  String get businessInfoTitle => 'व्यवसाय जानकारी';

  @override
  String get businessInfoHeading => 'अपने व्यवसाय के बारे में बताएं';

  @override
  String get businessInfoSubtitle =>
      'इससे हमें आपका अनुभव बेहतर बनाने में मदद मिलती है।';

  @override
  String get businessName => 'व्यवसाय का नाम';

  @override
  String get businessNameHint => 'जैसे शर्मा लॉन्ड्री एंड क्लीनर्स';

  @override
  String get businessNameRequired => 'व्यवसाय का नाम आवश्यक है';

  @override
  String get nameTooShort => 'नाम बहुत छोटा है';

  @override
  String get businessType => 'व्यवसाय का प्रकार';

  @override
  String get ownerName => 'मालिक का नाम';

  @override
  String get owner => 'मालिक';

  @override
  String get fullNameHint => 'पूरा नाम';

  @override
  String get ownerNameRequired => 'मालिक का नाम आवश्यक है';

  @override
  String get selectBusinessType => 'कृपया व्यवसाय का प्रकार चुनें';

  @override
  String get businessSummaryIntro =>
      'यह आपके व्यवसाय का सारांश है। आप इसे बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get businessTypeLaundry => 'लॉन्ड्री';

  @override
  String get businessTypeDryCleaning => 'ड्राई क्लीनिंग';

  @override
  String get businessTypeTailoring => 'सिलाई';

  @override
  String get businessTypeShoeCleaning => 'जूता सफ़ाई';

  @override
  String get businessTypeApplianceRepair => 'उपकरण मरम्मत';

  @override
  String get businessTypeMobileRepair => 'मोबाइल मरम्मत';

  @override
  String get businessTypeVehicleWash => 'वाहन धुलाई';

  @override
  String get businessTypeSalon => 'सैलून';

  @override
  String get businessTypeGeneral => 'सामान्य';

  @override
  String get businessTypeCustom => 'कस्टम';

  @override
  String get serviceWashAndFold => 'धुलाई और तह';

  @override
  String get accountDetailsTitle => 'खाता विवरण';

  @override
  String get createAccountHeading => 'अपना खाता बनाएं';

  @override
  String get createAccountSubtitle =>
      'साइन इन करने के लिए आप इन्हीं का उपयोग करेंगे।';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get phoneRequired => 'फ़ोन नंबर आवश्यक है';

  @override
  String get invalidPhone => 'मान्य फ़ोन नंबर दर्ज करें';

  @override
  String get passwordMinHint => 'कम से कम 8 अक्षर';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक है';

  @override
  String get passwordMin8 => 'कम से कम 8 अक्षर';

  @override
  String get passwordNeedsUppercase => 'इसमें एक बड़ा अक्षर होना चाहिए';

  @override
  String get passwordNeedsNumber => 'इसमें एक अंक होना चाहिए';

  @override
  String get passwordNeedsSpecial => 'इसमें एक विशेष चिह्न होना चाहिए';

  @override
  String get agreePrefix => 'मैं ';

  @override
  String get agreeAnd => ' और ';

  @override
  String get agreeSuffix => ' से सहमत हूं';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get registrationFillHighlighted =>
      'कृपया चिह्नित फ़ील्ड भरें — ईमेल, फ़ोन नंबर और पासवर्ड आवश्यक हैं।';

  @override
  String get mustAgreeTerms => 'आपको सेवा की शर्तों से सहमत होना होगा।';

  @override
  String alreadyRegisteredAdvice(String message) {
    return '$message। उसी खाते से लॉग इन करें (ज़रूरत हो तो \"पासवर्ड भूल गए?\" का उपयोग करें), या कोई दूसरा उपयोग करें।';
  }

  @override
  String get registrationFailed =>
      'पंजीकरण पूरा नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get accountCreatedTitle => 'खाता बन गया!';

  @override
  String get accountCreatedBody =>
      'आपका व्यवसाय खाता तैयार है।\nचलिए आपका वर्कस्पेस सेट करते हैं।';

  @override
  String get startSetup => 'सेटअप शुरू करें';

  @override
  String get firstBranchTitle => 'पहली शाखा';

  @override
  String get firstBranchHeading => 'अपनी पहली शाखा जोड़ें';

  @override
  String get firstBranchSubtitle =>
      'अपनी मुख्य शाखा का पता और संपर्क विवरण दर्ज करें।';

  @override
  String get branchName => 'शाखा का नाम';

  @override
  String get mainBranchHint => 'मुख्य शाखा';

  @override
  String get streetAddress => 'पता';

  @override
  String get streetAddressHint => 'गली/सड़क का पता';

  @override
  String get city => 'शहर';

  @override
  String get postalCode => 'पिन कोड';

  @override
  String get postalCodeHint => 'पिन कोड';

  @override
  String get invalidEmailAddress => 'मान्य ईमेल पता दर्ज करें';

  @override
  String get servicesTitle => 'सेवाएं';

  @override
  String get servicesSubtitle =>
      'अपने व्यवसाय द्वारा दी जाने वाली सेवाएं चुनें। आप बाद में और जोड़ सकते हैं।';

  @override
  String get selectAtLeastOneService => 'कम से कम एक सेवा चुनें';

  @override
  String servicesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेवाएं चुनी गईं',
      one: '1 सेवा चुनी गई',
    );
    return '$_temp0';
  }

  @override
  String get inviteStaffTitle => 'स्टाफ़ आमंत्रित करें';

  @override
  String get inviteStaffSubtitle =>
      'टीम के सदस्यों को अपने वर्कस्पेस में आमंत्रित करें। हर व्यक्ति को ईमेल से आमंत्रण मिलेगा।';

  @override
  String get staffEmailLabel => 'ईमेल *';

  @override
  String staffEmailNumberedLabel(int number) {
    return 'ईमेल $number *';
  }

  @override
  String get staffMobileLabel => 'मोबाइल नंबर (वैकल्पिक)';

  @override
  String staffMobileNumberedLabel(int number) {
    return 'मोबाइल नंबर $number (वैकल्पिक)';
  }

  @override
  String get emailRequiredForInvite => 'आमंत्रण भेजने के लिए ईमेल आवश्यक है';

  @override
  String get invalidEmail => 'मान्य ईमेल दर्ज करें';

  @override
  String get emailEnteredTwice => 'यह ईमेल दो बार दर्ज किया गया है';

  @override
  String get invalidMobile => 'मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get addAnother => 'एक और जोड़ें';

  @override
  String get inviteStaffNote =>
      'हर स्टाफ़ सदस्य को उनकी लॉगिन आईडी (उनका ईमेल) के साथ एक ईमेल मिलेगा। वे ऐप में \"पासवर्ड भूल गए?\" पर टैप करके अपना पासवर्ड खुद सेट करेंगे। आप बाद में स्टाफ़ स्क्रीन से और स्टाफ़ जोड़ सकते हैं।';

  @override
  String get inviteFixHighlighted =>
      'कृपया चिह्नित फ़ील्ड ठीक करें। हर स्टाफ़ सदस्य का ईमेल पता होना चाहिए — आमंत्रण ईमेल से भेजा जाता है।';

  @override
  String get invitationsSent => 'आमंत्रण भेजे गए';

  @override
  String get invitationsNeedAttention =>
      'कुछ आमंत्रणों पर ध्यान देने की ज़रूरत है';

  @override
  String inviteReportAllSent(String emails) {
    return '$emails को आमंत्रण भेजा गया। वे ऐप में \"पासवर्ड भूल गए?\" से अपना पासवर्ड खुद सेट करेंगे।';
  }

  @override
  String inviteReportInvited(String emails) {
    return 'आमंत्रित: $emails।';
  }

  @override
  String inviteReportEmailFailed(String email) {
    return '$email — खाता बन गया, लेकिन ईमेल नहीं भेजा जा सका। उनसे ऐप खोलकर \"पासवर्ड भूल गए?\" पर टैप करने को कहें।';
  }

  @override
  String inviteReportFailed(String email, String reason) {
    return '$email — $reason';
  }

  @override
  String get inviteReportCouldNotInvite => 'आमंत्रित नहीं किया जा सका';

  @override
  String get inviteReportFooter =>
      'आप बाद में स्टाफ़ स्क्रीन से स्टाफ़ जोड़ या फिर से आमंत्रित कर सकते हैं।';

  @override
  String get unableToSaveOnboarding =>
      'ऑनबोर्डिंग सहेजी नहीं जा सकी। कृपया फिर से कोशिश करें।';

  @override
  String get allSetTitle => 'सब तैयार!';

  @override
  String get allSetHeading => 'आप पूरी तरह तैयार हैं!';

  @override
  String get allSetBody =>
      'आपका वर्कस्पेस सेट और तैयार है। ऑर्डर जोड़ना और अपना व्यवसाय संभालना शुरू करें।';

  @override
  String get goToDashboard => 'डैशबोर्ड पर जाएं';

  @override
  String branchCreated(String name) {
    return '$name बनाई गई';
  }

  @override
  String get branchNotCreated => 'शाखा नहीं बनाई गई';

  @override
  String servicesConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेवाएं सेट की गईं',
      one: '1 सेवा सेट की गई',
    );
    return '$_temp0';
  }

  @override
  String get servicesNotConfigured => 'सेवाएं सेट नहीं की गईं';

  @override
  String get staffInvitationSkipped => 'स्टाफ़ आमंत्रण छोड़ा गया';

  @override
  String staffInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्टाफ़ आमंत्रण भेजे गए',
      one: '1 स्टाफ़ आमंत्रण भेजा गया',
    );
    return '$_temp0';
  }

  @override
  String get choosePlanTitle => 'अपना प्लान चुनें';

  @override
  String get choosePlanSubtitle =>
      'अपना वर्कस्पेस सक्रिय करने के लिए एक प्लान चुनें। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get unableToLoadPlans =>
      'प्लान लोड नहीं हो सके। कृपया फिर से कोशिश करें।';

  @override
  String get unableToSelectPlan =>
      'यह प्लान नहीं चुना जा सका। कृपया फिर से कोशिश करें।';

  @override
  String get noPlansTitle => 'कोई प्लान उपलब्ध नहीं';

  @override
  String get noPlansMessage =>
      'अभी तक कोई सक्रिय सब्सक्रिप्शन प्लान सेट नहीं है।';

  @override
  String get billingMonthly => 'मासिक';

  @override
  String get billingAnnual => 'वार्षिक';

  @override
  String get currentPlan => 'वर्तमान प्लान';

  @override
  String get planFree => 'मुफ़्त';

  @override
  String get perYear => ' / वर्ष';

  @override
  String get perMonth => ' / माह';

  @override
  String freeTrialDays(int days) {
    return '$days दिन का मुफ़्त ट्रायल';
  }

  @override
  String planLimits(int branches, int staff, int orders) {
    return 'अधिकतम $branches शाखाएं · $staff स्टाफ़ · $orders ऑर्डर/माह';
  }

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get editProfileTooltip => 'प्रोफ़ाइल संपादित करें';

  @override
  String get loadingProfile => 'प्रोफ़ाइल लोड हो रही है...';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get securitySection => 'सुरक्षा';

  @override
  String get preferencesSection => 'प्राथमिकताएं';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String lastChanged(String when) {
    return 'पिछली बार बदला गया: $when';
  }

  @override
  String get accountCreatedLabel => 'खाता बनाया गया';

  @override
  String get plan => 'प्लान';

  @override
  String get branch => 'शाखा';

  @override
  String get roleSwitch => 'भूमिका बदलें';

  @override
  String get roleSwitchSubtitle => 'डेमो मोड — डैशबोर्ड व्यू बदलें';

  @override
  String get roleOwnerDescription => 'सभी सुविधाओं तक पूरी पहुंच';

  @override
  String get roleBranchManager => 'शाखा प्रबंधक';

  @override
  String get roleBranchManagerDescription => 'शाखा संचालन और स्टाफ़';

  @override
  String get roleStaffMember => 'स्टाफ़ सदस्य';

  @override
  String get roleStaffMemberDescription => 'केवल सौंपे गए ऑर्डर';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get name => 'नाम';

  @override
  String get enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get nameRequired => 'नाम आवश्यक है';

  @override
  String get enterYourPhone => 'अपना फ़ोन नंबर दर्ज करें';

  @override
  String get enterBusinessName => 'अपने व्यवसाय का नाम दर्ज करें';

  @override
  String get enterLocationCityBranch => 'अपना स्थान दर्ज करें (शहर/शाखा)';

  @override
  String get enterLocation => 'अपना स्थान दर्ज करें';

  @override
  String get saveProfile => 'प्रोफ़ाइल सहेजें';

  @override
  String get fixHighlightedBeforeSaving =>
      'सहेजने से पहले कृपया चिह्नित फ़ील्ड ठीक करें।';

  @override
  String get changePasswordIntro =>
      'अपना वर्तमान पासवर्ड दर्ज करें, फिर नया पासवर्ड चुनें।';

  @override
  String get enterCurrentPassword => 'अपना वर्तमान पासवर्ड दर्ज करें।';

  @override
  String get newPasswordsDoNotMatch => 'नए पासवर्ड मेल नहीं खाते।';

  @override
  String get newPasswordMustDiffer =>
      'नया पासवर्ड वर्तमान पासवर्ड से अलग होना चाहिए।';

  @override
  String get unableToChangePassword =>
      'पासवर्ड नहीं बदला जा सका। कृपया फिर से कोशिश करें।';

  @override
  String get passwordChanged => 'पासवर्ड बदल गया';

  @override
  String get passwordChangedBody =>
      'आपका पासवर्ड बदल दिया गया है और आपके अन्य डिवाइस से साइन आउट कर दिया गया है। कृपया नए पासवर्ड से फिर से साइन इन करें।';

  @override
  String get changingPassword => 'पासवर्ड बदला जा रहा है...';

  @override
  String get welcomeTitle => 'आप Nexoraa का उपयोग कैसे करना चाहते हैं?';

  @override
  String get welcomeSubtitle => 'एक चुनें — आप कभी भी बदल सकते हैं।';

  @override
  String get welcomeCustomerTitle => 'मुझे सेवा चाहिए';

  @override
  String get welcomeCustomerSubtitle =>
      'अपने पास लॉन्ड्री, रिपेयर, सैलून और बहुत कुछ खोजें';

  @override
  String get welcomeBusinessTitle => 'मेरा व्यवसाय है';

  @override
  String get welcomeBusinessSubtitle =>
      'अपनी दुकान के ऑर्डर, स्टाफ और भुगतान संभालें';

  @override
  String get consumerLoginTitle => 'स्वागत है';

  @override
  String get consumerLoginSubtitle =>
      'अपने पास की सेवाएँ खोजने के लिए साइन इन करें';

  @override
  String get consumerIdentifierLabel => 'ईमेल या मोबाइल नंबर';

  @override
  String get consumerNewHere => 'नए हैं?';

  @override
  String get consumerCreateAccount => 'खाता बनाएँ';

  @override
  String get consumerBusinessLink => 'व्यवसाय चलाते हैं? यहाँ साइन इन करें';

  @override
  String get consumerSignupTitle => 'अपना खाता बनाएँ';

  @override
  String get consumerSignupSubtitle =>
      'यह मुफ़्त है। सत्यापन के लिए हम आपको ईमेल पर कोड भेजेंगे।';

  @override
  String get consumerFullName => 'पूरा नाम';

  @override
  String get consumerMobileNumber => 'मोबाइल नंबर';

  @override
  String get consumerConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get consumerHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get consumerVerifyTitle => 'अपना ईमेल सत्यापित करें';

  @override
  String consumerVerifySubtitle(String email) {
    return '$email पर भेजा गया 6 अंकों का कोड दर्ज करें';
  }

  @override
  String get consumerVerifyButton => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get consumerResendCode => 'नया कोड भेजें';

  @override
  String consumerResendIn(int seconds) {
    return '$seconds सेकंड में नया कोड भेजें';
  }

  @override
  String get consumerCodeSent => 'आपके ईमेल पर नया कोड भेजा गया है';

  @override
  String get consumerForgotTitle => 'अपना पासवर्ड रीसेट करें';

  @override
  String get consumerForgotSubtitle =>
      'अपना ईमेल या मोबाइल नंबर दर्ज करें, हम आपको ईमेल पर कोड भेजेंगे।';

  @override
  String get consumerSendCode => 'कोड भेजें';

  @override
  String get consumerResetButton => 'पासवर्ड रीसेट करें';

  @override
  String get consumerPasswordResetDone =>
      'पासवर्ड बदल गया। कृपया साइन इन करें।';

  @override
  String get consumerErrEmailTaken =>
      'इस ईमेल से खाता पहले से है। कृपया साइन इन करें।';

  @override
  String get consumerErrMobileTaken => 'यह मोबाइल नंबर पहले से पंजीकृत है।';

  @override
  String get consumerErrPasswordPolicy =>
      'पासवर्ड में कम से कम 8 अक्षर हों, जिनमें एक बड़ा अक्षर, एक छोटा अक्षर, एक अंक और एक चिह्न हो।';

  @override
  String get consumerErrLoginDenied => 'ईमेल/मोबाइल या पासवर्ड गलत है।';

  @override
  String get consumerErrNotVerified => 'कृपया पहले अपना ईमेल सत्यापित करें।';

  @override
  String get consumerErrCodeInvalid =>
      'कोड गलत है या उसकी समय-सीमा समाप्त हो गई है।';

  @override
  String get consumerErrTooManyAttempts =>
      'बहुत अधिक प्रयास। कृपया थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get consumerErrEmailDelivery =>
      'हम अभी ईमेल नहीं भेज सके। कृपया फिर कोशिश करें।';

  @override
  String get consumerErrNetwork =>
      'सर्वर तक नहीं पहुँच सके। अपना इंटरनेट कनेक्शन जाँचें।';

  @override
  String get consumerErrSession =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर से साइन इन करें।';

  @override
  String get consumerErrGeneric => 'कुछ गलत हो गया। कृपया फिर कोशिश करें।';

  @override
  String get consumerFullNameRequired => 'अपना पूरा नाम दर्ज करें';

  @override
  String get consumerIdentifierRequired => 'अपना ईमेल या मोबाइल नंबर दर्ज करें';

  @override
  String get consumerAddressTitleNew => 'अपना पता जोड़ें';

  @override
  String get consumerAddressTitleEdit => 'पता बदलें';

  @override
  String get consumerAddressRequiredNote =>
      'आपके पास की दुकानें दिखाने के लिए हमें आपका पता चाहिए।';

  @override
  String get consumerUseCurrentLocation => 'मेरी वर्तमान लोकेशन उपयोग करें';

  @override
  String get consumerLocating => 'आपकी लोकेशन खोज रहे हैं…';

  @override
  String get consumerLocationPinned => 'लोकेशन पिन हो गई';

  @override
  String get consumerLocationNeeded =>
      'अपना पता पिन करने के लिए “मेरी वर्तमान लोकेशन उपयोग करें” दबाएँ।';

  @override
  String get consumerLocationOff =>
      'लोकेशन बंद है। पता पिन करने के लिए इसे चालू करें।';

  @override
  String get consumerLocationDenied =>
      'पता पिन करने के लिए लोकेशन की अनुमति चाहिए।';

  @override
  String get consumerLocationUnavailable =>
      'आपकी लोकेशन नहीं मिल सकी। कृपया फिर कोशिश करें।';

  @override
  String get consumerOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get consumerSaveAs => 'इस रूप में सहेजें';

  @override
  String get addressLabelHome => 'घर';

  @override
  String get addressLabelWork => 'काम';

  @override
  String get addressLabelOther => 'अन्य';

  @override
  String get consumerHouseFlat => 'मकान / फ्लैट / मंज़िल';

  @override
  String get consumerStreetArea => 'गली, क्षेत्र या इलाका';

  @override
  String get consumerLandmark => 'लैंडमार्क (वैकल्पिक)';

  @override
  String get consumerState => 'राज्य';

  @override
  String get consumerPincode => 'पिन कोड';

  @override
  String get consumerInvalidPincode => 'मान्य 6 अंकों का पिन कोड दर्ज करें';

  @override
  String get consumerContactName => 'संपर्क नाम';

  @override
  String get consumerContactPhone => 'संपर्क फ़ोन';

  @override
  String get consumerMakeDefault => 'इसे मेरा डिफ़ॉल्ट पता बनाएँ';

  @override
  String get consumerSaveAddress => 'पता सहेजें';

  @override
  String get consumerAddresses => 'मेरे पते';

  @override
  String get consumerAddAddress => 'नया पता जोड़ें';

  @override
  String get consumerDefault => 'डिफ़ॉल्ट';

  @override
  String get consumerSetDefault => 'डिफ़ॉल्ट बनाएँ';

  @override
  String get consumerEdit => 'बदलें';

  @override
  String get consumerDelete => 'हटाएँ';

  @override
  String get consumerDeleteAddressConfirm => 'यह पता हटाएँ?';

  @override
  String get consumerCannotDeleteLastAddress =>
      'कम से कम एक पता ज़रूरी है। इसे हटाने से पहले दूसरा पता जोड़ें।';

  @override
  String get consumerTabShops => 'दुकानें';

  @override
  String get consumerTabRequests => 'मेरे अनुरोध';

  @override
  String get consumerTabAccount => 'खाता';

  @override
  String get consumerShowingNear => 'इसके पास की दुकानें';

  @override
  String get consumerCurrentLocation => 'वर्तमान लोकेशन';

  @override
  String get consumerChooseLocation => 'इसके पास दुकानें खोजें…';

  @override
  String get consumerSearchShops => 'दुकान के नाम से खोजें';

  @override
  String get consumerFilterAll => 'सभी';

  @override
  String get consumerFilterOpenNow => 'अभी खुली';

  @override
  String get modeVisitShop => 'दुकान पर जाएँ';

  @override
  String get modeHomeService => 'घर पर सेवा';

  @override
  String get modePickupDrop => 'पिकअप और ड्रॉप';

  @override
  String consumerDistanceKm(String km) {
    return '$km किमी';
  }

  @override
  String consumerWithinKm(int km) {
    return '$km किमी के भीतर';
  }

  @override
  String get consumerOpenNow => 'अभी खुली';

  @override
  String get consumerClosedNow => 'अभी बंद';

  @override
  String consumerTodayHours(String open, String close) {
    return 'आज $open – $close';
  }

  @override
  String get consumerClosedToday => 'आज बंद';

  @override
  String get consumerCall => 'कॉल करें';

  @override
  String get consumerBook => 'बुक करें';

  @override
  String get consumerDirections => 'रास्ता';

  @override
  String get consumerServesYou => 'आपके इलाके में आती है';

  @override
  String get consumerNoShopsTitle => 'पास में कोई दुकान नहीं मिली';

  @override
  String get consumerNoShopsMessage =>
      'दूसरी श्रेणी चुनें, फ़िल्टर हटाएँ या ज़्यादा दूरी तक खोजें।';

  @override
  String get consumerCouldNotOpen => 'इस काम के लिए ऐप नहीं खुल सका';

  @override
  String get consumerAbout => 'परिचय';

  @override
  String get consumerServices => 'सेवाएँ';

  @override
  String get consumerHowTheyServe => 'वे कैसे सेवा देते हैं';

  @override
  String consumerTravelsUpTo(int km) {
    return '$km किमी तक आपके पास आते हैं';
  }

  @override
  String get consumerOpeningHours => 'खुलने का समय';

  @override
  String get consumerClosed => 'बंद';

  @override
  String get consumerAddressHeading => 'पता';

  @override
  String get consumerBookService => 'सेवा बुक करें';

  @override
  String consumerBookTitle(String shop) {
    return '$shop पर बुक करें';
  }

  @override
  String get consumerWhatService => 'आपको क्या चाहिए?';

  @override
  String get consumerHowServed => 'आप इसे कैसे चाहते हैं?';

  @override
  String get consumerWhen => 'कब?';

  @override
  String get consumerPickDate => 'तारीख चुनें';

  @override
  String get consumerTimeFrom => 'से';

  @override
  String get consumerTimeTo => 'तक';

  @override
  String get consumerYourAddress => 'आपका पता';

  @override
  String get consumerDescribe => 'बताएँ आपको क्या चाहिए';

  @override
  String get consumerDescribeHint =>
      'जैसे: 5 शर्ट धोकर इस्त्री करें, 2 चादरों पर दाग हैं';

  @override
  String get consumerItemsOptional => 'सामान (वैकल्पिक)';

  @override
  String get consumerAddItem => 'सामान जोड़ें';

  @override
  String get consumerItemName => 'सामान';

  @override
  String get consumerQty => 'संख्या';

  @override
  String get consumerSendRequest => 'अनुरोध भेजें';

  @override
  String get consumerRequestSentTitle => 'अनुरोध भेजा गया!';

  @override
  String consumerRequestSentMessage(String shop) {
    return '$shop 48 घंटों में जवाब देगी। आप इसे मेरे अनुरोध में देख सकते हैं।';
  }

  @override
  String get consumerShopClosedThatDay =>
      'उस दिन दुकान बंद है। कृपया दूसरी तारीख चुनें।';

  @override
  String get consumerSlotInvalid =>
      'खत्म होने का समय शुरू होने के बाद होना चाहिए।';

  @override
  String get consumerDescribeMore =>
      'कृपया बताएँ आपको क्या चाहिए (कम से कम 5 अक्षर)।';

  @override
  String get consumerChooseAddress => 'घर पर सेवा या पिकअप के लिए पता चुनें।';

  @override
  String consumerOutsideArea(int km) {
    return 'यह दुकान $km किमी तक आती है; आपका पता इससे दूर है।';
  }

  @override
  String get requestStatusPending => 'प्रतीक्षा में';

  @override
  String get requestStatusAccepted => 'स्वीकार';

  @override
  String get requestStatusDeclined => 'अस्वीकार';

  @override
  String get requestStatusCancelled => 'रद्द';

  @override
  String get requestStatusExpired => 'कोई जवाब नहीं';

  @override
  String get requestStatusCompleted => 'पूर्ण';

  @override
  String get consumerNoRequestsTitle => 'अभी कोई अनुरोध नहीं';

  @override
  String get consumerNoRequestsMessage =>
      'कोई दुकान खोजें और सेवा बुक करें — आपके अनुरोध यहाँ दिखेंगे।';

  @override
  String get consumerRequestDetails => 'अनुरोध विवरण';

  @override
  String get consumerPreferredTime => 'पसंदीदा समय';

  @override
  String get consumerConfirmedTime => 'पक्का समय';

  @override
  String get consumerShopMessage => 'दुकान का संदेश';

  @override
  String get consumerReason => 'कारण';

  @override
  String consumerOrderCreated(String number) {
    return 'ऑर्डर $number बना';
  }

  @override
  String consumerReplyBy(String time) {
    return 'दुकान को $time तक जवाब देना है';
  }

  @override
  String get consumerCancelRequest => 'अनुरोध रद्द करें';

  @override
  String get consumerCancelConfirm => 'यह अनुरोध रद्द करें?';

  @override
  String get consumerCancelReasonHint => 'कारण (वैकल्पिक)';

  @override
  String get consumerKeepRequest => 'रहने दें';

  @override
  String get consumerHistory => 'इतिहास';

  @override
  String get consumerByYou => 'आप';

  @override
  String get consumerByShop => 'दुकान';

  @override
  String get consumerByAutomatic => 'स्वचालित';

  @override
  String get consumerCallShop => 'दुकान को कॉल करें';

  @override
  String get consumerItems => 'सामान';

  @override
  String get consumerAccountTitle => 'मेरा खाता';

  @override
  String get consumerSignOutConfirm => 'अपने खाते से साइन आउट करें?';

  @override
  String get shopListingTitle => 'दुकान लिस्टिंग';

  @override
  String get shopListingMenuSubtitle =>
      'ग्राहकों को दिखने वाला पता, बुकिंग फ़ोन और समय';

  @override
  String get shopListingVisible => 'ग्राहक आपकी दुकान खोज सकते हैं';

  @override
  String get shopListingHiddenIncomplete =>
      'ग्राहकों से छिपी है — नीचे बाकी जानकारी भरें';

  @override
  String get shopListingHiddenUnlisted =>
      'ग्राहकों से छिपी है — आपने लिस्टिंग बंद की है';

  @override
  String get shopListingHiddenInactive =>
      'ग्राहकों से छिपी है — आपका व्यवसाय खाता सक्रिय नहीं है';

  @override
  String get shopListingShowToCustomers => 'मेरी दुकान ग्राहकों को दिखाएँ';

  @override
  String get shopListingAddressSection => 'दुकान का पता';

  @override
  String get shopListingPinShop => 'दुकान की लोकेशन पिन करें';

  @override
  String get shopListingPinHint =>
      'अपनी दुकान के अंदर खड़े होकर “दुकान की लोकेशन पिन करें” दबाएँ। ग्राहक इसी जगह से दूरी देखते हैं।';

  @override
  String get shopListingStreet => 'दुकान नं., इमारत, गली';

  @override
  String get shopListingArea => 'क्षेत्र / इलाका';

  @override
  String get shopListingBookingPhone => 'बुकिंग फ़ोन (ग्राहकों को दिखेगा)';

  @override
  String shopListingBookingPhoneHint(String phone) {
    return 'खाली छोड़ें तो आपका फ़ोन दिखेगा: $phone';
  }

  @override
  String get shopListingInvalidPhone =>
      '10 अंकों का मोबाइल या STD कोड के साथ लैंडलाइन दर्ज करें';

  @override
  String get shopListingHowServe => 'आप ग्राहकों को कैसे सेवा देते हैं';

  @override
  String get shopListingChooseMode => 'कम से कम एक चुनें';

  @override
  String shopListingRadius(int km) {
    return 'घर पर सेवा और पिकअप के लिए आप $km किमी तक जाते हैं';
  }

  @override
  String get shopListingHours => 'खुलने का समय';

  @override
  String get shopListingOpen => 'खुली';

  @override
  String get shopListingClosed => 'बंद';

  @override
  String get shopListingNeedOpenDay => 'दुकान कम से कम एक दिन खुली होनी चाहिए';

  @override
  String get shopListingAbout => 'आपकी दुकान के बारे में (वैकल्पिक)';

  @override
  String get shopListingAboutHint =>
      'जैसे: उसी दिन इस्त्री, ₹300 से ऊपर मुफ़्त पिकअप';

  @override
  String get shopListingSave => 'लिस्टिंग सहेजें';

  @override
  String get shopListingSaved => 'लिस्टिंग सहेजी गई';

  @override
  String get shopListingNeedPin => 'पहले अपनी दुकान की लोकेशन पिन करें';

  @override
  String get shopListingNoPermission =>
      'दुकान लिस्टिंग केवल मालिक या ब्रांच मैनेजर बदल सकते हैं।';

  @override
  String get shopAddressPromptTitle => 'अपनी दुकान का पता जोड़ें';

  @override
  String get shopAddressPromptBody =>
      'पता और लोकेशन जोड़ते ही आपके पास के ग्राहक आपकी दुकान खोज और बुक कर सकेंगे।';

  @override
  String get shopAddressPromptAction => 'पता जोड़ें';

  @override
  String get shopAddressPromptLater => 'बाद में';

  @override
  String get onlineRequestsTitle => 'ऑनलाइन अनुरोध';

  @override
  String get onlineRequestsCardSubtitle => 'ऐप पर ग्राहकों की बुकिंग';

  @override
  String onlineRequestsWaiting(int count) {
    return '$count प्रतीक्षा में';
  }

  @override
  String get onlineRequestsNoneWaiting => 'कोई नया अनुरोध नहीं';

  @override
  String get onlineRequestsEmptyTitle => 'यहाँ कोई अनुरोध नहीं';

  @override
  String get onlineRequestsEmptyMessage =>
      'ग्राहकों के अनुरोध यहाँ दिखेंगे। दुकान लिस्टिंग पूरी रखें ताकि ग्राहक आपको खोज सकें।';

  @override
  String get onlineRequestCustomer => 'ग्राहक';

  @override
  String get onlineRequestAccept => 'स्वीकार करें';

  @override
  String get onlineRequestDecline => 'अस्वीकार करें';

  @override
  String get onlineRequestCreateOrder => 'ऑर्डर बनाएँ';

  @override
  String get onlineRequestComplete => 'पूर्ण चिह्नित करें';

  @override
  String get onlineRequestAcceptTitle => 'अनुरोध स्वीकार करें';

  @override
  String get onlineRequestConfirmTime => 'पक्की तारीख और समय';

  @override
  String get onlineRequestNoteHint => 'ग्राहक के लिए संदेश (वैकल्पिक)';

  @override
  String get onlineRequestDeclineTitle => 'अनुरोध अस्वीकार करें';

  @override
  String get onlineRequestDeclineHint => 'कारण (ग्राहक इसे देखेंगे)';

  @override
  String get onlineRequestDeclineNeedReason => 'कृपया कारण बताएँ';

  @override
  String get onlineRequestCompleteTitle => 'पूर्ण चिह्नित करें?';

  @override
  String get onlineRequestAccepted => 'अनुरोध स्वीकार किया गया';

  @override
  String get onlineRequestDeclined => 'अनुरोध अस्वीकार किया गया';

  @override
  String get onlineRequestCompleted => 'अनुरोध पूर्ण हुआ';

  @override
  String onlineRequestOrderLinked(String number) {
    return 'ऑर्डर $number बना और जुड़ गया';
  }

  @override
  String get onlineRequestOrderNotLinked =>
      'ऑर्डर बन गया पर इस अनुरोध से जुड़ नहीं सका। फिर से कोशिश करने के लिए अनुरोध दोबारा खोलें।';

  @override
  String get onlineRequestOnlineBadge => 'ऑनलाइन';

  @override
  String onlineRequestReceived(String time) {
    return 'प्राप्त $time';
  }

  @override
  String onlineRequestExpiresAt(String time) {
    return '$time से पहले जवाब दें, नहीं तो यह समाप्त हो जाएगा';
  }

  @override
  String get onlineRequestCallCustomer => 'ग्राहक को कॉल करें';

  @override
  String onlineRequestDistance(String km) {
    return 'आपकी दुकान से $km किमी';
  }

  @override
  String get onlineRequestStaffCannotCreate =>
      'ऑर्डर बनाने के लिए मालिक या मैनेजर से कहें।';

  @override
  String get pickupWorkerLabel => 'लेने कौन जाएगा?';

  @override
  String get pickupChooseWorker => 'कर्मचारी चुनें';

  @override
  String get pickupNoWorkers =>
      'इस ब्रांच में कोई कर्मचारी नहीं मिला। पहले स्टाफ में जोड़ें।';

  @override
  String get pickupWorkerRequired => 'लेने जाने वाला कर्मचारी चुनें';

  @override
  String get pickupChangeWorker => 'कर्मचारी बदलें';

  @override
  String pickupBy(String name) {
    return '$name लेने जाएंगे';
  }

  @override
  String get pickupCollectTitle => 'पिकअप दर्ज करें';

  @override
  String get pickupCollectAction => 'ले लिया';

  @override
  String get pickupItemsHeading => 'आपने क्या लिया?';

  @override
  String get pickupItemName => 'आइटम (जैसे शर्ट)';

  @override
  String get pickupItemQty => 'संख्या';

  @override
  String get pickupAddItem => 'आइटम जोड़ें';

  @override
  String get pickupNeedItem => 'संख्या के साथ कम से कम एक आइटम जोड़ें';

  @override
  String get pickupDeliveryDate => 'डिलीवरी की तारीख';

  @override
  String pickupAutoDate(String date) {
    return 'अपने-आप: $date';
  }

  @override
  String get pickupCustomDate => 'दूसरी तारीख चुनें';

  @override
  String get pickupBackToAuto => 'अपने-आप वाली तारीख लें';

  @override
  String get pickupCollectedToast =>
      'पिकअप दर्ज हुआ। ग्राहक को डिलीवरी की तारीख बता दी गई है।';

  @override
  String pickupDeliveryOn(String date) {
    return '$date को डिलीवरी';
  }

  @override
  String get pickupCollectedItems => 'लिए गए आइटम';

  @override
  String get pickupPhotosHeading => 'पिकअप की फ़ोटो';

  @override
  String get pickupTakePhoto => 'फ़ोटो लें';

  @override
  String get pickupPhotoLimit => 'अधिकतम 6 फ़ोटो';

  @override
  String get pickupUploading => 'फ़ोटो अपलोड हो रही हैं…';

  @override
  String get pickupPhotosTitle => 'पिकअप के समय ली गई फ़ोटो';
}
