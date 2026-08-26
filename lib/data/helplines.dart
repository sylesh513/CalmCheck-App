/// CRISIS-01 content, loaded from a bundled dataset.
///
/// The dataset is a file, not code: `assets/helplines/helplines.json`, built by
/// `tool/build_helplines.py`. Refreshing the numbers is a data change and a
/// release, never a network call — the crisis screen is exactly where somebody
/// may have no signal, and the app has no internet permission to spend on it.
///
/// Two different kinds of number live in it. Emergency services numbers come
/// from Google's libphonenumber short-number metadata, which is ITU-derived and
/// covers 237 territories. Crisis helplines are hand-verified against the
/// operator's own publication, so they cover far fewer — and where a country
/// has none the app says so and routes to findahelpline.com, rather than
/// showing a number nobody checked.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

@immutable
class Helpline {
  const Helpline({
    required this.name,
    required this.numbers,
    required this.sub,
    this.verified,
  });

  final String name;

  /// Dialled exactly as printed. A number may fold at its own spaces, never
  /// mid-group and never clipped.
  final List<String> numbers;
  final String sub;

  /// The date this entry was last checked against its operator.
  final String? verified;
}

@immutable
class HelplineRegion {
  const HelplineRegion({
    required this.code,
    required this.label,
    required this.crisis,
    required this.emergency,
  });

  final String code;
  final String label;

  /// Verified crisis lines. Empty for most countries.
  final List<Helpline> crisis;

  /// Always present.
  final Helpline emergency;

  bool get hasCrisisLine => crisis.isNotEmpty;

  List<Helpline> get lines => [...crisis, emergency];
}

/// The one entry the app can always fall back to: a maintained directory of
/// 170+ countries, reached through the browser rather than bundled.
const Helpline findAHelpline = Helpline(
  name: 'Find a helpline',
  numbers: ['findahelpline.com'],
  sub:
      'Free, confidential lines in over 130 countries, kept up to date by the '
      'people who run them.',
);

class Helplines {
  Helplines._();

  static final Helplines instance = Helplines._();

  static const String _asset = 'assets/helplines/helplines.json';

  final Map<String, HelplineRegion> _regions = {};
  List<HelplineRegion> _sorted = const [];
  String _crisisVerifiedOn = '';
  bool _loaded = false;

  bool get isLoaded => _loaded;
  String get crisisVerifiedOn => _crisisVerifiedOn;

  /// Every territory, by name. Used by the region picker.
  List<HelplineRegion> get all => _sorted;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_asset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _crisisVerifiedOn = data['crisisVerifiedOn'] as String? ?? '';

      final countries = data['countries'] as Map<String, dynamic>;
      countries.forEach((code, value) {
        final entry = value as Map<String, dynamic>;
        final emergency = (entry['emergency'] as List).cast<String>();
        if (emergency.isEmpty) return;

        _regions[code] = HelplineRegion(
          code: code,
          label: entry['name'] as String,
          emergency: Helpline(
            name: 'Emergency services',
            numbers: emergency,
            sub: 'If there is immediate danger to life.',
          ),
          crisis: [
            for (final line in (entry['crisis'] as List? ?? const []))
              Helpline(
                name: (line as Map)['name'] as String,
                numbers: (line['numbers'] as List).cast<String>(),
                sub: line['sub'] as String,
                verified: line['verified'] as String?,
              ),
          ],
        );
      });

      _sorted = _regions.values.toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _loaded = true;
    } catch (_) {
      // A missing or unreadable asset must not take the crisis screen with it.
      _loaded = false;
    }
  }

  /// Null when the territory is not in the dataset.
  HelplineRegion? forCode(String? code) => code == null ? null : _regions[code];
}

/// True when the entry is a dialable number rather than a web address or a
/// plain instruction.
bool isDialable(String value) => RegExp(r'^[0-9+][0-9 \-()]*$').hasMatch(value);
