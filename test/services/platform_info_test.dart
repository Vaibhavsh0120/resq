import 'package:flutter_test/flutter_test.dart';
import 'package:resq/services/app_platform_info.dart';

void main() {
  test('resolves the test runtime to a known platform', () {
    expect(AppPlatformInfo.current, isNot(AppPlatform.unknown));
  });
}
