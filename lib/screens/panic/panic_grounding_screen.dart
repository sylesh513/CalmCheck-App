/// PANIC-03 — sensory grounding, one prompt at a time.
///
/// One prompt per screen. Never a list of five things at once, and the count
/// remaining is shape-based — dots, never a digit. A number is a thing to fail
/// at.
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../widgets/widgets.dart';
import 'panic_exits.dart';

const List<({String prompt, int total})> _prompts = [
  (prompt: 'Name five things you can see.', total: 5),
  (prompt: 'Name four things you can touch.', total: 4),
  (prompt: 'Name three things you can hear.', total: 3),
  (prompt: 'Name two things you can smell.', total: 2),
  (prompt: 'Name one thing you can taste.', total: 1),
];

class PanicGroundingScreen extends StatefulWidget {
  const PanicGroundingScreen({super.key});

  @override
  State<PanicGroundingScreen> createState() => _PanicGroundingScreenState();
}

class _PanicGroundingScreenState extends State<PanicGroundingScreen> {
  int _step = 0;
  bool _complete = false;

  void _advance() {
    setState(() {
      if (_step >= _prompts.length - 1) {
        _complete = true;
      } else {
        _step++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void onDone() =>
        Navigator.of(context).pushReplacementNamed(Routes.panicCheckIn);

    if (_complete) {
      return AcuteScaffold(
        onSystemBack: onDone,
        child: AcuteScreen(
          children: [
            const SizedBox.shrink(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  "You're here. You did that.",
                  textAlign: TextAlign.center,
                  style: context.ccText.displaySmall,
                ),
              ),
            ),
            PanicExits(onDone: onDone),
          ],
        ),
      );
    }

    final item = _prompts[_step];
    return AcuteScaffold(
      onSystemBack: onDone,
      child: AcuteScreen(
        children: [
          Text('Look around you.', style: context.ccText.titleLarge),
          SensePrompt(
            label: 'Grounding',
            prompt: item.prompt,
            // `remaining` used to be passed as `item.total`, which made
            // SensePrompt's fill test (`i < total - remaining`) reduce to
            // `i < 0` — so no dot ever filled and the spoken label read
            // "5 of 5 left", "4 of 4 left" with no sense of progress.
            // Progress is across the five prompts, matching ExerciseSteps.
            remaining: _prompts.length - _step,
            total: _prompts.length,
            advanceLabel: 'Next',
            onAdvance: _advance,
          ),
          PanicExits(onDone: onDone),
        ],
      ),
    );
  }
}
