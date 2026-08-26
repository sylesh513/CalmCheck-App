/// Where care cards actually live.
///
/// A care card is the only thing in this app that a person cannot recreate from
/// memory in a hurry, so the storage is written to survive: atomic writes, a
/// previous-good copy, and a quarantine for anything that fails to parse. A
/// decode error must never silently discard somebody's cards.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/care_card.dart';

/// Bumped when the on-disk shape changes. Every reader must handle every
/// version it has ever written.
const int cardSchemaVersion = 1;

/// What happened the last time the store was read. Surfaced in Settings so a
/// person is told when something went wrong with their own data rather than
/// finding an empty shelf.
enum CardStoreHealth {
  /// Loaded from the primary file, or there was nothing to load yet.
  ok,

  /// The primary file was unreadable and the previous-good copy was used.
  recoveredFromBackup,

  /// Neither copy could be read. The unreadable file has been kept.
  quarantined,
}

class CardRepository {
  CardRepository({@visibleForTesting Directory? directory})
    : _override = directory;

  final Directory? _override;
  Directory? _dir;

  CardStoreHealth health = CardStoreHealth.ok;

  /// Set when a file was quarantined, so Settings can name it.
  String? quarantinedPath;

  static const String _fileName = 'care-cards.json';
  static const String _backupName = 'care-cards.backup.json';
  static const String _legacyPrefsKey = 'cards';

  Future<Directory> _directory() async {
    if (_dir != null) return _dir!;
    if (_override != null) return _dir = _override;
    try {
      return _dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // No documents directory — a test host, or a device in a strange state.
      // Somewhere writable beats refusing to run.
      final fallback = Directory('${Directory.systemTemp.path}/calmcheck');
      if (!fallback.existsSync()) fallback.createSync(recursive: true);
      return _dir = fallback;
    }
  }

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');
  Future<File> _backup() async =>
      File('${(await _directory()).path}/$_backupName');

  /// Reads every card, migrating from the pre-1.0 preferences blob if that is
  /// all that exists.
  Future<List<CareCardData>> load(SharedPreferences prefs) async {
    health = CardStoreHealth.ok;
    quarantinedPath = null;

    final file = await _file();
    if (file.existsSync()) {
      final primary = _tryDecode(await _read(file));
      if (primary != null) return primary;

      // The primary file is unreadable. Try the copy from before the last
      // successful write.
      final backup = await _backup();
      if (backup.existsSync()) {
        final recovered = _tryDecode(await _read(backup));
        if (recovered != null) {
          health = CardStoreHealth.recoveredFromBackup;
          // Put the good copy back in place so the next read is clean.
          await _writeAtomic(file, await _read(backup));
          return recovered;
        }
      }

      // Keep the unreadable file. It is somebody's data; it is not ours to
      // delete because we could not parse it.
      health = CardStoreHealth.quarantined;
      quarantinedPath = await _quarantine(file);
      return const [];
    }

    // Nothing on disk. Migrate the pre-1.0 preferences blob if it is there.
    final legacy = prefs.getString(_legacyPrefsKey);
    if (legacy != null) {
      final migrated = _tryDecodeCardList(legacy);
      if (migrated != null) {
        await save(migrated);
        await prefs.remove(_legacyPrefsKey);
        return migrated;
      }
      // Unparseable legacy data: keep it in preferences rather than dropping
      // it, and start clean.
      health = CardStoreHealth.quarantined;
      return const [];
    }

    return const [];
  }

  /// Writes atomically, keeping the previous contents as the backup. A crash
  /// mid-write can lose the newest edit, never the whole shelf.
  Future<void> save(List<CareCardData> cards) async {
    final file = await _file();
    final payload = const JsonEncoder().convert({
      'schema': cardSchemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'cards': cards.map((c) => c.toJson()).toList(),
    });

    if (file.existsSync()) {
      try {
        await file.copy((await _backup()).path);
      } catch (_) {
        // A missing backup is survivable; a failed primary write is not.
      }
    }
    await _writeAtomic(file, payload);
  }

  Future<void> _writeAtomic(File file, String contents) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(file.path);
  }

  Future<String> _read(File file) async {
    try {
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  Future<String?> _quarantine(File file) async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final target = '${file.path}.unreadable-$stamp';
      await file.rename(target);
      return target;
    } catch (_) {
      return null;
    }
  }

  /// The versioned envelope.
  List<CareCardData>? _tryDecode(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final schema = decoded['schema'] as int? ?? 0;
      if (schema > cardSchemaVersion) {
        // Written by a newer build. Refusing to read is safer than dropping
        // fields we do not understand on the next write.
        return null;
      }
      final list = decoded['cards'];
      if (list is! List) return null;
      return _parseCards(list);
    } catch (_) {
      return null;
    }
  }

  /// The pre-1.0 shape: a bare JSON array in preferences.
  List<CareCardData>? _tryDecodeCardList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return _parseCards(decoded);
    } catch (_) {
      return null;
    }
  }

  /// One malformed card does not cost the others.
  List<CareCardData> _parseCards(List<dynamic> list) {
    final cards = <CareCardData>[];
    for (final entry in list) {
      try {
        cards.add(
          CareCardData.fromJson(Map<String, dynamic>.from(entry as Map)),
        );
      } catch (_) {
        continue;
      }
    }
    return cards;
  }
}
