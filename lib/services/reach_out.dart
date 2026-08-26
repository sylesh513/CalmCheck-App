/// Reaching your person.
///
/// Two verbs, and neither of them happens without a deliberate press:
///
/// * **Call** hands the number to the dialler.
/// * **Text** opens the messaging app with the words and, if a fix arrived in
///   time, a maps link — already written. The person presses send.
///
/// It cannot be otherwise, and that turns out to be right. iOS has no API to
/// send a message on somebody's behalf, and Play's SMS policy forbids a
/// non-messaging app from even declaring the permission. An app that texted
/// your sister without showing you what it said would be the wrong app anyway.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../models/personal_contact.dart';
import 'dialer.dart';
import 'whereabouts.dart';

Future<void> callPerson(PersonalContact contact) => dial(contact.number);

/// The words. Short, because it will be read on a lock screen by somebody who
/// has just been startled, and it has to say the three things that matter:
/// who, what, and whether they need to come.
String reachOutMessage({
  required PersonalContact contact,
  Whereabouts? whereabouts,
  String? senderName,
}) {
  final who = (senderName ?? '').trim().isEmpty ? 'I' : senderName!.trim();
  final buffer = StringBuffer()
    ..write(
      who == 'I'
          ? "I'm having a panic attack and I'd like you to know."
          : "$who is having a panic attack and wanted you to know.",
    );

  buffer.write(' Sent from CalmCheck.');

  if (whereabouts != null) {
    buffer.write('\n\nWhere I am right now: ${whereabouts.mapsLink}');
  }
  return buffer.toString();
}

/// Opens the messaging app with everything filled in. Returns false if no
/// messaging app could be opened, so the caller can say so instead of leaving
/// somebody staring at a button that did nothing.
Future<bool> textPerson({
  required PersonalContact contact,
  Whereabouts? whereabouts,
  String? senderName,
}) async {
  final body = reachOutMessage(
    contact: contact,
    whereabouts: whereabouts,
    senderName: senderName,
  );
  final number = contact.number.replaceAll(RegExp(r'[^0-9+*#]'), '');
  if (number.isEmpty) return false;

  // The separator is not the same on both platforms: iOS Messages only reads
  // the body after `&`, Android's messaging apps after `?`. Using `?` on iOS
  // opens Messages with an empty draft.
  final useAmpersand = !kIsWeb && Platform.isIOS;
  final separator = useAmpersand ? '&' : '?';
  final uri = Uri.parse(
    'sms:$number${separator}body=${Uri.encodeComponent(body)}',
  );
  try {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    // Fall through.
  }
  return false;
}
