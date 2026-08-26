/// The system state patterns, designed once and applied everywhere.
///
/// Each one is a ghosted form of the missing thing, one line of direction, and
/// one action. Never an apology, never a shrug, never "Oops". There is
/// deliberately no offline state anywhere in this app: offline is its normal
/// operating condition, not a failure to report.
library;

import 'package:flutter/material.dart';

import '../../services/device_settings.dart';

import '../../data/copy.dart';
import '../../data/exercises.dart';
import '../../routes.dart';
import '../../widgets/widgets.dart';

/// Camera permission denied — the QR scanner's blocked state.
class PermissionCameraScreen extends StatelessWidget {
  const PermissionCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              const CcHeadline('Scan a care card'),
              SystemState(
                label: StateCopy.cameraLabel,
                headline: StateCopy.cameraHeadline,
                direction: StateCopy.cameraDirection,
                ghost: const _GhostViewfinder(),
                action: CcButton(
                  StateCopy.cameraPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: openAppSettings,
                ),
                alternative: CcButton(
                  StateCopy.cameraSecondary,
                  variant: CcButtonVariant.quiet,
                  fullWidth: true,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.cardScan),
                ),
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Notification permission denied — reached from the reminder toggle.
class PermissionNotificationsScreen extends StatelessWidget {
  const PermissionNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              const CcHeadline('Practice reminder'),
              SystemState(
                label: StateCopy.notificationsLabel,
                headline: StateCopy.notificationsHeadline,
                direction: StateCopy.notificationsDirection,
                action: CcButton(
                  StateCopy.notificationsPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: openNotificationSettings,
                ),
                alternative: CcButton(
                  StateCopy.notificationsSecondary,
                  variant: CcButtonVariant.quiet,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Purchase failure — states the fact, names the charge, offers two ways on.
class PurchaseFailedScreen extends StatelessWidget {
  const PurchaseFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              const CcHeadline('CalmCheck Pro'),
              SystemState(
                label: StateCopy.purchaseLabel,
                headline: StateCopy.purchaseHeadline,
                direction: StateCopy.purchaseDirection,
                action: CcButton(
                  StateCopy.purchasePrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(Routes.paywall),
                ),
                alternative: CcButton(
                  StateCopy.purchaseSecondary,
                  variant: CcButtonVariant.quiet,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(Routes.manageSubscription),
                ),
              ),
            ],
          ),
          const CcBody(
            'Breathing, grounding, your first care card and the helplines are '
            'free forever.',
          ),
        ],
      ),
    );
  }
}

/// Empty 1 — no care cards.
class EmptyCardsStateScreen extends StatelessWidget {
  const EmptyCardsStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              SystemState(
                label: StateCopy.emptyCardsLabel,
                headline: StateCopy.emptyCardsHeadline,
                direction: StateCopy.emptyCardsDirection,
                ghost: const CareTile(
                  name: 'Mum',
                  signal: 'Lives alone · Ealing',
                  addNew: true,
                  ghost: true,
                ),
                action: CcButton(
                  StateCopy.emptyCardsPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.cardEdit),
                ),
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Empty 2 — nothing unlocked. Breathing and grounding are never locked.
class EmptyExercisesStateScreen extends StatelessWidget {
  const EmptyExercisesStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              SystemState(
                label: StateCopy.emptyExercisesLabel,
                headline: StateCopy.emptyExercisesHeadline,
                direction: StateCopy.emptyExercisesDirection,
                ghost: const ExerciseCardTile(
                  name: 'Physiological sigh',
                  duration: '1 min',
                  purpose: 'Two inhales, one long exhale.',
                  state: ExerciseCardState.locked,
                  ghost: true,
                ),
                action: CcButton(
                  StateCopy.emptyExercisesPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.paywall),
                ),
              ),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Free, always'),
                  for (final ex in exercises.where((e) => e.isFree))
                    ExerciseCardTile(
                      name: ex.name,
                      duration: ex.duration,
                      purpose: ex.purpose,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(Routes.exerciseDetail, arguments: ex.id),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Empty 3 — the scan found something that isn't a card.
class EmptyScanStateScreen extends StatelessWidget {
  const EmptyScanStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              const CcHeadline('Scan a care card'),
              SystemState(
                label: StateCopy.emptyScanLabel,
                headline: StateCopy.emptyScanHeadline,
                direction: StateCopy.emptyScanDirection,
                ghost: const _GhostViewfinder(),
                action: CcButton(
                  StateCopy.emptyScanPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(Routes.cardScan),
                ),
                alternative: CcButton(
                  'Open a card file instead',
                  variant: CcButtonVariant.quiet,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(Routes.cardScan),
                ),
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Destructive confirmation — one wording, used everywhere a card is deleted.
class DeleteCardConfirmScreen extends StatelessWidget {
  const DeleteCardConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.center,
        children: [
          DestructiveConfirm(
            title: StateCopy.deleteCardTitle,
            consequence: StateCopy.deleteCardBody,
            confirmLabel: StateCopy.deleteCardConfirm,
            cancelLabel: StateCopy.deleteCardCancel,
            onConfirm: () => Navigator.of(context).maybePop(),
            onCancel: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _GhostViewfinder extends StatelessWidget {
  const _GhostViewfinder();

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return AspectRatio(
      aspectRatio: 1.6,
      child: DottedFrame(
        color: t.rule,
        radius: t.radiusCard,
        child: const SizedBox(),
      ),
    );
  }
}
