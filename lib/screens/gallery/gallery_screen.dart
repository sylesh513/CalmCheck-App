/// The design reference: every screen and every state in this build, grouped
/// by the sessions that specified them.
///
/// This is a reading surface, not a debug menu — nothing here changes what the
/// app does, and nothing here is a shortcut past a paywall.
library;

import 'package:flutter/material.dart';

import '../../data/sample_cards.dart';
import '../../models/care_card.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../cards/card_edit_screen.dart';
import '../cards/card_empty_screen.dart';
import '../cards/card_scan_screen.dart';
import '../cards/card_share_screen.dart';
import '../cards/card_view_screen.dart';
import '../crisis/crisis_screen.dart';
import '../exercises/exercise_detail_screen.dart';
import '../exercises/exercise_library_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screens.dart';
import '../panic/panic_check_in_screen.dart';
import '../panic/panic_grounding_screen.dart';
import '../panic/panic_pacer_screen.dart';
import '../panic/panic_rise_screen.dart';
import '../paywall/lifecycle_screen.dart';
import '../paywall/manage_subscription_screen.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/sponsored_screen.dart';
import '../settings/about_screen.dart';
import '../settings/breathing_pace_screen.dart';
import '../settings/display_screen.dart';
import '../settings/helpline_region_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/settings_screen.dart';
import '../states/system_state_screens.dart';
import 'specimen_screen.dart';

class _Entry {
  const _Entry(this.label, this.note, this.build);

  final String label;
  final String note;
  final WidgetBuilder build;
}

class _Group {
  const _Group(this.title, this.entries);

  final String title;
  final List<_Entry> entries;
}

/// A minimal card: only the fields someone filled in on the first pass. It
/// must not look broken.
CareCardData get _aanyaMinimal {
  final full = aanya;
  return full.copyWith(
    doThis: full.doThis.take(2).toList(),
    dontDo: full.dontDo.take(1).toList(),
    call: full.call.take(1).toList(),
    version: 1,
  );
}

