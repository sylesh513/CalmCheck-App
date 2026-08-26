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
Future<Whereabouts?> currentWhereabouts({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
  try {
    final fix = await _channel
        .invokeMapMethod<String, double>('currentLocation')
        .timeout(timeout);
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
