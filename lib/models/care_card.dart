/// A care card is a panic flow you prepared in advance, for someone else.
///
/// The field order below is the fixed information order, identical on screen
/// and on paper: who this is, WHAT TO DO, DO NOT, CALL, then everything else.
library;

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/widgets.dart';

@immutable
class CareContact {
  const CareContact({required this.name, this.relationship = '', this.number});

  final String name;
  final String relationship;

  /// Null when no number has been saved yet — the row says so rather than
  /// pretending the field isn't there.
  final String? number;

  bool get hasNumber => (number ?? '').trim().isNotEmpty;

  CareContact copyWith({String? name, String? relationship, String? number}) =>
      CareContact(
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        number: number ?? this.number,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    if (number != null) 'number': number,
  };

  factory CareContact.fromJson(Map<String, dynamic> json) => CareContact(
    name: json['name'] as String? ?? '',
    relationship: json['relationship'] as String? ?? '',
    number: json['number'] as String?,
  );
}

@immutable
class CareCardData {
  const CareCardData({
    required this.id,
    required this.name,
    this.relation = '',
    this.livesWith = '',
    this.doThis = const [],
    this.dontDo = const [],
    this.call = const [],
    this.medications = '',
    this.triggers = '',
    this.notes = '',
    this.photoPath,
    this.version = 1,
    required this.preparedAt,
    this.readOnly = false,
    this.sharedBy,
  });

  final String id;
  final String name;
  final String relation;
  final String livesWith;
  final List<String> doThis;
  final List<String> dontDo;
  final List<CareContact> call;
  final String medications;
  final String triggers;
  final String notes;

  /// An absolute path inside the app's own documents directory. Never a URL.
  final String? photoPath;
  final int version;
  final DateTime preparedAt;

  /// A received card. No edit affordance; the owner keeps the original.
  final bool readOnly;
  final String? sharedBy;

  /// A card left behind by an earlier build that shipped two bundled
  /// examples. Nothing creates these any more; they are cleared on load.
  bool get isSample => id.startsWith('sample-');

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  /// One glanceable signal of who the card is for, for the home shelf. Two
  /// cards must be tellable apart at a glance.
  String get signal {
    if (relation.trim().isNotEmpty) return relation;
    if (livesWith.trim().isNotEmpty) return livesWith;
    return 'Care card';
  }

  /// "Prepared 4 March · version 3 · on this device only"
  String get meta {
    final d = '${preparedAt.day} ${_months[preparedAt.month - 1]}';
    return 'Prepared $d · version $version · on this device only';
  }

  bool get isNamed => name.trim().isNotEmpty;

  /// A minimal card is not a broken card — it just hasn't been filled in yet.
  bool get hasAbout =>
      livesWith.trim().isNotEmpty ||
      medications.trim().isNotEmpty ||
      triggers.trim().isNotEmpty ||
      notes.trim().isNotEmpty;

  CareCardData copyWith({
    String? id,
    String? name,
    String? relation,
    String? livesWith,
    List<String>? doThis,
    List<String>? dontDo,
    List<CareContact>? call,
    String? medications,
    String? triggers,
    String? notes,
    String? photoPath,
    bool clearPhoto = false,
    int? version,
    DateTime? preparedAt,
    bool? readOnly,
    String? sharedBy,
  }) => CareCardData(
    id: id ?? this.id,
    name: name ?? this.name,
    relation: relation ?? this.relation,
    livesWith: livesWith ?? this.livesWith,
    doThis: doThis ?? this.doThis,
    dontDo: dontDo ?? this.dontDo,
    call: call ?? this.call,
    medications: medications ?? this.medications,
    triggers: triggers ?? this.triggers,
    notes: notes ?? this.notes,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    version: version ?? this.version,
    preparedAt: preparedAt ?? this.preparedAt,
    readOnly: readOnly ?? this.readOnly,
    sharedBy: sharedBy ?? this.sharedBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'livesWith': livesWith,
    'doThis': doThis,
    'dontDo': dontDo,
    'call': call.map((c) => c.toJson()).toList(),
    'medications': medications,
    'triggers': triggers,
    'notes': notes,
    if (photoPath != null) 'photoPath': photoPath,
    'version': version,
    'preparedAt': preparedAt.toIso8601String(),
    'readOnly': readOnly,
    if (sharedBy != null) 'sharedBy': sharedBy,
  };

