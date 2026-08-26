/// Runs on a real device or simulator, in the app's own process, with the real
/// plugins registered.
///
/// It exists for the platform code this app owns rather than imports: the
/// Swift and Kotlin behind `app.calmcheck/device_settings`. A unit test cannot
/// see any of it, and a channel that is not registered fails silently — the
/// Dart side catches MissingPluginException and answers null, which looks
/// exactly like "no fix available".
///
///     flutter test integration_test/platform_channels_test.dart -d <device>
library;

import 'dart:io' show Platform;

import 'package:calmcheck/services/whereabouts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const MethodChannel channel = MethodChannel('app.calmcheck/device_settings');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the location channel is registered on this platform',
      (tester) async {
    await tester.runAsync(() async {
      try {
        await channel.invokeMethod<Map<Object?, Object?>>('currentLocation');
      } on MissingPluginException {
        fail('app.calmcheck/device_settings has no native handler — the '
            'plugin did not register, and every location would silently come '
            'back null');
      } on PlatformException {
        // A refusal is a real answer from real native code.
      }
    });
  });

  testWidgets('a fix comes back as usable coordinates', (tester) async {
    // Set one first:
    //   xcrun simctl location <udid> set 51.50733,-0.12775
    //   adb emu geo fix -0.12775 51.50733
    await tester.runAsync(() async {
      final where = await currentWhereabouts(
        timeout: const Duration(seconds: 12),
      );
      if (where == null) {
        // Ordinary on a device with no fix, and the app is built for it.
        debugPrint('CHANNEL CHECK: no fix available');
        return;
      }
      debugPrint('CHANNEL CHECK: ${where.mapsLink}');
      expect(where.latitude.abs(), lessThanOrEqualTo(90));
      expect(where.longitude.abs(), lessThanOrEqualTo(180));
      expect(where.mapsLink, startsWith('https://maps.google.com/?q='));
      expect(where.mapsLink, contains(','));
    });
  });

  testWidgets('the country channel answers on Android and defers on iOS',
      (tester) async {
    await tester.runAsync(() async {
      try {
        final code = await channel.invokeMethod<String>('countryCode');
        expect(Platform.isAndroid, isTrue,
            reason: 'only Android implements this');
        if (code != null) expect(code.length, 2);
      } on MissingPluginException {
        // iOS answers FlutterMethodNotImplemented, which Flutter surfaces as
        // MissingPluginException — the documented behaviour here, because iOS
        // 16 removed carrier country and the Dart side falls back to the
        // locale's region.
        expect(Platform.isIOS, isTrue,
            reason: 'Android must implement countryCode');
      }
    });
  });
}
