/// "Open Settings" — the one thing to do about a denied permission. A state in
/// this app is never a dead end, so this has to work on both platforms without
/// depending on anything that might not build.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const MethodChannel _channel = MethodChannel('app.calmcheck/device_settings');

Future<void> openAppSettings() async {
  if (kIsWeb) return;
  if (Platform.isAndroid) {
    try {
      await _channel.invokeMethod<bool>('openAppSettings');
    } on PlatformException {
      // Nothing to fall back to; the caller's screen already offers the card
      // file instead.
    }
    return;
  }
  // iOS routes to this app's own page in Settings.
  // `canLaunchUrl` is deliberately not consulted: `app-settings:` is this
  // app's own Settings page, not a third-party scheme, and gating on
  // `canOpenURL` made the button silently dead.
  final uri = Uri.parse('app-settings:');
  try {
    await launchUrl(uri);
  } catch (_) {
    // Nothing to fall back to; the caller's screen already says what to do.
  }
}

Future<void> openNotificationSettings() async {
  if (kIsWeb) return;
  if (Platform.isAndroid) {
    try {
      await _channel.invokeMethod<bool>('openNotificationSettings');
    } on PlatformException {
      await openAppSettings();
    }
    return;
  }
  await openAppSettings();
}

/// Which country the phone is in, for the crisis helplines.
///
/// Asked of the network first, because somebody having a panic attack in a
/// country they are visiting needs the numbers for where they are standing,
/// not for the language their phone is set to. Android can answer without any
/// permission; iOS removed carrier country in iOS 16, so there the caller
/// falls back to the locale's region.
Future<String?> deviceCountryCode() async {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    final code = await _channel.invokeMethod<String>('countryCode');
    if (code == null || code.length != 2) return null;
    return code.toUpperCase();
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
