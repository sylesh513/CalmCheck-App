/// What happens when something in this app goes wrong.
///
/// There is no crash reporter. The design forbids one that could ship card
/// content, and adding a network dependency to an app whose whole promise is
/// that it has none would be worse than the crashes. So failures are kept in a
/// small ring buffer on this device, shown in About if somebody wants them, and
/// otherwise forgotten when the app closes.
///
/// The other half of this file matters more: a build error must never leave
/// somebody stranded on a red screen in the middle of a panic attack. The
/// replacement says one true thing and offers the two ways out that always
/// work.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';

@immutable
class LoggedFailure {
  const LoggedFailure(this.at, this.summary, this.library);

  final DateTime at;
  final String summary;
  final String library;

  @override
  String toString() => '${at.toIso8601String()} · $library · $summary';
}

class FailureLog {
  FailureLog._();

  static final FailureLog instance = FailureLog._();

  static const int _limit = 20;
  final Queue<LoggedFailure> _entries = Queue<LoggedFailure>();

  List<LoggedFailure> get entries => List.unmodifiable(_entries);

  void add(String summary, {String library = 'app'}) {
    _entries.addLast(LoggedFailure(DateTime.now(), summary, library));
    while (_entries.length > _limit) {
      _entries.removeFirst();
    }
  }

  void clear() => _entries.clear();
}

/// Installs the handlers and runs the app inside a guarded zone.
void runGuarded(Widget Function() app) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FailureLog.instance.add(
          details.exceptionAsString(),
          library: details.library ?? 'flutter',
        );
        // Still print in debug so a developer sees it; never sent anywhere.
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FailureLog.instance.add('$error', library: 'platform');
        if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
        return true;
      };

      ErrorWidget.builder = (details) {
        FailureLog.instance.add(
          details.exceptionAsString(),
          library: details.library ?? 'widget',
        );
        return const _RecoverySurface();
      };

      runApp(app());
    },
    (error, stack) {
      FailureLog.instance.add('$error', library: 'zone');
      if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
    },
  );
}

/// What replaces the red screen. No branding, no apology, no stack trace —
/// one sentence and the two things that always work.
class _RecoverySurface extends StatelessWidget {
  const _RecoverySurface();

  @override
  Widget build(BuildContext context) {
    // Deliberately built from raw values: whatever failed may have been the
    // theme.
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: CcColors.stockLight,
        child: Padding(
          padding: EdgeInsets.all(CcStructure.marginH),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THIS PART DIDN’T LOAD',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    letterSpacing: 1.44,
                    fontWeight: FontWeight.w600,
                    color: CcColors.inkMutedLight,
                  ),
                ),
                SizedBox(height: CcSpace.md),
                Text(
                  'Close CalmCheck and open it again. Your care cards are '
                  'saved on this device and are not affected.',
                  style: TextStyle(
                    fontFamily: 'AtkinsonHyperlegible',
                    fontSize: 17,
                    height: 1.55,
                    color: CcColors.inkLight,
                  ),
                ),
                SizedBox(height: CcSpace.md),
                Text(
                  'If you need someone right now, call your local emergency '
                  'number.',
                  style: TextStyle(
                    fontFamily: 'AtkinsonHyperlegible',
                    fontSize: 17,
                    height: 1.55,
                    color: CcColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
