// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ResQ';

  @override
  String get home => 'Home';

  @override
  String get updates => 'Updates';

  @override
  String get report => 'Report';

  @override
  String get family => 'Family';

  @override
  String get places => 'Places';

  @override
  String get profileSettings => 'Profile and settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get homeSubtitle => 'Your safety tools in one place';

  @override
  String get emergencyAccessReady => 'Emergency access is ready';

  @override
  String get goodToSeeYouSafe => 'Good to see you safe';

  @override
  String get emergencySos => 'Emergency SOS';

  @override
  String get activeVerifiedAlert => 'Active verified alert';

  @override
  String get yourReadinessPlan => 'Your readiness plan';

  @override
  String get signInSavePlan => 'Sign in to save your emergency plan.';

  @override
  String get askResq => 'Ask ResQ';

  @override
  String get assistantPrompt => 'How can I help you prepare?';

  @override
  String get updatesSubtitle => 'Local alerts and India-wide disaster events';

  @override
  String get reportSubtitle =>
      'Share what is happening without putting yourself at risk';

  @override
  String get familySubtitle => 'Emergency contacts and accepted Circle members';

  @override
  String get placesSubtitle => 'Verified help within 5 km';

  @override
  String get resqAssistant => 'ResQ assistant';

  @override
  String get voiceAssistant => 'Voice assistant';

  @override
  String get startVoiceAssistant => 'Start voice assistant';

  @override
  String get newConversation => 'New conversation';

  @override
  String get noSavedConversations =>
      'No saved conversations yet. Start one to build your history.';

  @override
  String get messageResq => 'Message ResQ';

  @override
  String get sendMessage => 'Send message';

  @override
  String get yourReadiness => 'Your readiness';

  @override
  String get yourInformation => 'Your information';

  @override
  String get manageMyCircle => 'Manage My Circle';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get sosHistory => 'SOS history';

  @override
  String get privacyAiAccess => 'Privacy and AI data access';

  @override
  String get language => 'Language — English / हिन्दी';

  @override
  String get appearance => 'Appearance';

  @override
  String get logout => 'Log out';

  @override
  String get getGuidance => 'Get guidance';

  @override
  String get submitPrivateReport => 'Submit private report';

  @override
  String get call112 => 'Call 112';

  @override
  String get directions => 'Directions';

  @override
  String get tryAgain => 'Try again';

  @override
  String get assistantUnavailable =>
      'Assistant unavailable. Emergency calling and saved guidance remain available.';

  @override
  String get assistantDailyLimit =>
      'Daily assistant limit reached. Try again tomorrow.';

  @override
  String get assistantTurnsLeft => 'assistant turns left today';

  @override
  String get assistantConnectionFailure =>
      'The assistant could not connect. Try again later.';

  @override
  String get homeAlertRegion => 'Alerts for your saved home region';

  @override
  String get nearbyUpdates => 'Nearby';

  @override
  String get acrossIndia => 'Across India';

  @override
  String get indiaDisasterEvents => 'Disaster events across India';

  @override
  String get homeCoverageMarker => 'Alerts affecting your saved home area';

  @override
  String get homeCoverageExplanation =>
      'This pin marks your saved home location for alert coverage. It is not where the incident happened.';

  @override
  String get noHomeMapPoint =>
      'Add your home location to show alert coverage on the map.';

  @override
  String get indiaEventNotLocalWarning =>
      'These events may affect India. They are not warnings for your saved home area.';

  @override
  String get openGdacsReport => 'Open GDACS report';

  @override
  String get indiaUpdatesUnavailable => 'India-wide updates are unavailable';

  @override
  String get noIndiaEvents => 'No recent India-wide disaster events';

  @override
  String get indiaFeedDelayed => 'India-wide feed may be delayed';

  @override
  String get indiaFeedChecked => 'India-wide feed checked';

  @override
  String get updatesUnavailable => 'Updates are unavailable';

  @override
  String get updatesRetry =>
      'Pull down to try again. Previously received emergency guidance remains available.';

  @override
  String get setHomeLocation => 'Set your home location';

  @override
  String get noMatchingAlerts => 'No matching active alerts';

  @override
  String get addDistrictState =>
      'Add a district and state in your profile to see local alerts.';

  @override
  String get noAlertsSafetyNotice =>
      'This does not mean your area is safe. Check the official SACHET feed for more coverage.';

  @override
  String get feedDelayed => 'Feed coverage may be delayed';

  @override
  String get feedChecked => 'Official feed checked';

  @override
  String get noFeedRefresh => 'No source has refreshed yet.';

  @override
  String sourceUnavailable(String source, String status) {
    return '$source: unavailable ($status)';
  }

  @override
  String get sourceNotConfigured => 'not configured';

  @override
  String get sourceRefreshFailed => 'refresh failed';

  @override
  String get sourceCoveragePartial => 'partial coverage';

  @override
  String get sourceNotChecked => 'not checked yet';

  @override
  String alertValidFor(String duration) {
    return 'Valid for $duration';
  }

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationHours(int count) {
    return '$count hr';
  }

  @override
  String durationDays(int count) {
    return '$count days';
  }

  @override
  String get expired => 'expired';

  @override
  String get alertViewLimited =>
      'This region has more alerts than this view can show.';

  @override
  String get openSachet => 'Open official SACHET alerts';

  @override
  String get aiResponseLabel => 'ResQ AI';

  @override
  String get sourcesProvided => 'Sources provided to the assistant';

  @override
  String get sosRecording =>
      'Digital SOS is being recorded. Call 112 for immediate help.';

  @override
  String get sosUnconfirmedHelp =>
      'ResQ could not confirm the online record. Calling 112 and SMS sharing are still available.';

  @override
  String get sosNoRecipients =>
      'SOS recorded. No accepted Family Circle recipients are available. Call 112 if you need immediate help.';

  @override
  String get sosDeliveryPending =>
      'SOS recorded. Digital delivery is pending. Call 112 if you need immediate help.';

  @override
  String get sosInboxesRecorded =>
      'SOS recorded in Circle inboxes. Push delivery is not guaranteed. Call 112 if you need immediate help.';

  @override
  String get sosTitle => 'Emergency SOS';

  @override
  String get sosSending => 'Sending digital SOS';

  @override
  String get sosRecorded => 'SOS recorded';

  @override
  String get sosDigitalUnconfirmed => 'Digital SOS unconfirmed';

  @override
  String get sosCountdown => 'Sending SOS in';

  @override
  String get sosActivate => 'Tap or hold to start SOS countdown';

  @override
  String get sosCancelNotice =>
      'You have five seconds to cancel before ResQ records the event.';

  @override
  String get sosCancel => 'Cancel SOS';

  @override
  String get sosCountdownCancelled => 'SOS countdown cancelled.';

  @override
  String get sosSmsHelp => 'Ask for help by SMS';

  @override
  String get sosSmsBody => 'I need emergency help.';

  @override
  String get sosMyLocation => 'My location:';

  @override
  String get phoneAppUnavailable => 'No compatible phone app is available.';

  @override
  String get sosEventTitle => 'SOS event';

  @override
  String get sosEventUnavailable =>
      'This SOS event is unavailable or you do not have access.';

  @override
  String get sosEventMissing => 'This SOS event was not found.';

  @override
  String get sosCircleActivated => 'A Family Circle member activated SOS';

  @override
  String get sosPushUnconfirmed =>
      'A push attempt does not confirm that anyone received or read this SOS.';

  @override
  String get sosRecordedAt => 'Recorded:';

  @override
  String get sosDirectContact =>
      'Contact the person directly and call emergency services if immediate help is needed. ResQ does not dispatch responders.';

  @override
  String get sosInboxDelivered => 'Recorded in Circle members’ ResQ inboxes';

  @override
  String get sosInboxDispatching => 'Adding this SOS to Circle inboxes';

  @override
  String get sosInboxNoRecipients =>
      'No accepted Circle recipients are available';

  @override
  String get sosInboxWaiting => 'Waiting to add this SOS to Circle inboxes';

  @override
  String get locationUnavailable => 'Location is unavailable';

  @override
  String get locationServicesOff =>
      'Turn on location services to find nearby safe places.';

  @override
  String get locationPermissionNeeded =>
      'Allow location to sort safe places by distance.';

  @override
  String get safePlacesUnavailable => 'Safe places are unavailable';

  @override
  String get checkConnectionRetry => 'Check your connection and try again.';

  @override
  String get noVerifiedPlaces => 'No verified places within 5 km';

  @override
  String get placeCoverageIncomplete =>
      'Coverage may be incomplete. Emergency calling remains available from Home.';

  @override
  String get placeCoverageLimited =>
      'Search coverage is limited. Check official local sources before travelling.';

  @override
  String get placePartialResults =>
      'Showing part of the verified places in this area. Search coverage is limited.';

  @override
  String get locationNeededMap => 'Location needed for the map';

  @override
  String get findingPlaces => 'Finding nearby safe places…';

  @override
  String get deleteAccountTitle => 'Delete your ResQ account?';

  @override
  String get deleteAccountExplanation =>
      'Your private data and report photos will be deleted. Public report summaries will be removed. This cannot be undone.';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get deleteAccountData => 'Delete account and data';

  @override
  String get deleteAccountFailed => 'Deletion could not finish. Please retry.';

  @override
  String get cancel => 'Cancel';

  @override
  String get localAlerts => 'Local alerts';

  @override
  String get district => 'District';

  @override
  String get state => 'State';

  @override
  String get districtExample => 'For example, Khagaria';

  @override
  String get stateExample => 'For example, Bihar';

  @override
  String get districtStateHelp =>
      'Enter your district and state to match official alerts. Some sources have limited coverage.';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get medicalDetails => 'Medical and accessibility details';

  @override
  String get saveInformation => 'Save information';

  @override
  String get informationSaved => 'Your information was saved.';

  @override
  String get informationSaveFailed => 'Your information could not be saved.';

  @override
  String get informationLoadFailed =>
      'Your information could not be loaded. Check your connection and try again.';

  @override
  String get signInEditInformation => 'Sign in to edit your information.';

  @override
  String get photoRetentionNotice =>
      'Photo metadata is removed. Photos need screening before private review. Access ends after 30 days; operators run deletion manually.';

  @override
  String get photoPrivacyNotice =>
      'Reports are private until moderated. Operators screen photos before access and run deletion manually after 30 days. You can delete your account and photos from Profile.';

  @override
  String get gdacsAttribution =>
      'Global Disaster Awareness and Coordination System (GDACS)';

  @override
  String get signInForUpdates => 'Sign in';
}
