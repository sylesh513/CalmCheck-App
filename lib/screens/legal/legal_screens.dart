/// The terms and the privacy policy, in the app, at full body size. Both are
/// linked from the paywall because the stores require it, and from Settings
/// because a person should not have to reach a paywall to read them.
library;

import 'package:flutter/material.dart';

import '../../data/legal.dart';
import '../../widgets/widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalPage(
    label: 'Terms',
    title: 'Terms of use',
    sections: LegalCopy.terms,
  );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalPage(
    label: 'Privacy policy',
    title: 'Privacy policy',
    sections: LegalCopy.privacy,
  );
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.label,
    required this.title,
    required this.sections,
  });

  final String label;
  final String title;
  final List<({String heading, String body})> sections;

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel(label),
              CcHeadline(title),
              CcCaption(LegalCopy.lastUpdated),
            ],
          ),
          for (final section in sections)
            CcStack(
              gap: CcGap.sm,
              children: [
                const CcRule(),
                FieldLabel(section.heading),
                CcBody(section.body),
              ],
            ),
        ],
      ),
    );
  }
}
