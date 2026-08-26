/// Card files. The counterpart to the QR code, for anyone whose camera can't
/// be used — a plain text file carrying the same payload, opened from wherever
/// the phone keeps files. Still no account and still no network.
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../models/care_card.dart';

const String cardFileExtension = 'calmcheck';

Future<File> writeCardFile(CareCardData card) async {
  final dir = await getApplicationDocumentsDirectory();
  final safeName = card.name
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .toLowerCase();
  final file = File('${dir.path}/$safeName-care-card.$cardFileExtension');
  await file.writeAsString(card.toShareString());
  return file;
}

/// Returns the card, or null when the file isn't a CalmCheck card. The caller
/// shows the same "not a CalmCheck card" state the scanner does.
Future<CareCardData?> openCardFile() async {
  const group = XTypeGroup(
    label: 'CalmCheck card',
    extensions: [cardFileExtension, 'txt', 'json'],
  );
  final file = await openFile(acceptedTypeGroups: const [group]);
  if (file == null) return null;
  final raw = (await file.readAsString()).trim();
  return CareCardData.tryParseShareString(raw);
}
