/// The helpline region, reached from settings. Detected from the device locale
/// on first run, changed by hand here or on CRISIS-01 itself.
library;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../crisis/crisis_screen.dart' show RegionPicker;

class HelplineRegionScreen extends StatelessWidget {
  const HelplineRegionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Helpline region'),
              const CcSub(
                "Which country's crisis numbers show on the Talk to someone "
                'now screen.',
              ),
            ],
          ),
          RegionPicker(
            selected: app.regionCode,
            onPick: (code) {
              app.setRegion(code);
              Navigator.of(context).maybePop();
            },
          ),
          const CcRule(),
          const CcCaption(
            'Nothing about this choice leaves the phone, and opening the '
            'helplines screen is never recorded.',
          ),
          if (!app.regionIsDetected)
            CcButton(
              'Follow my phone instead',
              variant: CcButtonVariant.quiet,
              fullWidth: true,
              onPressed: () {
                app.clearRegionOverride();
                Navigator.of(context).maybePop();
              },
            ),
        ],
      ),
    );
  }
}
