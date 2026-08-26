/// The two Pro exercises that are instructions rather than a pacer, run in the
/// same register as everything else in the flow: ACUTE, one instruction on
/// screen at a time, progress shown as dots rather than as a counter.
library;

import 'package:flutter/material.dart';

import '../../data/exercises.dart';
import '../../widgets/widgets.dart';
import '../panic/panic_exits.dart';
import '../../services/keep_awake.dart';

class ExerciseStepsScreen extends StatefulWidget {
  const ExerciseStepsScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseStepsScreen> createState() => _ExerciseStepsScreenState();
}

class _ExerciseStepsScreenState extends State<ExerciseStepsScreen>
    with KeepAwake<ExerciseStepsScreen> {
  int _step = 0;
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    final steps = widget.exercise.steps;
    void leave() => Navigator.of(context).pop();

    if (_complete) {
      return AcuteScaffold(
        onSystemBack: leave,
        child: AcuteScreen(
          children: [
            const SizedBox.shrink(),
            Center(
              child: Text(
                "You're here. You did that.",
                textAlign: TextAlign.center,
                style: context.ccText.displaySmall,
              ),
            ),
            PanicExits(onDone: leave, showPerson: false),
          ],
        ),
      );
    }

    return AcuteScaffold(
      onSystemBack: leave,
      child: AcuteScreen(
        children: [
          Text(widget.exercise.name, style: context.ccText.titleLarge),
          SensePrompt(
            label: 'Step',
            prompt: steps[_step],
            remaining: steps.length - _step,
            total: steps.length,
            advanceLabel: _step == steps.length - 1 ? 'Done' : 'Next',
            onAdvance: () => setState(() {
              if (_step == steps.length - 1) {
                _complete = true;
              } else {
                _step++;
              }
            }),
          ),
          PanicExits(onDone: leave, showPerson: false),
        ],
      ),
    );
  }
}
