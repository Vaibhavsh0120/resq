import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/updates/presentation/updates_map.dart';
import 'package:resq/l10n/app_localizations.dart';
import 'package:resq/widgets/osm_map_attribution.dart';

void main() {
  testWidgets('map credit is visible below tiles without covering markers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: SizedBox(width: 390, child: UpdatesMap(isNearby: false)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final credit = find.byType(OsmMapAttribution);
    final map = find.byType(FlutterMap);
    expect(credit, findsOneWidget);
    expect(find.ancestor(of: credit, matching: map), findsNothing);
    expect(
      tester.getTopLeft(credit).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(map).dy),
    );
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(tester.getSize(credit).height, lessThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
