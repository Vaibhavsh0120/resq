import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/assistant/domain/voice_turn_policy.dart';

void main() {
  test('headphones allow spoken interruption while speaker mode waits', () {
    expect(canListenDuringSpeech(headphonesMode: true), isTrue);
    expect(canListenDuringSpeech(headphonesMode: false), isFalse);
  });
}
