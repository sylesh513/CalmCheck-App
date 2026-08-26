/// PANIC-04 — a gentle off-ramp. No scoring, no logging, no history.
///
/// The "Not really" branch is the single most important escalation moment in
/// the product: it offers another exercise **and** the crisis helplines, side
/// by side, with equal weight. The helpline is never behind a second tap.
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/haptics.dart';
import '../../widgets/widgets.dart';
import 'panic_exits.dart';

enum CheckInBranch { question, steadier, notReally }

class PanicCheckInScreen extends StatefulWidget {
  const PanicCheckInScreen({super.key});

  @override
  State<PanicCheckInScreen> createState() => _PanicCheckInScreenState();
}

class _PanicCheckInScreenState extends State<PanicCheckInScreen> {
  CheckInBranch _branch = CheckInBranch.question;

  void _leave() => Navigator.of(context).pushReplacementNamed(Routes.panicRise);

  @override
  Widget build(BuildContext context) {
    final question = switch (_branch) {
      CheckInBranch.question => 'How are you doing?',
      CheckInBranch.steadier => 'Good. Take your time getting up.',
      CheckInBranch.notReally => "That's okay. Nothing is wrong with you.",
    };

    return AcuteScaffold(
      onSystemBack: _leave,
      child: AcuteScreen(
        children: [
          const SizedBox.shrink(),
          CcStack(
            gap: CcGap.xl,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(question, style: context.ccText.titleLarge),
              ),
              if (_branch == CheckInBranch.question)
                _Choices(
                  children: [
                    _Choice(
                      'A bit steadier',
                      onTap: () =>
                          setState(() => _branch = CheckInBranch.steadier),
                    ),
                    _Choice(
                      'Not really',
                      onTap: () =>
                          setState(() => _branch = CheckInBranch.notReally),
                    ),
                    _Choice(
                      'I want to keep going',
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(Routes.panicPacer),
                    ),
                  ],
                ),
              // The escalation moment: another exercise and the helplines, side
              // by side, with equal weight. The helpline is never a second tap.
              if (_branch == CheckInBranch.notReally)
                _Choices(
                  children: [
                    _Choice(
                      'Try grounding instead',
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(Routes.panicGrounding),
                    ),
                    _Choice(
                      'See crisis helplines',
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.crisis),
                    ),
                  ],
                ),
            ],
          ),
          PanicExits(onDone: _leave),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: CcSpace.lg,
    children: children,
  );
}

class _Choice extends StatelessWidget {
  const _Choice(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () {
          CcHaptics.instance.fire(CcHaptic.pressFirm);
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(CcSpace.lg),
          decoration: BoxDecoration(
            // The only line ACUTE draws: a hairline separating two choices,
            // in ink rather than in a rule token.
            border: Border(
              top: BorderSide(
                color: t.inkMuted.withValues(alpha: 0.35),
                width: CcStructure.ruleWeight,
              ),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(label, style: context.ccText.bodyLarge),
        ),
      ),
    );
  }
}
