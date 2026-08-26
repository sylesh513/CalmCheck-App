/// SET-01 — the settings index.
///
/// Every row carries a one-line explanation. This app explains itself: a
/// settings screen where you have to guess what a switch does is a failure of
/// nerve.
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/card_repository.dart';
import '../../services/voice.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pro = app.isPro;

    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Settings'),
              const CcSub(
                'Every switch here says what it does. Nothing leaves the phone.',
              ),
            ],
          ),
          if (app.cardStoreHealth != CardStoreHealth.ok ||
              app.lastSaveError != null)
            _StorageNotice(app: app),
          CcStack(
            gap: CcGap.lg,
            children: [
              NavRow(
                label: 'Your person',
                explanation: app.person == null
                    ? 'One person to call from inside the breathing screen, '
                          'without leaving it.'
                    : 'Called from inside the breathing screen, without '
                          'leaving it.',
                value: app.person?.shortName,
                onTap: () => Navigator.of(context).pushNamed(Routes.yourPerson),
              ),
              const CcRule(),
              ToggleRow(
                label: 'Guide voice',
                explanation:
                    'Speaks the breathing cues aloud so you can keep your eyes '
                    'closed.',
                value: app.guideVoice,
                onChanged: (v) {
                  app.guideVoice = v;
                  CcVoice.instance.enabled = v;
                },
              ),
              const CcRule(),
              ToggleRow(
                label: 'Vibration',
                explanation:
                    'A short buzz at each change of breath. Works with the '
                    'phone on silent.',
                value: app.vibration,
                onChanged: (v) => app.vibration = v,
              ),
              const CcRule(),
              // Not in the Session 6 row list, because that list was written
              // before the reminder existed as a real thing the OS schedules.
              // A setting somebody can only choose once, during onboarding,
              // is not a setting.
              ToggleRow(
                label: 'Practice reminder',
                explanation:
                    'One nudge a week to practise while you are calm. '
                    'Scheduled by your phone; nothing is sent from anywhere.',
                value: app.reminders,
                onChanged: (v) => app.setReminders(v),
              ),
              const CcRule(),
              NavRow(
                label: 'Breathing pace',
                explanation:
                    'Set your own inhale and exhale lengths for every exercise.',
                value: pro
                    ? '${app.cadence.inhale.round()}s in · '
                          '${app.cadence.exhale.round()}s out'
                    : null,
                marker: pro ? null : 'Pro',
                onTap: () => Navigator.of(context).pushNamed(
                  pro ? Routes.breathingPace : Routes.paywall,
                  arguments: pro ? null : 'breathing-pace',
                ),
              ),
              const CcRule(),
              NavRow(
                label: 'Text size',
                explanation:
                    'Make every word in the app larger, up to twice the normal '
                    'size.',
                value: '${(app.textScale * 100).round()}%',
                onTap: () => Navigator.of(context).pushNamed(Routes.display),
              ),
              const CcRule(),
              ToggleRow(
                label: 'Reduce motion',
                explanation:
                    'Replaces the moving orb with a counted cue that fades '
                    'instead of scaling.',
                value: app.reduceMotion,
                onChanged: (v) => app.reduceMotion = v,
              ),
              const CcRule(),
              NavRow(
                label: 'Helpline region',
                explanation:
                    "Which country's crisis numbers show on the Talk to "
                    'someone now screen.',
                value: app.region?.label ?? 'Not set',
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.helplineRegion),
              ),
              const CcRule(),
              NavRow(
                label: 'Privacy and data',
                explanation:
                    'What is stored, where it lives, and what happens if you '
                    'delete the app.',
                onTap: () => Navigator.of(context).pushNamed(Routes.privacy),
              ),
              const CcRule(),
              NavRow(
                label: 'Manage subscription',
                explanation: pro
                    ? 'Renews yearly through the app store. Cancel any time.'
                    : 'See what Pro includes and what it costs.',
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(pro ? Routes.manageSubscription : Routes.paywall),
              ),
              const CcRule(),
              NavRow(
                label: 'Restore purchases',
                explanation:
                    'Already paid on another device? Bring Pro back on this '
                    'one.',
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.manageSubscription),
              ),
              const CcRule(),
              NavRow(
                label: 'Sponsored access',
                explanation:
                    'A free year of Pro, paid for by other subscriptions, for '
                    "people who can't afford it.",
                onTap: () => Navigator.of(context).pushNamed(Routes.sponsored),
              ),
              const CcRule(),
              NavRow(
                label: 'Exercises',
                explanation:
                    'Every breathing and grounding exercise in the app, free '
                    'and Pro.',
                onTap: () => Navigator.of(context).pushNamed(Routes.exercises),
              ),
              const CcRule(),
              NavRow(
                label: 'Terms of use',
                explanation: 'What you agree to, and what this app is not.',
                onTap: () => Navigator.of(context).pushNamed(Routes.terms),
              ),
              const CcRule(),
              NavRow(
                label: 'Privacy policy',
                explanation:
                    'The full policy: what is stored, and what is collected.',
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.privacyPolicy),
              ),
              const CcRule(),
              NavRow(
                label: 'About CalmCheck',
                explanation:
                    'Version, the wellness disclaimer, font licences, and how '
                    'to reach us.',
                onTap: () => Navigator.of(context).pushNamed(Routes.about),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Something went wrong with somebody's own data. They are told, in words, and
/// nothing is quietly deleted behind the message.
class _StorageNotice extends StatelessWidget {
  const _StorageNotice({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    if (app.lastSaveError != null) {
      return const AlertBlock(
        label: 'Not saved',
        body:
            'The last change to a care card could not be written to this '
            'device. Check there is space free, then edit the card again. '
            'Nothing already saved has been lost.',
      );
    }
    return switch (app.cardStoreHealth) {
      CardStoreHealth.recoveredFromBackup => const AlertBlock(
        label: 'Recovered',
        body:
            'A care card file could not be read, so CalmCheck went back to '
            'the copy from before the last change. Check your cards; the very '
            'last edit may be missing.',
      ),
      CardStoreHealth.quarantined => const AlertBlock(
        label: 'Could not be read',
        body:
            'A care card file could not be read. It has been kept, '
            "untouched, in the app's own storage rather than deleted, in "
            'case it can be recovered. Cards made from now on are saved '
            'normally.',
      ),
      CardStoreHealth.ok => const SizedBox.shrink(),
    };
  }
}
