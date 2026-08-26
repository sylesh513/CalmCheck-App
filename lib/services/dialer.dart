/// tel: links. Nothing about a call is recorded — the app hands the number to
/// the dialler and forgets it.
library;

import 'package:url_launcher/url_launcher.dart';

Future<void> dial(String number) async {
  final cleaned = number.replaceAll(RegExp(r'[^0-9+*#]'), '');
  if (cleaned.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> openWeb(String host) async {
  final uri = Uri.parse(host.startsWith('http') ? host : 'https://$host');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// PAY-02. There is no server to receive a sponsorship application, so the
/// application is an email the person sends and can see in their own outbox.
Future<void> composeSponsorApplication() async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'hello@calmcheck.app',
    queryParameters: {
      'subject': 'Sponsored access',
      'body':
          'I would like to apply for a sponsored year of CalmCheck Pro.\n\n'
          'You do not need to tell us anything about your situation. Add '
          'anything you want us to know below, or send this as it is.\n\n',
    },
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Support. An email the person composes and can see in their own outbox —
/// the app never sends anything on their behalf.
Future<void> composeSupportEmail({String? body}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'hello@calmcheck.app',
    queryParameters: {
      'subject': 'CalmCheck',
      if (body != null)
        'body': 'Anything you add here is what we see.\n\n$body',
    },
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
