/// CRISIS-01 — a fire exit, not a designed experience.
///
/// Different rules from every other screen: no branding flourishes, no
/// illustration, no animation, no atmosphere. Labels, rules, the largest tap
/// targets in the product, and nothing else. One tap from HOME and one tap from
/// the PANIC-04 "not really" branch, and never near anything that asks for
/// money.
///
/// The numbers come from a bundled dataset, so this screen works with no
/// signal. Emergency services are known for 237 territories; crisis lines are
/// only listed where somebody verified them against the operator, and where
/// there is none the screen says so and points at a directory that maintains
/// them properly.
library;

import 'package:flutter/material.dart';

import '../../data/helplines.dart';
import '../../services/dialer.dart';
import '../../services/haptics.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class CrisisScreen extends StatefulWidget {
  const CrisisScreen({super.key});

  @override
  State<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends State<CrisisScreen> {
  bool _pickerOpen = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final region = app.region;

    return CalmScaffold(
      child: CcScreen(
        gap: CcGap.lg,
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Crisis', tone: CcTone.alert),
                  const CcHeadline('Talk to someone now'),
                  const CcSub(
                    'These lines are free and open around the clock.',
                  ),
                ],
              ),
              const CcRule(),

              if (region == null)
                // The phone is somewhere the dataset does not cover. Say so
                // rather than showing a number for the wrong country.
                const _NoRegion()
              else ...[
                for (final line in region.crisis) _CallRow(line: line),
                if (!region.hasCrisisLine) const _NoVerifiedCrisisLine(),
                _CallRow(line: region.emergency),
              ],

              const CcRule(),
              if (_pickerOpen)
                RegionPicker(
                  selected: app.regionCode,
                  onPick: (code) {
                    app.setRegion(code);
                    setState(() => _pickerOpen = false);
                  },
                )
              else
                _RegionLine(
                  label: region?.label,
                  detected: app.regionIsDetected,
                  onChange: () => setState(() => _pickerOpen = true),
                ),
            ],
          ),
          _Footer(verifiedOn: Helplines.instance.crisisVerifiedOn),
        ],
      ),
    );
  }
}

/// The tap-to-call rows, at maximum size — larger than anywhere else in the
/// app. A number folds at its own spaces, never mid-group and never clipped.
class _CallRow extends StatelessWidget {
  const _CallRow({required this.line});

  final Helpline line;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return CcStack(
      gap: CcGap.sm,
      children: [
        Text(
          line.name.toUpperCase(),
          style: context.ccText.labelSmall!.copyWith(color: t.ink),
        ),
        for (final number in line.numbers)
          Semantics(
            button: true,
            label: isDialable(number)
                ? 'Call ${line.name} on $number'
                : 'Open ${line.name}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                CcHaptics.instance.fire(CcHaptic.emergency);
                if (isDialable(number)) {
                  dialOrExplain(context, number);
                } else if (number.contains('.')) {
                  openWebOrExplain(context, number);
                }
              },
              borderRadius: t.cardBorderRadius,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: CcStructure.targetCrisis,
                ),
                padding: const EdgeInsets.all(CcSpace.lg),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: t.alert,
                  borderRadius: t.cardBorderRadius,
                  border: Border.all(color: t.alert, width: 2),
                ),
                child: Text(
                  number,
                  style: context.ccText.titleLarge!.copyWith(
                    color: t.alertInk,
                    fontSize: context.ccText.titleLarge!.fontSize! * 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        CcBody(line.sub, muted: true),
      ],
    );
  }
}

/// No verified crisis line for this country. The emergency number below is
/// still right, and the directory is the honest route to the rest.
class _NoVerifiedCrisisLine extends StatelessWidget {
  const _NoVerifiedCrisisLine();

  @override
  Widget build(BuildContext context) {
    return CcStack(
      gap: CcGap.sm,
      children: [
        const CcBody(
          'CalmCheck does not have a checked crisis line for this country yet. '
          'This directory keeps them for over 130 countries.',
        ),
        _DirectoryButton(),
      ],
    );
  }
}

