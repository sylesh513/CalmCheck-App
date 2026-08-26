/// Your person.
///
/// Distinct from the contacts on a care card: those belong to whoever the card
/// is about — Priya is Ravi's daughter, not yours. This is the one somebody
/// wants when *they* are the one who cannot breathe, and it is the only reason
/// the panic flow ever shows a third control.
library;

import 'package:flutter/foundation.dart';

@immutable
class PersonalContact {
  const PersonalContact({required this.name, required this.number});

  final String name;
  final String number;

  bool get isUsable => name.trim().isNotEmpty && number.trim().isNotEmpty;

  /// "Call Dana" — the first name is what a person recognises at a glance, and
  /// a long name would push the button's label onto a second line at the worst
  /// possible moment.
  String get shortName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final first = trimmed.split(RegExp(r'\s+')).first;
    return first.length <= 14 ? first : first.substring(0, 14);
  }

  Map<String, dynamic> toJson() => {'name': name, 'number': number};

  factory PersonalContact.fromJson(Map<String, dynamic> json) =>
      PersonalContact(
        name: json['name'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );
}