List<_Group> _groups() => [
  _Group('Design system', [
    _Entry(
      'Specimen',
      'Three modes, palette, type, spacing, contrast',
      (_) => const SpecimenScreen(),
    ),
  ]),
  _Group('Session 3 · Onboarding', [
    _Entry(
      'ONB-01 · The promise',
      'Orb-forward',
      (_) => const OnboardingPromiseScreen(),
    ),
    _Entry(
      'ONB-01 · The promise',
      'Type-forward',
      (_) => const OnboardingPromiseTypeScreen(),
    ),
    _Entry(
      'ONB-02 · Two paths',
      'Two doors into one room',
      (_) => const OnboardingPathsScreen(),
    ),
    _Entry(
      'ONB-03 · Permissions',
      'Reminders off by default',
      (_) => const OnboardingPermissionsScreen(),
    ),
    _Entry(
      'ONB-04 · What this is',
      'The scope, printed properly',
      (_) => const OnboardingScopeScreen(),
    ),
  ]),
  _Group('Session 3 · Home', [
    _Entry('HOME', 'Ground layout, saved cards', (_) => const HomeScreen()),
    _Entry(
      'HOME · no cards yet',
      'The first-run shelf',
      (_) => const HomeScreen(forceEmpty: true),
    ),
  ]),
  _Group('Session 4 · Panic flow', [
    _Entry(
      'PANIC-02 · Breathing pacer',
      'Live orb, haptics, voice',
      (_) => const PanicPacerScreen(),
    ),
    _Entry(
      'PANIC-02 · Reduced motion',
      'Static ring, pacing kept',
      (_) => const PanicPacerScreen(args: PacerArgs(forceReducedMotion: true)),
    ),
    _Entry(
      'PANIC-03 · Grounding',
      'One prompt per screen, dots',
      (_) => const PanicGroundingScreen(),
    ),
    _Entry(
      'PANIC-04 · Check-in',
      'All four branches',
      (_) => const PanicCheckInScreen(),
    ),
    _Entry(
      'PANIC-05 · The rise',
      'ACUTE back up to CALM',
      (_) => const PanicRiseScreen(),
    ),
  ]),
  _Group('Session 5 · Care cards', [
    _Entry(
      'CARD-VIEW · Ravi',
      'Full card, owner view',
      (_) => CardViewScreen(previewCard: ravi),
    ),
    _Entry(
      'CARD-VIEW · Aanya',
      'Minimal card',
      (_) => CardViewScreen(previewCard: _aanyaMinimal),
    ),
    _Entry(
      'CARD-VIEW · Received',
      'Read-only, no edit affordance',
      (_) => CardViewScreen(
        previewCard: aanya.copyWith(readOnly: true, sharedBy: 'Sonia'),
      ),
    ),
    _Entry(
      'CARD-EDIT',
      'Autosave, suggestions, disclosure',
      (_) => const CardEditScreen(),
    ),
    _Entry(
      'CARD-EMPTY',
      'The ghosted example card',
      (_) => const CardEmptyScreen(),
    ),
    _Entry(
      'CARD-SCAN',
      'Scanning, found, denied, invalid',
      (_) => const CardScanScreen(),
    ),
  ]),
  _Group('Session 6 · Exercises', [
    _Entry(
      'EX-01 · Library',
      'Free and Pro',
      (_) => const ExerciseLibraryScreen(),
    ),
    _Entry(
      'EX-02 · Paced breathing',
      'Free, unlocked',
      (_) => const ExerciseDetailScreen(exerciseId: 'paced'),
    ),
    _Entry(
      'EX-02 · Box breathing',
      'Locked, or the cadence control',
      (_) => const ExerciseDetailScreen(exerciseId: 'box'),
    ),
  ]),
  _Group('Session 6 · Crisis', [
    _Entry(
      'CRISIS-01',
      'A fire exit, not an experience',
      (_) => const CrisisScreen(),
    ),
  ]),
  _Group('Session 7 · Pro', [
    _Entry(
      'PAY-01 · Annual-default',
      'The conventional shape',
      (_) => const PaywallScreen(
        variant: PaywallVariant.annual,
        forcedState: PayState.free,
      ),
    ),
    _Entry(
      'PAY-01 · Lifetime-anchor',
      'Lifetime first as the anchor',
      (_) => const PaywallScreen(
        variant: PaywallVariant.lifetime,
        forcedState: PayState.free,
      ),
    ),
    _Entry(
      'PAY-01 · Give-back-forward',
      'The mission leads',
      (_) => const PaywallScreen(
        variant: PaywallVariant.giveback,
        forcedState: PayState.free,
      ),
    ),
    _Entry(
      'PAY-01 · Trial active',
      'Days left, price named',
      (_) => const PaywallScreen(forcedState: PayState.trial),
    ),
    _Entry(
      'PAY-01 · Subscribed',
      'Nothing to buy here',
      (_) => const PaywallScreen(forcedState: PayState.subscribed),
    ),
    _Entry(
      'PAY-01 · Purchase error',
      'Nothing has been charged',
      (_) => const PaywallScreen(forcedState: PayState.error),
    ),
    _Entry(
      'PAY-01 · Restoring',
      'The button says what it is doing',
      (_) => const PaywallScreen(forcedState: PayState.restoring),
    ),
    _Entry(
      'PAY-02 · Pool open',
      'A specific number',
      (_) => const SponsoredScreen(forcedState: SponsoredState.open),
    ),
    _Entry(
      'PAY-02 · Pool empty',
      'Designed honestly',
      (_) => const SponsoredScreen(forcedState: SponsoredState.empty),
    ),
    _Entry(
      'PAY-02 · Submitted',
      'Nothing stored in the app',
      (_) => const SponsoredScreen(forcedState: SponsoredState.submitted),
    ),
    _Entry(
      'PAY-02 · Granted',
      "Someone else's subscription paid for this",
      (_) => const SponsoredScreen(forcedState: SponsoredState.granted),
    ),
    _Entry(
      'PAY-03 · Manage · free',
      'Restore only',
      (_) => const ManageSubscriptionScreen(forcedStatus: ProStatus.free),
    ),
    _Entry(
      'PAY-03 · Manage · trial',
      'Days remaining',
      (_) => const ManageSubscriptionScreen(forcedStatus: ProStatus.trial),
    ),
    _Entry(
      'PAY-03 · Manage · subscribed',
      'Renews yearly',
      (_) => const ManageSubscriptionScreen(forcedStatus: ProStatus.subscribed),
    ),
    _Entry(
      'PAY-03 · Manage · expired',
      'Cards still readable',
      (_) => const ManageSubscriptionScreen(forcedStatus: ProStatus.expired),
    ),
    _Entry(
      'PAY-04 · Trial started',
      'Seven days of everything',
      (_) => const LifecycleScreen(moment: LifecycleMoment.started),
    ),
    _Entry(
      'PAY-04 · Trial ending',
      'In-app, not a notification',
      (_) => const LifecycleScreen(moment: LifecycleMoment.ending),
    ),
    _Entry(
      'PAY-04 · Pro ended',
      'What stays, what pauses',
      (_) => const LifecycleScreen(moment: LifecycleMoment.expired),
    ),
  ]),
  _Group('Session 6 · Settings', [
    _Entry(
      'SET-01 · Index',
      'Every row explains itself',
      (_) => const SettingsScreen(),
    ),
    _Entry(
      'SET-02 · Privacy and data',
      'The back of the card',
      (_) => const PrivacyScreen(),
    ),
    _Entry(
      'SET-03 · About',
      'Disclaimer and font licences',
      (_) => const AboutScreen(),
    ),
    _Entry(
      'SET-04 · Text size and motion',
      'Live preview',
      (_) => const DisplayScreen(),
    ),
    _Entry(
      'Breathing pace',
      'The Pro cadence control',
      (_) => const BreathingPaceScreen(),
    ),
    _Entry(
      'Helpline region',
      'Locale-detected, hand-changed',
      (_) => const HelplineRegionScreen(),
    ),
  ]),
  _Group('Session 8 · System states', [
    _Entry(
      'Permission · camera',
      'Never a dead end',
      (_) => const PermissionCameraScreen(),
    ),
    _Entry(
      'Permission · notifications',
      'Carry on without them',
      (_) => const PermissionNotificationsScreen(),
    ),
    _Entry(
      'Purchase failed',
      'Nothing has been charged',
      (_) => const PurchaseFailedScreen(),
    ),
    _Entry(
      'Empty · care cards',
      'A ghosted tile',
      (_) => const EmptyCardsStateScreen(),
    ),
    _Entry(
      'Empty · exercises',
      'The two free ones stay unlocked',
      (_) => const EmptyExercisesStateScreen(),
    ),
    _Entry(
      'Empty · scan',
      "That code isn't a CalmCheck card",
      (_) => const EmptyScanStateScreen(),
    ),
    _Entry(
      'Destructive confirmation',
      'One wording, everywhere',
      (_) => const DeleteCardConfirmScreen(),
    ),
  ]),
];

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final firstCard = app.cards.isEmpty ? null : app.cards.first;

    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Design reference'),
              const CcHeadline('Every screen in this build.'),
              const CcSub(
                'Grouped by the session that specified it. Opening one here '
                'changes nothing that is saved.',
              ),
            ],
          ),
          for (final group in _groups())
            CcStack(
              gap: CcGap.sm,
              children: [
                const CcRule(),
                FieldLabel(group.title),
                for (final entry in group.entries)
                  NavRow(
                    label: entry.label,
                    explanation: entry.note,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: entry.build)),
                  ),
              ],
            ),
          // CARD-SHARE needs a real saved card to point its QR at.
          if (firstCard != null)
            CcStack(
              gap: CcGap.sm,
              children: [
                const CcRule(),
                FieldLabel('Session 5 · Sharing'),
                NavRow(
                  label: 'CARD-SHARE',
                  explanation:
                      'QR, PDF at A4 and Letter — uses ${firstCard.name}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CardShareScreen(cardId: firstCard.id),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