  factory CareCardData.fromJson(Map<String, dynamic> json) => CareCardData(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    relation: json['relation'] as String? ?? '',
    livesWith: json['livesWith'] as String? ?? '',
    doThis: _stringList(json['doThis']),
    dontDo: _stringList(json['dontDo']),
    call:
        (json['call'] as List?)
            ?.map(
              (e) => CareContact.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [],
    medications: json['medications'] as String? ?? '',
    triggers: json['triggers'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    photoPath: json['photoPath'] as String?,
    version: json['version'] as int? ?? 1,
    preparedAt:
        DateTime.tryParse(json['preparedAt'] as String? ?? '') ??
        DateTime.now(),
    readOnly: json['readOnly'] as bool? ?? false,
    sharedBy: json['sharedBy'] as String?,
  );

  /// The payload behind the QR code. Everything the receiving phone needs; no
  /// URL, no lookup, no network — which is why a shared card works with no
  /// signal at either end.
  ///
  /// The code has to scan from a screen at arm's length in poor light, so the
  /// payload is kept as small as it can be: single-letter keys, then gzip, then
  /// base64. The photo lives at a path on *this* device and is deliberately
  /// left out.
  String toShareString() {
    final compact = <String, dynamic>{
      'i': id,
      'n': name,
      if (relation.isNotEmpty) 'r': relation,
      if (livesWith.isNotEmpty) 'w': livesWith,
      if (doThis.isNotEmpty) 'd': doThis,
      if (dontDo.isNotEmpty) 'x': dontDo,
      if (call.isNotEmpty)
        'c': [
          for (final c in call) [c.name, c.relationship, c.number ?? ''],
        ],
      if (medications.isNotEmpty) 'm': medications,
      if (triggers.isNotEmpty) 't': triggers,
      if (notes.isNotEmpty) 'o': notes,
      'v': version,
      'p': preparedAt.millisecondsSinceEpoch ~/ 86400000,
    };
    final zipped = gzip.encode(utf8.encode(jsonEncode(compact)));
    return '$_sharePrefix${base64Url.encode(zipped)}';
  }

  /// Returns null when the scanned code isn't a CalmCheck card.
  static CareCardData? tryParseShareString(String raw) {
    if (!raw.startsWith(_sharePrefix)) return null;
    try {
      final zipped = base64Url.decode(raw.substring(_sharePrefix.length));
      final json = utf8.decode(gzip.decode(zipped));
      final m = jsonDecode(json) as Map<String, dynamic>;
      return CareCardData(
        id: m['i'] as String,
        name: m['n'] as String? ?? '',
        relation: m['r'] as String? ?? '',
        livesWith: m['w'] as String? ?? '',
        doThis: _stringList(m['d']),
        dontDo: _stringList(m['x']),
        call: [
          for (final c in (m['c'] as List? ?? const []))
            CareContact(
              name: (c as List)[0] as String,
              relationship: c[1] as String,
              number: (c[2] as String).isEmpty ? null : c[2] as String,
            ),
        ],
        medications: m['m'] as String? ?? '',
        triggers: m['t'] as String? ?? '',
        notes: m['o'] as String? ?? '',
        version: m['v'] as int? ?? 1,
        preparedAt: DateTime.fromMillisecondsSinceEpoch(
          ((m['p'] as int?) ?? 0) * 86400000,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Bumped whenever the payload shape changes.
const String _sharePrefix = 'CC1:';

/// Eagerly typed copy of a decoded JSON list. `.cast<String>()` is lazy — a
/// non-string element would sail through the parse guards and only throw
/// later, at render time. `List<String>.from` throws here, inside the
/// try/catch that quarantines bad data.
List<String> _stringList(Object? value) =>
    value is List ? List<String>.from(value) : const [];

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
