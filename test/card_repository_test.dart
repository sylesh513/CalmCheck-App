/// A care card is the one thing in this app a person cannot recreate from
/// memory in a hurry. These tests are about not losing one.
library;

import 'dart:convert';
import 'dart:io';

import 'fixtures/sample_cards.dart';
import 'package:calmcheck/models/care_card.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late CardRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('calmcheck-repo');
    repo = CardRepository(directory: dir);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  File primary() => File('${dir.path}/care-cards.json');
  File backup() => File('${dir.path}/care-cards.backup.json');

  test('an empty store loads nothing and reports itself healthy', () async {
    expect(await repo.load(prefs), isEmpty);
    expect(repo.health, CardStoreHealth.ok);
  });

  test('saves and reloads a card whole', () async {
    await repo.save([ravi]);
    final loaded = await repo.load(prefs);

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Ravi');
    expect(loaded.first.doThis, ravi.doThis);
    expect(loaded.first.dontDo, ravi.dontDo);
    expect(loaded.first.call.first.number, ravi.call.first.number);
  });

  test(
    'writes are versioned, so a future build knows what it is reading',
    () async {
      await repo.save([ravi]);
      final decoded =
          jsonDecode(primary().readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['schema'], cardSchemaVersion);
      expect(decoded['cards'], hasLength(1));
    },
  );

  test('keeps the previous contents as a backup on every write', () async {
    await repo.save([ravi]);
    await repo.save([ravi, aanya]);

    expect(backup().existsSync(), isTrue);
    final old = jsonDecode(backup().readAsStringSync()) as Map<String, dynamic>;
    expect(old['cards'], hasLength(1), reason: 'the copy is from before');
  });

  test('recovers from the backup when the primary file is corrupt', () async {
    await repo.save([ravi]);
    await repo.save([ravi, aanya]);
    primary().writeAsStringSync('{ this is not json');

    final loaded = await repo.load(prefs);

    expect(repo.health, CardStoreHealth.recoveredFromBackup);
    expect(loaded, hasLength(1));
    // The good copy is put back so the next read is clean.
    expect(await repo.load(prefs), hasLength(1));
    expect(repo.health, CardStoreHealth.ok);
  });

  test('quarantines an unreadable file rather than deleting it', () async {
    primary().writeAsStringSync('not json at all');

    final loaded = await repo.load(prefs);

    expect(loaded, isEmpty);
    expect(repo.health, CardStoreHealth.quarantined);
    expect(repo.quarantinedPath, isNotNull);
    expect(
      File(repo.quarantinedPath!).existsSync(),
      isTrue,
      reason: 'somebody\'s data is not ours to delete',
    );
  });

  test('one malformed card does not cost the others', () async {
    primary().writeAsStringSync(
      jsonEncode({
        'schema': cardSchemaVersion,
        'cards': [
          ravi.toJson(),
          {'nonsense': true},
          aanya.toJson(),
        ],
      }),
    );

    final loaded = await repo.load(prefs);
    expect(loaded.map((c) => c.name), ['Ravi', 'Aanya']);
  });

  test('refuses to read a file written by a newer build', () async {
    primary().writeAsStringSync(
      jsonEncode({
        'schema': cardSchemaVersion + 1,
        'cards': [ravi.toJson()],
      }),
    );

    final loaded = await repo.load(prefs);
    // Better to quarantine than to drop fields we do not understand on the
    // next write.
    expect(loaded, isEmpty);
    expect(repo.health, CardStoreHealth.quarantined);
  });

  test('migrates the pre-1.0 preferences blob exactly once', () async {
    SharedPreferences.setMockInitialValues({
      'cards': jsonEncode([ravi.toJson(), aanya.toJson()]),
    });
    prefs = await SharedPreferences.getInstance();

    final loaded = await repo.load(prefs);

    expect(loaded.map((c) => c.name), ['Ravi', 'Aanya']);
    expect(primary().existsSync(), isTrue, reason: 'moved to the file store');
    expect(prefs.getString('cards'), isNull, reason: 'and cleared from prefs');
  });

  test('a half-written temp file never becomes the store', () async {
    await repo.save([ravi]);
    File('${primary().path}.tmp').writeAsStringSync('{"schema":1,"cards":[');

    final loaded = await repo.load(prefs);
    expect(loaded, hasLength(1), reason: 'the real file is untouched');
  });

  test(
    'a photo path survives a round trip but never the share payload',
    () async {
      final withPhoto = ravi.copyWith(photoPath: '/tmp/photo.jpg');
      await repo.save([withPhoto]);

      final loaded = await repo.load(prefs);
      expect(loaded.first.photoPath, '/tmp/photo.jpg');
      expect(
        CareCardData.tryParseShareString(
          loaded.first.toShareString(),
        )!.photoPath,
        isNull,
      );
    },
  );
}
