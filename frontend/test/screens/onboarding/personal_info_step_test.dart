import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/models/user_profile.dart';
import 'package:resq/screens/onboarding/personal_info_step.dart';

void main() {
  testWidgets('reports a prefilled complete profile as valid', (tester) async {
    PersonalInfo? changed;
    bool? valid;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalInfoStep(
            initialValue: PersonalInfo(
              fullName: 'Alex Morgan',
              phoneNumber: '+12025550123',
              dateOfBirth: DateTime(1990, 5, 4),
              bloodType: BloodType.aPositive,
            ),
            onChanged: (value) => changed = value,
            onValidChanged: (value) => valid = value,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(valid, isTrue);
    expect(changed?.fullName, 'Alex Morgan');
    expect(find.text('May 4, 1990'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'A+'), findsOneWidget);
  });

  testWidgets('edits are emitted but incomplete data remains invalid', (
    tester,
  ) async {
    PersonalInfo? changed;
    bool? valid;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalInfoStep(
              initialValue: const PersonalInfo(),
              onChanged: (value) => changed = value,
              onValidChanged: (value) => valid = value,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Taylor');
    await tester.pump();
    expect(changed?.fullName, 'Taylor');
    expect(valid, isFalse);
  });

  testWidgets('country picker normalizes and validates the phone number', (
    tester,
  ) async {
    PersonalInfo? changed;
    bool? valid;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalInfoStep(
              initialValue: PersonalInfo(
                fullName: 'Taylor Morgan',
                dateOfBirth: DateTime(1990, 5, 4),
                bloodType: BloodType.oPositive,
              ),
              onChanged: (value) => changed = value,
              onValidChanged: (value) => valid = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('country-code-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search country or code'),
      'IN',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'IN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('phone-number-input')),
      '123',
    );
    await tester.pump();
    expect(valid, isFalse);
    expect(find.text('Invalid number for selected country'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('phone-number-input')),
      '9876543210',
    );
    await tester.pump();
    expect(changed?.phoneNumber, '+919876543210');
    expect(valid, isTrue);
  });
}
