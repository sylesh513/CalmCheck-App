/// tel: links. Nothing about a call is recorded — the app hands the number to
/// the dialler and forgets it.
///
/// Every launcher here reports whether the hand-off worked. A `canLaunchUrl`
/// gate used to sit in front of `launchUrl`, which made these buttons silently
/// dead on devices with no dialler (Wi-Fi iPads, many tablets) — the same
/// lesson `device_settings.dart` records. Now the launch is attempted and the
/// failure is surfaced, so a crisis button is never a no-op.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/legal.dart';

/// True when the hand-off to the dialler happened.
Future<bool> dial(String number) async {
  final cleaned = number.replaceAll(RegExp(r'[^0-9+*#]'), '');
  if (cleaned.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: cleaned);
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Dial, and say so when the device cannot: on a tablet with no phone app the
/// row must answer with the number to use elsewhere, not with silence.
Future<void> dialOrExplain(BuildContext context, String number) async {
  final ok = await dial(number);
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "This device can't place calls. From any phone, dial $number.",
      ),
      duration: const Duration(seconds: 6),
    ),
  );
}

/// True when a browser took the URL.
Future<bool> openWeb(String host) async {
  final uri = Uri.parse(host.startsWith('http') ? host : 'https://$host');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Open a page, and say so when nothing on the device could.
Future<void> openWebOrExplain(BuildContext context, String host) async {
  final ok = await openWeb(host);
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('No browser could be opened. The address is $host.'),
      duration: const Duration(seconds: 6),
    ),
  );
}

/// PAY-02. There is no server to receive a sponsorship application, so the
/// application is an email the person sends and can see in their own outbox.
Future<bool> composeSponsorApplication() async {
  final uri = Uri(
    scheme: 'mailto',
    path: LegalCopy.contact,
    queryParameters: {
      'subject': 'Sponsored access',
      'body':
          'I would like to apply for a sponsored year of CalmCheck Pro.\n\n'
          'You do not need to tell us anything about your situation. Add '
          'anything you want us to know below, or send this as it is.\n\n',
    },
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Support. An email the person composes and can see in their own outbox —
/// the app never sends anything on their behalf.
Future<bool> composeSupportEmail({String? body}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: LegalCopy.contact,
    queryParameters: {
      'subject': 'CalmCheck',
      if (body != null)
        'body': 'Anything you add here is what we see.\n\n$body',
    },
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
