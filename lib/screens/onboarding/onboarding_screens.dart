/// ONB-01 .. ONB-04.
///
/// The only screen in the app allowed a moment of atmosphere is the first one,
/// and even there the atmosphere is the product demonstrating itself rather
/// than describing itself.
library;

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../routes.dart';
import '../../services/voice.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../../services/haptics.dart';

/// ONB-01, orb-forward. The promise, with the orb alive and slow behind it.
class OnboardingPromiseScreen extends StatelessWidget {
  const OnboardingPromiseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          FieldLabel('CalmCheck'),
          SizedBox(
            height: 260,
            child: BreathOrb(
              showCue: false,
              glow: 0.85,
              reducedMotion: reduced,
              verticalCentre: 0.5,
            ),
          ),
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcHeadline('Know what to do in the next 60 seconds.'),
              const CcSub(
                'Guided calm for hard moments, and care cards for the people '
                'you look after. Works with no signal.',
              ),
              CcButton(
                'Get started',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.onboardingPaths),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ONB-01, type-forward. The same promise set as printed matter — the
/// alternative treatment, kept for comparison.
class OnboardingPromiseTypeScreen extends StatelessWidget {
  const OnboardingPromiseTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('CalmCheck'),
              const CcRule(),
              const CcHeadline(
                'Know what to do in the next 60 seconds.',
                scale: 1.2,
              ),
            ],
          ),
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcRule(),
              const CcSub(
                'Guided calm for hard moments, and care cards for the people '
                'you look after. Works with no signal.',
              ),
              CcButton(
                'Get started',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.onboardingPaths),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ONB-02 — two doors into one room, not two apps. Both land on the same HOME;
/// the choice only sets which half is emphasised on first run.
class OnboardingPathsScreen extends StatefulWidget {
  const OnboardingPathsScreen({super.key});

  @override
  State<OnboardingPathsScreen> createState() => _OnboardingPathsScreenState();
}

class _OnboardingPathsScreenState extends State<OnboardingPathsScreen> {
  OnboardingPath? _selected;
  bool _navigating = false;

  void _choose(OnboardingPath path) {
    setState(() => _selected = path);
    context.appRead.setPath(path);
    // One push per screen, no matter how fast the taps: a second choice
    // within the beat updates the selection but must not stack ONB-03 twice.
    if (_navigating) return;
    _navigating = true;
    // A short beat so the selection is visible before the screen changes.
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      Navigator.of(context).pushNamed(Routes.onboardingPermissions).then((_) {
        _navigating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('Setup · 1 of 3'),
              const CcHeadline('Who are you setting this up for?'),
            ],
          ),
          CcStack(
            gap: CcGap.md,
            children: [
              PathOption(
                title: 'Myself',
                sub: 'Breathing and grounding, one tap away.',
                selected: _selected == OnboardingPath.myself,
                onTap: () => _choose(OnboardingPath.myself),
              ),
              PathOption(
                title: 'Someone I look after',
                sub: "A card anyone can follow if you're not there.",
                selected: _selected == OnboardingPath.someoneElse,
                onTap: () => _choose(OnboardingPath.someoneElse),
              ),
              CcButton(
                'Both — show me everything',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: () => _choose(OnboardingPath.both),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ONB-03 — permissions. Reminders are asked for on arrival and left on if
/// granted: a nudge to practise while you're calm is the whole mechanism by
/// which the app is any use before a bad moment, and almost nobody goes
/// looking for a switch to enable it. The toggle stays, immediately above the
/// button, so turning it back off is one tap and needs no menu.
class OnboardingPermissionsScreen extends StatefulWidget {
  const OnboardingPermissionsScreen({super.key});

  @override
  State<OnboardingPermissionsScreen> createState() =>
      _OnboardingPermissionsScreenState();
}

class _OnboardingPermissionsScreenState
    extends State<OnboardingPermissionsScreen> {
  /// The notification prompt is fired once, on arrival, rather than waiting
  /// for someone to find the toggle. `setReminders` is what owns the OS
  /// dialog: it only records `true` if permission actually came back granted,
  /// so a denial — or a second visit after a denial, where iOS never asks
  /// again — leaves the toggle honestly off rather than showing a promise the
  /// phone will not keep.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.appRead;
      if (!app.reminders) app.setReminders(true);
    });
  }

  /// The Vibration switch is the one setting nobody can evaluate by reading
  /// about it, so turning it on plays the pacing haptic once.
  void _setVibration(bool on) {
    final app = context.appRead;
    app.vibration = on;
    if (on) CcHaptics.instance.fire(CcHaptic.breathRise);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('Setup · 2 of 3'),
              const CcHeadline('Two quick settings.'),
            ],
          ),
          CcStack(
            gap: CcGap.md,
            children: [
              ToggleRow(
                label: 'Vibration',
                explanation:
                    'The app paces your breathing through your hand, so you '
                    "don't have to watch the screen.",
                value: app.vibration,
                onChanged: _setVibration,
              ),
              const CcRule(),
              ToggleRow(
                label: 'Reminders',
                explanation:
                    "An occasional nudge to practise while you're calm. On, "
                    'because it is easy to forget — turn it off here or in '
                    'Settings.',
                value: app.reminders,
                onChanged: (v) => app.setReminders(v),
              ),
            ],
          ),
          CcButton(
            'Continue',
            size: CcButtonSize.lg,
            fullWidth: true,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.onboardingScope),
          ),
        ],
      ),
    );
  }
}

