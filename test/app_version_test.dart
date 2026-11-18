import 'package:flutter_test/flutter_test.dart';
import 'package:swaraguru/app_version.dart';

void main() {
  group('AppVersion', () {
    test('reads Flutter version.json manifests', () {
      expect(
        AppVersion.fromManifest({
          'version': '1.2.3',
          'build_number': '45',
        }),
        '1.2.3+45',
      );
    });

    test('recognizes newer semantic versions and build numbers', () {
      expect(AppVersion.isNewer('1.0.1+1', current: '1.0.0+99'), isTrue);
      expect(AppVersion.isNewer('1.0.0+10', current: '1.0.0+9'), isTrue);
      expect(AppVersion.isNewer('1.0.0+9', current: '1.0.0+9'), isFalse);
      expect(AppVersion.isNewer('1.0.0+8', current: '1.0.0+9'), isFalse);
    });
  });
}
