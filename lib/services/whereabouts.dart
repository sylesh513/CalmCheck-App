/// "Text them where I am."
///
/// The one place this app asks where somebody is, and it asks at the moment
/// they press the button — never before, never in the background. The fix goes
/// into a message they send from their own messaging app; it is not stored, and
/// there is nowhere for it to be uploaded to.
///
/// A fix that does not arrive quickly is not worth waiting for. GPS indoors can
/// take a minute, and somebody mid-panic-attack does not have one, so the
/// message goes without it rather than making them wait.
///
/// Implemented as a channel this app owns rather than a plugin, for the same
/// reason as `device_settings.dart`: it is thirty lines of platform code and it
/// keeps the permission surface exactly as narrow as the feature needs.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('app.calmcheck/device_settings');

@immutable
class Whereabouts {
  const Whereabouts({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Opens in whatever map app the recipient already has.
  String get mapsLink =>
      'https://maps.google.com/?q=${latitude.toStringAsFixed(5)},'
      '${longitude.toStringAsFixed(5)}';
}

/// Null whenever location is unavailable, declined, switched off, or slow.
/// Every one of those is an ordinary outcome, not an error to show anybody.
///
/// The timeout is the budget for the *fix*, not for the person: on a first
/// use the OS permission dialog appears, and reading it takes longer than any
/// sensible fix budget. So when a prompt is coming, the wait is extended —
/// the dialog already holds their attention, and cutting it off used to throw
/// away the location on exactly the occasion it was just granted.
Future<Whereabouts?> currentWhereabouts({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;

  var promptComing = false;
  try {
    promptComing =
        await _channel.invokeMethod<bool>('locationPromptNeeded') ?? false;
  } catch (_) {
    // An older native side without the method: keep the plain budget.
  }
  final budget = promptComing ? const Duration(seconds: 90) : timeout;

  try {
    final fix = await _channel
        .invokeMapMethod<String, double>('currentLocation')
        .timeout(budget);
    final latitude = fix?['latitude'];
    final longitude = fix?['longitude'];
    if (latitude == null || longitude == null) return null;
    return Whereabouts(latitude: latitude, longitude: longitude);
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  } on TimeoutException {
    return null;
  }
}