/// ONB-04 — the scope of the app, delivered as respect rather than legal cover.
/// Set at full body size: this is the fine print printed properly.
class OnboardingScopeScreen extends StatelessWidget {
  const OnboardingScopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('Setup · 3 of 3'),
              const CcHeadline("What this app is, and what it isn't."),
              const CcRule(),
              const CcBody(StateCopy.disclaimerBody),
              const CcBody(StateCopy.disclaimerDanger),
            ],
          ),
          CcStack(
            gap: CcGap.md,
            children: [
              CcButton(
                'See crisis helplines',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pushNamed(Routes.crisis),
              ),
              CcButton(
                'I understand',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () {
                  final app = context.appRead;
                  app.completeOnboarding();
                  CcVoice.instance.enabled = app.guideVoice;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.onboardingFirstCard,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ONB-05 — the first care card. Asked for once, at the only moment the whole
/// point of the second half of the app is on screen. Never forced: somebody who
/// came here for the breathing is allowed to leave with just the breathing.
class OnboardingFirstCardScreen extends StatefulWidget {
  const OnboardingFirstCardScreen({super.key});

  @override
  State<OnboardingFirstCardScreen> createState() =>
      _OnboardingFirstCardScreenState();
}

class _OnboardingFirstCardScreenState extends State<OnboardingFirstCardScreen> {
  void _toHome() => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(Routes.home, (route) => false);

  /// Push the editor and wait for it to come back before deciding anything.
  ///
  /// The count is deliberately compared here and not in `build`. The editor
  /// autosaves while someone is still typing, which notifies AppState, which
  /// rebuilds this screen underneath it — and a "did a card appear?" check in
  /// `build` fired on the first keystroke of the name and threw the editor
  /// away mid-sentence. Nothing about this screen may depend on card state
  /// while the editor is on top of it.
  Future<void> _create() async {
    final app = context.appRead;
    final before = app.cards.length;

    // The same rule HOME uses, so onboarding is not a way around the paywall.
    final route = app.canCreateCard
        ? Routes.cardEdit
        : Routes.paywall;
    await Navigator.of(
      context,
    ).pushNamed(route, arguments: route == Routes.paywall ? 'second-card' : null);

    // They came back having actually made one. Say nothing more about it and
    // get out of the way; otherwise leave them on this screen to choose again.
    if (!mounted) return;
    if (context.appRead.cards.length > before) _toHome();
  }

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('One last thing'),
              const CcHeadline('Make a card for someone you look after.'),
              const CcBody(
                'A care card is what somebody else follows when you are not '
                'there — what helps, what to avoid, who to ring. It takes about '
                'two minutes, and it never leaves this phone.',
              ),
              const CcBody(
                'You can do it now or later. The library starts empty — the '
                'only cards in it are the ones you make.',
              ),
            ],
          ),
          CcStack(
            gap: CcGap.md,
            children: [
              CcButton(
                'Create a care card',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: _create,
              ),
              CcButton(
                "I'll do this later",
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: _toHome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
