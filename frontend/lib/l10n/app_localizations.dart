import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ResQ'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get profileSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety tools in one place'**
  String get homeSubtitle;

  /// No description provided for @emergencyAccessReady.
  ///
  /// In en, this message translates to:
  /// **'Emergency access is ready'**
  String get emergencyAccessReady;

  /// No description provided for @goodToSeeYouSafe.
  ///
  /// In en, this message translates to:
  /// **'Good to see you safe'**
  String get goodToSeeYouSafe;

  /// No description provided for @emergencySos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySos;

  /// No description provided for @activeVerifiedAlert.
  ///
  /// In en, this message translates to:
  /// **'Active verified alert'**
  String get activeVerifiedAlert;

  /// No description provided for @yourReadinessPlan.
  ///
  /// In en, this message translates to:
  /// **'Your readiness plan'**
  String get yourReadinessPlan;

  /// No description provided for @signInSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your emergency plan.'**
  String get signInSavePlan;

  /// No description provided for @askResq.
  ///
  /// In en, this message translates to:
  /// **'Ask ResQ'**
  String get askResq;

  /// No description provided for @assistantPrompt.
  ///
  /// In en, this message translates to:
  /// **'How can I help you prepare?'**
  String get assistantPrompt;

  /// No description provided for @updatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified local alerts and changing conditions'**
  String get updatesSubtitle;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share what is happening without putting yourself at risk'**
  String get reportSubtitle;

  /// No description provided for @familySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts and accepted Circle members'**
  String get familySubtitle;

  /// No description provided for @placesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified help within 5 km'**
  String get placesSubtitle;

  /// No description provided for @resqAssistant.
  ///
  /// In en, this message translates to:
  /// **'ResQ assistant'**
  String get resqAssistant;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get voiceAssistant;

  /// No description provided for @startVoiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Start voice assistant'**
  String get startVoiceAssistant;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @noSavedConversations.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet. Start one to build your history.'**
  String get noSavedConversations;

  /// No description provided for @messageResq.
  ///
  /// In en, this message translates to:
  /// **'Message ResQ'**
  String get messageResq;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @yourReadiness.
  ///
  /// In en, this message translates to:
  /// **'Your readiness'**
  String get yourReadiness;

  /// No description provided for @yourInformation.
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get yourInformation;

  /// No description provided for @manageMyCircle.
  ///
  /// In en, this message translates to:
  /// **'Manage My Circle'**
  String get manageMyCircle;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @sosHistory.
  ///
  /// In en, this message translates to:
  /// **'SOS history'**
  String get sosHistory;

  /// No description provided for @privacyAiAccess.
  ///
  /// In en, this message translates to:
  /// **'Privacy and AI data access'**
  String get privacyAiAccess;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language — English / हिन्दी'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @getGuidance.
  ///
  /// In en, this message translates to:
  /// **'Get guidance'**
  String get getGuidance;

  /// No description provided for @submitPrivateReport.
  ///
  /// In en, this message translates to:
  /// **'Submit private report'**
  String get submitPrivateReport;

  /// No description provided for @call112.
  ///
  /// In en, this message translates to:
  /// **'Call 112'**
  String get call112;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;
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
      <String>['en', 'hi'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
