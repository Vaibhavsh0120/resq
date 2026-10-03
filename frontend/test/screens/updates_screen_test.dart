import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/updates/application/alerts_providers.dart';
import 'package:resq/features/updates/application/india_events_providers.dart';
import 'package:resq/features/updates/data/alerts_repository.dart';
import 'package:resq/features/updates/data/india_events_repository.dart';
import 'package:resq/features/updates/domain/india_event.dart';
import 'package:resq/features/updates/domain/public_alert.dart';
import 'package:resq/features/updates/presentation/updates_screen.dart';
import 'package:resq/l10n/app_localizations.dart';
import 'package:resq/theme/app_theme.dart';

class _Nearby implements AlertsRepository {
  _Nearby(this.feed);
  final AlertFeed feed;
  @override
  Stream<AlertFeed> watchActive() => Stream.value(feed);
}

class _India implements IndiaEventsRepository {
  _India(this.feed, {this.fails = false});
  final IndiaEventFeed feed;
  final bool fails;
  @override
  Stream<IndiaEventFeed> watchRecent() =>
      fails ? Stream.error(StateError('offline')) : Stream.value(feed);
}

Future<void> _pump(
  WidgetTester tester, {
  required AlertFeed nearby,
  required IndiaEventFeed india,
  bool indiaFails = false,
  Size size = const Size(900, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertsRepositoryProvider.overrideWithValue(_Nearby(nearby)),
        indiaEventsRepositoryProvider.overrideWithValue(
          _India(india, fails: indiaFails),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: UpdatesScreen()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  test('India event model rejects an invented or expired map point', () {
    final live = IndiaEvent.fromMap({
      'id': 'gdacs-FL-4-2',
      'title': 'Flood in India',
      'eventType': 'FL',
      'latitude': 30.0203,
      'longitude': 79.0499,
      'sourceUrl': 'https://www.gdacs.org/report.aspx?eventid=4',
      'countryLabel': 'India',
      'alertLevel': 'Orange',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'relevanceEndsAt': DateTime.now()
          .toUtc()
          .add(const Duration(days: 1))
          .toIso8601String(),
    });
    expect(live, isNotNull);
    expect(live!.latitude, 30.0203);
    expect(
      IndiaEvent.fromMap({
        'id': 'bad',
        'title': 'Unlocated',
        'latitude': 1000,
        'longitude': 79,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'relevanceEndsAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      }),
      isNull,
    );
    expect(
      IndiaEvent.fromMap({
        'id': 'bad-type',
        'title': 'Unlocated',
        'latitude': 'north',
        'longitude': 79,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'relevanceEndsAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      }),
      isNull,
    );
  });

  testWidgets(
    'switching views swaps coverage point for published event point',
    (tester) async {
      final alert = PublicAlert(
        id: 'ndma-1',
        titles: const {'en': 'Delhi flood warning'},
        summaries: const {'en': 'Avoid the river.'},
        severity: 'warning',
        source: 'NDMA SACHET',
        issuedAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 3)),
        verified: true,
        area: 'New Delhi, Delhi',
      );
      final event = IndiaEvent.fromMap({
        'id': 'gdacs-FL-4-2',
        'title': 'Flood in Uttarakhand',
        'eventType': 'FL',
        'latitude': 30.0203,
        'longitude': 79.0499,
        'sourceUrl': 'https://www.gdacs.org/report.aspx?eventid=4',
        'countryLabel': 'India',
        'alertLevel': 'Orange',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'relevanceEndsAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      })!;
      await _pump(
        tester,
        nearby: AlertFeed(
          items: [alert],
          homeLatitude: 28.6139,
          homeLongitude: 77.209,
        ),
        india: IndiaEventFeed(
          items: [event],
          status: 'ok',
          lastCheckedAt: DateTime.now().toUtc(),
        ),
      );
      expect(
        find.byKey(const ValueKey('nearby-coverage-marker')),
        findsOneWidget,
      );
      expect(find.text('Delhi flood warning'), findsOneWidget);
      await tester.tap(find.text('Across India'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byKey(const ValueKey('india-event-gdacs-FL-4-2')),
        findsOneWidget,
      );
      expect(find.text('Flood in Uttarakhand'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nearby-coverage-marker')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('india-event-gdacs-FL-4-2')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Open GDACS report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing home coordinates keeps alerts usable and India failure is isolated',
    (tester) async {
      final alert = PublicAlert(
        id: 'ndma-2',
        titles: const {'en': 'Local warning'},
        summaries: const {},
        severity: 'warning',
        source: 'NDMA SACHET',
        issuedAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 3)),
        verified: true,
      );
      await _pump(
        tester,
        nearby: AlertFeed(items: [alert]),
        india: const IndiaEventFeed(),
        indiaFails: true,
      );
      expect(find.text('Local warning'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nearby-coverage-marker')),
        findsNothing,
      );
      await tester.tap(find.text('Across India'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('India-wide updates are unavailable'), findsOneWidget);
    },
  );

  testWidgets(
    'compact India empty state remains usable without a fabricated pin',
    (tester) async {
      await _pump(
        tester,
        nearby: const AlertFeed(),
        india: const IndiaEventFeed(status: 'ok'),
        size: const Size(390, 844),
      );
      await tester.tap(find.text('Across India'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No recent India-wide disaster events'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nearby-coverage-marker')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('missing home offers a direct setup action', (tester) async {
    await _pump(
      tester,
      nearby: const AlertFeed(coverage: 'home_region_missing'),
      india: const IndiaEventFeed(),
    );
    expect(
      find.widgetWithText(FilledButton, 'Set your home location'),
      findsOneWidget,
    );
  });
}
