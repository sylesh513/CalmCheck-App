/// Your person.
///
/// One contact, yours, separate from any care card. When it is set, the panic
/// flow gains a way to reach them; when it is not, the flow looks exactly as it
/// was designed.
///
/// The message is shown in full before it can ever be sent. Nothing about this
/// app should be able to say something on somebody's behalf that they have not
/// read first.
library;

import 'package:flutter/material.dart';

import '../../models/personal_contact.dart';
import '../../services/reach_out.dart';
import '../../services/whereabouts.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class YourPersonScreen extends StatefulWidget {
  const YourPersonScreen({super.key});

  @override
  State<YourPersonScreen> createState() => _YourPersonScreenState();
}

class _YourPersonScreenState extends State<YourPersonScreen> {
  late final AppState _app;
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _sender = TextEditingController();

  @override
  void initState() {
    super.initState();
    _app = context.appRead;
    _name.text = _app.person?.name ?? '';
    _number.text = _app.person?.number ?? '';
    _sender.text = _app.senderName ?? '';
  }

  @override
  void dispose() {
    _save();
    _name.dispose();
    _number.dispose();
    _sender.dispose();
    super.dispose();
  }

  void _save() {
    _app.setPerson(PersonalContact(name: _name.text, number: _number.text));
    _app.setSenderName(_sender.text);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final draft = PersonalContact(name: _name.text, number: _number.text);
    final ready = draft.isUsable;

    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(label: 'Done'),
              FieldLabel('Your person'),
              const CcHeadline('Someone to reach for.'),
              const CcSub(
                'One person you would want to hear from you. While the '
                'breathing is running, you can call them without leaving the '
                'screen.',
              ),
            ],
          ),

          TextFieldRow(
            label: 'Their name',
            controller: _name,
            hint: 'Dana',
            helper: 'The button reads "Call Dana", so a first name is enough.',
            onChanged: (_) {
              _save();
              setState(() {});
            },
          ),
          TextFieldRow(
            label: 'Their number',
            controller: _number,
            hint: '07700 900 118',
            keyboardType: TextInputType.phone,
            onChanged: (_) {
              _save();
              setState(() {});
            },
          ),

          const CcRule(),

          CcStack(
            gap: CcGap.md,
            children: [
              FieldLabel('If you text them'),
              const CcBody(
                'CalmCheck writes the message and opens your own messaging '
                'app with it ready. You press send. It can never send '
                'anything by itself.',
              ),
              ToggleRow(
                label: 'Include where you are',
                explanation:
                    'Adds a map link to the message. CalmCheck asks your phone '
                    'for your location only when you tap to text, and the link '
                    'goes into your message — never to us.',
                value: app.shareLocation,
                onChanged: (v) => app.shareLocation = v,
              ),
              TextFieldRow(
                label: 'Sign it as',
                controller: _sender,
                hint: 'Leave empty for "I"',
                helper:
                    'Empty reads "I\'m having a panic attack". A name reads '
                    '"Sam is having a panic attack" — useful if someone else '
                    'might be holding your phone.',
                onChanged: (_) {
                  _save();
                  setState(() {});
                },
              ),
            ],
          ),

          if (ready) _MessagePreview(app: app, contact: draft),

          const CcRule(),
          if (app.person != null)
            CcButton(
              'Remove ${app.person!.shortName}',
              variant: CcButtonVariant.quiet,
              fullWidth: true,
              onPressed: () {
                _name.clear();
                _number.clear();
                _app.setPerson(null);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

/// Exactly what will be in the message box, before anybody is in a state to
/// read carefully.
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.app, required this.contact});

  final AppState app;
  final PersonalContact contact;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final sample = reachOutMessage(
      contact: contact,
      senderName: app.senderName,
      whereabouts: app.shareLocation
          ? const Whereabouts(latitude: 51.50733, longitude: -0.12775)
          : null,
    );

    return Container(
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: CcStack(
        gap: CcGap.sm,
        children: [
          FieldLabel('What ${contact.shortName} would see'),
          CcBody(sample),
          if (app.shareLocation)
            const CcCaption(
              'The link above is an example. Yours would point at wherever you '
              'are when you tap it.',
            ),
        ],
      ),
    );
  }
}
