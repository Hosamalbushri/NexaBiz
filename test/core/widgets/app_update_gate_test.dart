import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_update_gate.dart';

void main() {
  group('AppUpdateInfo.compareVersions', () {
    test('compares version strings correctly', () {
      expect(AppUpdateInfo.compareVersions('1.4.0', '1.5.0'), lessThan(0));
      expect(AppUpdateInfo.compareVersions('1.5.0', '1.5.0'), equals(0));
      expect(AppUpdateInfo.compareVersions('1.5.1', '1.5.0'), greaterThan(0));
      expect(AppUpdateInfo.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('handles build suffixes correctly', () {
      expect(AppUpdateInfo.compareVersions('1.4.0+10', '1.4.0+12'), equals(0));
      expect(AppUpdateInfo.compareVersions('1.4.1+10', '1.4.0+12'), greaterThan(0));
    });
  });

  group('AppUpdateInfo policies', () {
    test('triggers mandatory update when current < minimumSupportedVersion', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        minimumSupportedVersion: '1.5.0',
      );

      expect(info.isMandatoryUpdate('1.4.0'), isTrue);
      expect(info.isMandatoryUpdate('1.5.0'), isFalse);
      expect(info.isMandatoryUpdate('1.6.0'), isFalse);
    });

    test('triggers mandatory update when forceUpdate is true', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        minimumSupportedVersion: '1.0.0',
        forceUpdate: true,
      );

      expect(info.isMandatoryUpdate('1.8.0'), isTrue);
    });

    test('triggers optional update when current < latestVersion and >= minimum', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        minimumSupportedVersion: '1.5.0',
      );

      expect(info.isOptionalUpdate('1.6.0'), isTrue);
      expect(info.isOptionalUpdate('2.0.0'), isFalse);
    });
  });
}