/// The phone's country is not in the dataset at all.
class _NoRegion extends StatelessWidget {
  const _NoRegion();

  @override
  Widget build(BuildContext context) {
    return CcStack(
      gap: CcGap.sm,
      children: [
        const CcBody(
          'CalmCheck could not tell which country this phone is in, so it is '
          'not showing you numbers that might be for the wrong one. Choose '
          'your country below, or use this directory.',
        ),
        _DirectoryButton(),
      ],
    );
  }
}

class _DirectoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CcButton(
      'Open findahelpline.com',
      variant: CcButtonVariant.secondary,
      size: CcButtonSize.lg,
      fullWidth: true,
      haptic: CcHaptic.emergency,
      onPressed: () => openWebOrExplain(context, 'findahelpline.com'),
    );
  }
}

class _RegionLine extends StatelessWidget {
  const _RegionLine({
    required this.label,
    required this.detected,
    required this.onChange,
  });

  final String? label;
  final bool detected;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CcSpace.sm,
      children: [
        CcBody(
          label == null
              ? 'No country set.'
              : detected
              ? 'Showing helplines for $label, from your phone.'
              : 'Showing helplines for $label.',
          muted: true,
        ),
        CcButton(
          'Change country',
          variant: CcButtonVariant.quiet,
          haptic: null,
          onPressed: onChange,
        ),
      ],
    );
  }
}

/// Shared by CRISIS-01 and the settings row, so there is one list of countries
/// and one way to change it. 237 of them, so it can be searched.
class RegionPicker extends StatefulWidget {
  const RegionPicker({super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  State<RegionPicker> createState() => _RegionPickerState();
}

class _RegionPickerState extends State<RegionPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final needle = _query.text.trim().toLowerCase();
    final all = Helplines.instance.all;
    final matches = needle.isEmpty
        ? all
        : all.where((r) => r.label.toLowerCase().contains(needle)).toList();

    return CcStack(
      gap: CcGap.sm,
      children: [
        FieldLabel('Country'),
        TextFieldRow(
          label: 'Search',
          controller: _query,
          hint: 'Start typing a country',
          onChanged: (_) => setState(() {}),
        ),
        if (matches.isEmpty)
          const CcBody('No country by that name.', muted: true)
        else
          for (final region in matches.take(40))
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: region.code == widget.selected,
              button: true,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => widget.onPick(region.code),
                borderRadius: t.cardBorderRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CcSpace.lg,
                    vertical: CcSpace.md,
                  ),
                  decoration: BoxDecoration(
                    color: t.stockRaised,
                    borderRadius: t.cardBorderRadius,
                    border: Border.all(
                      color: region.code == widget.selected ? t.ink : t.rule,
                      width: region.code == widget.selected
                          ? 2
                          : CcStructure.cardEdge,
                    ),
                  ),
                  child: Row(
                    spacing: CcSpace.md,
                    children: [
                      Expanded(
                        child: Text(
                          region.label,
                          style: context.ccText.bodyLarge,
                        ),
                      ),
                      if (region.hasCrisisLine)
                        FieldLabel('Crisis line', tone: CcTone.signal),
                      if (region.code == widget.selected) FieldLabel('Showing'),
                    ],
                  ),
                ),
              ),
            ),
        if (needle.isEmpty && all.length > 40)
          CcCaption('${all.length - 40} more — search to narrow the list.'),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.verifiedOn});

  final String verifiedOn;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.only(top: CcSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.rule, width: CcStructure.ruleWeight),
        ),
      ),
      child: CcStack(
        gap: CcGap.xs,
        children: [
          const CcCaption(
            "CalmCheck doesn't monitor your use of this screen. Nothing here "
            'is recorded.',
          ),
          if (verifiedOn.isNotEmpty)
            CcCaption('Crisis numbers checked $verifiedOn.'),
        ],
      ),
    );
  }
}
