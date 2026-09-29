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

  /// No description provided for @assistantUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assistant unavailable. Emergency calling and saved guidance remain available.'**
  String get assistantUnavailable;

  /// No description provided for @assistantDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily assistant limit reached. Try again tomorrow.'**
  String get assistantDailyLimit;

  /// No description provided for @assistantTurnsLeft.
  ///
  /// In en, this message translates to:
  /// **'assistant turns left today'**
  String get assistantTurnsLeft;

  /// No description provided for @assistantConnectionFailure.
  ///
  /// In en, this message translates to:
  /// **'The assistant could not connect. Try again later.'**
  String get assistantConnectionFailure;

  /// No description provided for @homeAlertRegion.
  ///
  /// In en, this message translates to:
  /// **'Alerts for your saved home region'**
  String get homeAlertRegion;

  /// No description provided for @updatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Updates are unavailable'**
  String get updatesUnavailable;

  /// No description provided for @updatesRetry.
  ///
  /// In en, this message translates to:
  /// **'Pull down to try again. Previously received emergency guidance remains available.'**
  String get updatesRetry;

  /// No description provided for @setHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your home location'**
  String get setHomeLocation;

  /// No description provided for @noMatchingAlerts.
  ///
  /// In en, this message translates to:
  /// **'No matching active alerts'**
  String get noMatchingAlerts;

  /// No description provided for @addDistrictState.
  ///
  /// In en, this message translates to:
  /// **'Add a district and state in your profile to see local alerts.'**
  String get addDistrictState;

  /// No description provided for @noAlertsSafetyNotice.
  ///
  /// In en, this message translates to:
  /// **'This does not mean your area is safe. Check the official SACHET feed for more coverage.'**
  String get noAlertsSafetyNotice;

  /// No description provided for @feedDelayed.
  ///
  /// In en, this message translates to:
  /// **'Feed coverage may be delayed'**
  String get feedDelayed;

  /// No description provided for @feedChecked.
  ///
  /// In en, this message translates to:
  /// **'Official feed checked'**
  String get feedChecked;

  /// No description provided for @noFeedRefresh.
  ///
  /// In en, this message translates to:
  /// **'No source has refreshed yet.'**
  String get noFeedRefresh;

  /// No description provided for @sourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{source}: unavailable ({status})'**
  String sourceUnavailable(String source, String status);

  /// No description provided for @sourceNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'not configured'**
  String get sourceNotConfigured;

  /// No description provided for @sourceRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'refresh failed'**
  String get sourceRefreshFailed;

  /// No description provided for @sourceCoveragePartial.
  ///
  /// In en, this message translates to:
  /// **'partial coverage'**
  String get sourceCoveragePartial;

  /// No description provided for @sourceNotChecked.
  ///
  /// In en, this message translates to:
  /// **'not checked yet'**
  String get sourceNotChecked;

  /// No description provided for @alertValidFor.
  ///
  /// In en, this message translates to:
  /// **'Valid for {duration}'**
  String alertValidFor(String duration);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hr'**
  String durationHours(int count);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String durationDays(int count);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get expired;

  /// No description provided for @alertViewLimited.
  ///
  /// In en, this message translates to:
  /// **'This region has more alerts than this view can show.'**
  String get alertViewLimited;

  /// No description provided for @openSachet.
  ///
  /// In en, this message translates to:
  /// **'Open official SACHET alerts'**
  String get openSachet;

  /// No description provided for @aiResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'ResQ AI'**
  String get aiResponseLabel;

  /// No description provided for @sourcesProvided.
  ///
  /// In en, this message translates to:
  /// **'Sources provided to the assistant'**
  String get sourcesProvided;

  /// No description provided for @sosRecording.
  ///
  /// In en, this message translates to:
  /// **'Digital SOS is being recorded. Call 112 for immediate help.'**
  String get sosRecording;

  /// No description provided for @sosUnconfirmedHelp.
  ///
  /// In en, this message translates to:
  /// **'ResQ could not confirm the online record. Calling 112 and SMS sharing are still available.'**
  String get sosUnconfirmedHelp;

  /// No description provided for @sosNoRecipients.
  ///
  /// In en, this message translates to:
  /// **'SOS recorded. No accepted Family Circle recipients are available. Call 112 if you need immediate help.'**
  String get sosNoRecipients;

  /// No description provided for @sosDeliveryPending.
  ///
  /// In en, this message translates to:
  /// **'SOS recorded. Digital delivery is pending. Call 112 if you need immediate help.'**
  String get sosDeliveryPending;

  /// No description provided for @sosInboxesRecorded.
  ///
  /// In en, this message translates to:
  /// **'SOS recorded in Circle inboxes. Push delivery is not guaranteed. Call 112 if you need immediate help.'**
  String get sosInboxesRecorded;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get sosTitle;

  /// No description provided for @sosSending.
  ///
  /// In en, this message translates to:
  /// **'Sending digital SOS'**
  String get sosSending;

  /// No description provided for @sosRecorded.
  ///
  /// In en, this message translates to:
  /// **'SOS recorded'**
  String get sosRecorded;

  /// No description provided for @sosDigitalUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Digital SOS unconfirmed'**
  String get sosDigitalUnconfirmed;

  /// No description provided for @sosCountdown.
  ///
  /// In en, this message translates to:
  /// **'Sending SOS in'**
  String get sosCountdown;

  /// No description provided for @sosActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap or hold to start SOS countdown'**
  String get sosActivate;

  /// No description provided for @sosCancelNotice.
  ///
  /// In en, this message translates to:
  /// **'You have five seconds to cancel before ResQ records the event.'**
  String get sosCancelNotice;

  /// No description provided for @sosCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel SOS'**
  String get sosCancel;

  /// No description provided for @sosCountdownCancelled.
  ///
  /// In en, this message translates to:
  /// **'SOS countdown cancelled.'**
  String get sosCountdownCancelled;

  /// No description provided for @sosSmsHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask for help by SMS'**
  String get sosSmsHelp;

  /// No description provided for @sosSmsBody.
  ///
  /// In en, this message translates to:
  /// **'I need emergency help.'**
  String get sosSmsBody;

  /// No description provided for @sosMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location:'**
  String get sosMyLocation;

  /// No description provided for @phoneAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No compatible phone app is available.'**
  String get phoneAppUnavailable;

  /// No description provided for @sosEventTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS event'**
  String get sosEventTitle;

  /// No description provided for @sosEventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This SOS event is unavailable or you do not have access.'**
  String get sosEventUnavailable;

  /// No description provided for @sosEventMissing.
  ///
  /// In en, this message translates to:
  /// **'This SOS event was not found.'**
  String get sosEventMissing;

  /// No description provided for @sosCircleActivated.
  ///
  /// In en, this message translates to:
  /// **'A Family Circle member activated SOS'**
  String get sosCircleActivated;

  /// No description provided for @sosPushUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'A push attempt does not confirm that anyone received or read this SOS.'**
  String get sosPushUnconfirmed;

  /// No description provided for @sosRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded:'**
  String get sosRecordedAt;

  /// No description provided for @sosDirectContact.
  ///
  /// In en, this message translates to:
  /// **'Contact the person directly and call emergency services if immediate help is needed. ResQ does not dispatch responders.'**
  String get sosDirectContact;

  /// No description provided for @sosInboxDelivered.
  ///
  /// In en, this message translates to:
  /// **'Recorded in Circle members’ ResQ inboxes'**
  String get sosInboxDelivered;

  /// No description provided for @sosInboxDispatching.
  ///
  /// In en, this message translates to:
  /// **'Adding this SOS to Circle inboxes'**
  String get sosInboxDispatching;

  /// No description provided for @sosInboxNoRecipients.
  ///
  /// In en, this message translates to:
  /// **'No accepted Circle recipients are available'**
  String get sosInboxNoRecipients;

  /// No description provided for @sosInboxWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to add this SOS to Circle inboxes'**
  String get sosInboxWaiting;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to find nearby safe places.'**
  String get locationServicesOff;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow location to sort safe places by distance.'**
  String get locationPermissionNeeded;

  /// No description provided for @safePlacesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Safe places are unavailable'**
  String get safePlacesUnavailable;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionRetry;

  /// No description provided for @noVerifiedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No verified places within 5 km'**
  String get noVerifiedPlaces;

  /// No description provided for @placeCoverageIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Coverage may be incomplete. Emergency calling remains available from Home.'**
  String get placeCoverageIncomplete;

  /// No description provided for @placeCoverageLimited.
  ///
  /// In en, this message translates to:
  /// **'Search coverage is limited. Check official local sources before travelling.'**
  String get placeCoverageLimited;

  /// No description provided for @placePartialResults.
  ///
  /// In en, this message translates to:
  /// **'Showing part of the verified places in this area. Search coverage is limited.'**
  String get placePartialResults;

  /// No description provided for @locationNeededMap.
  ///
  /// In en, this message translates to:
  /// **'Location needed for the map'**
  String get locationNeededMap;

  /// No description provided for @findingPlaces.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby safe places…'**
  String get findingPlaces;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your ResQ account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your private data and report photos will be deleted. Public report summaries will be removed. This cannot be undone.'**
  String get deleteAccountExplanation;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountData.
  ///
  /// In en, this message translates to:
  /// **'Delete account and data'**
  String get deleteAccountData;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion could not finish. Please retry.'**
  String get deleteAccountFailed;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @localAlerts.
  ///
  /// In en, this message translates to:
  /// **'Local alerts'**
  String get localAlerts;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @districtExample.
  ///
  /// In en, this message translates to:
  /// **'For example, Khagaria'**
  String get districtExample;

  /// No description provided for @stateExample.
  ///
  /// In en, this message translates to:
  /// **'For example, Bihar'**
  String get stateExample;

  /// No description provided for @districtStateHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your district and state to match official alerts. Some sources have limited coverage.'**
  String get districtStateHelp;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @medicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Medical and accessibility details'**
  String get medicalDetails;

  /// No description provided for @saveInformation.
  ///
  /// In en, this message translates to:
  /// **'Save information'**
  String get saveInformation;

  /// No description provided for @informationSaved.
  ///
  /// In en, this message translates to:
  /// **'Your information was saved.'**
  String get informationSaved;

  /// No description provided for @informationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your information could not be saved.'**
  String get informationSaveFailed;

  /// No description provided for @informationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your information could not be loaded. Check your connection and try again.'**
  String get informationLoadFailed;

  /// No description provided for @signInEditInformation.
  ///
  /// In en, this message translates to:
  /// **'Sign in to edit your information.'**
  String get signInEditInformation;

  /// No description provided for @photoRetentionNotice.
  ///
  /// In en, this message translates to:
  /// **'Photo metadata is removed. Photos are scanned before private review, become inaccessible after 30 days, and are automatically deleted.'**
  String get photoRetentionNotice;

  /// No description provided for @photoPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Reports are private until moderated. Photos are scanned before moderator access, become inaccessible after 30 days, and are automatically deleted. You can delete your account and photos from Profile.'**
  String get photoPrivacyNotice;
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
