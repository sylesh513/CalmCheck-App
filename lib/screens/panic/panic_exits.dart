/// The controls the panic flow is allowed to show.
///
/// The design holds this screen to two interactive elements, and for a long
/// time that was exactly right: an alternative route out of breathing, and a
/// way to stop. Reaching a person is the one thing worth a third, and it is
/// only ever drawn when somebody has actually named their person — so an app
/// nobody has set up still looks exactly as designed.
///
/// Exit stays available and stays quiet. The one loud control is the one that
/// gets you a human.
library;

import 'package:flutter/material.dart';

import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../models/personal_contact.dart';
import '../../services/haptics.dart';
import '../../services/reach_out.dart';
import '../../services/whereabouts.dart';
import '../../state/app_state.dart';
import '../../services/dialer.dart';
import '../../models/care_card.dart';

class PanicExits extends StatelessWidget {
  const PanicExits({
    super.key,
    this.alternative,
    this.onAlternative,
    required this.onDone,
    this.doneLabel = "I'm done",
    this.showPerson = true,
    this.showCareFallback = false,
  });

  final String? alternative;
  final VoidCallback? onAlternative;
  final VoidCallback onDone;
  final String doneLabel;

  /// Off for surfaces where reaching a person is not the point.
  final bool showPerson;

  /// Offer a care-card contact when no personal contact has been named. Opt-in,
  /// and currently only the pacer: the check-in and escalation surfaces balance
  /// grounding against the helplines deliberately, and a third loud button
  /// there would upset that.
  final bool showCareFallback;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final person = showPerson ? context.app.person : null;
    // Nobody has named a personal contact, but their care cards carry numbers.
    // Offering one of those beats offering nothing at all.
    final fallback = (showCareFallback && showPerson && person == null)
        ? context.app.firstCareContact
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CcSpace.sm,
      children: [
        if (person == null && fallback != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CcSpace.sm),
            child: CallCareContact(
              contact: fallback.contact,
              cardName: fallback.cardName,
            ),
          ),
        if (person != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CcSpace.sm),
            child: ReachPerson(person: person),
          ),
        if (alternative != null && onAlternative != null)
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: _QuietExit(
              label: alternative!,
              onTap: onAlternative!,
              style: context.ccText.bodyMedium!.copyWith(color: t.inkMuted),
            ),
          ),
        FocusTraversalOrder(
          order: const NumericFocusOrder(4),
          child: _QuietExit(
            label: doneLabel.toUpperCase(),
            onTap: onDone,
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: 18,
              letterSpacing: 1.44,
              fontWeight: FontWeight.w600,
              color: t.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Call, or text. Both hand off to the phone's own apps; nothing is sent by
/// this app on anybody's behalf.
class ReachPerson extends StatefulWidget {
  const ReachPerson({super.key, required this.person});

  final PersonalContact person;

  @override
  State<ReachPerson> createState() => _ReachPersonState();
}

class _ReachPersonState extends State<ReachPerson> {
  bool _preparing = false;
  String? _note;

  Future<void> _call() async {
    CcHaptics.instance.fire(CcHaptic.emergency);
    final ok = await callPerson(widget.person);
    if (!mounted || ok) return;
    // A silent crisis button is the one failure this surface may never have.
    setState(() {
      _note = "This device can't place calls. Texting still works — or dial "
          '${widget.person.number} from any phone.';
    });
  }

  Future<void> _text() async {
    if (_preparing) return;
    final app = context.appRead;
    setState(() {
      _preparing = true;
      _note = null;
    });
    CcHaptics.instance.fire(CcHaptic.pressFirm);

    // A fix that does not arrive quickly is not worth waiting for. The message
    // goes either way.
    final where = app.shareLocation ? await currentWhereabouts() : null;
    final opened = await textPerson(
      contact: widget.person,
      whereabouts: where,
      senderName: app.senderName,
    );

    if (!mounted) return;
    setState(() {
      _preparing = false;
      _note = opened
          ? null
          : 'No messaging app could be opened. The call button still works.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final name = widget.person.shortName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CcSpace.xs,
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(2),
          child: Semantics(
            button: true,
            label: 'Call $name, your emergency contact',
            excludeSemantics: true,
            child: InkWell(
              onTap: _call,
              borderRadius: t.cardBorderRadius,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: CcStructure.targetCrisis,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: CcSpace.lg,
                  vertical: CcSpace.md,
                ),
                decoration: BoxDecoration(
                  color: t.alert,
                  borderRadius: t.cardBorderRadius,
                ),
                child: Text(
                  'Call $name',
                  textAlign: TextAlign.center,
                  style: context.ccText.titleLarge!.copyWith(color: t.alertInk),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Text $name where you are',
          excludeSemantics: true,
          child: InkWell(
            onTap: _preparing ? null : _text,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CcStructure.targetMin,
              ),
              child: Center(
                child: Text(
                  _preparing ? 'Writing the message…' : 'Text $name instead',
                  textAlign: TextAlign.center,
                  style: context.ccText.bodyMedium!.copyWith(
                    color: t.inkMuted,
                    decoration: TextDecoration.underline,
                    decorationColor: t.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_note != null)
          Text(
            _note!,
            textAlign: TextAlign.center,
            style: context.ccText.bodySmall,
          ),
      ],
    );
  }
}

class _QuietExit extends StatelessWidget {
  const _QuietExit({
    required this.label,
    required this.onTap,
    required this.style,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: () {
        CcHaptics.instance.fire(CcHaptic.pressFirm);
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CcSpace.lg),
          child: Center(
            child: Text(label, textAlign: TextAlign.center, style: style),
          ),
        ),
      ),
    ),
  );
}

/// A care-card contact offered on the panic surfaces when no personal contact
/// has been named. Call only: this is somebody else's contact, so "text them
/// where I am" would be the wrong message to put in anyone's hands.
class CallCareContact extends StatelessWidget {
  const CallCareContact({
    super.key,
    required this.contact,
    required this.cardName,
  });

  final CareContact contact;
  final String cardName;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final relation = contact.relationship.trim();
    final origin = relation.isEmpty
        ? "from $cardName's card"
        : "$relation, from $cardName's card";

    // Deliberately smaller than ReachPerson's crisis-sized button. This is a
    // fallback, not the person they chose, and the pacer has no vertical room
    // to spare — a full-height button pushed the exits off the screen.
    return FocusTraversalOrder(
      order: const NumericFocusOrder(2),
      child: Semantics(
        button: true,
        label: 'Call ${contact.name}, $origin',
        excludeSemantics: true,
        child: InkWell(
          onTap: () {
            CcHaptics.instance.fire(CcHaptic.emergency);
            // Total by construction (the fallback filter guarantees a
            // number), and never silent on a device without a dialler.
            final number = contact.number ?? '';
            if (number.isNotEmpty) dialOrExplain(context, number);
          },
          borderRadius: t.cardBorderRadius,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: CcSpace.lg,
              vertical: CcSpace.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: t.cardBorderRadius,
              border: Border.all(color: t.alert, width: CcStructure.cardEdge),
            ),
            child: Text(
              'Call ${contact.name}',
              textAlign: TextAlign.center,
              style: context.ccText.bodyLarge!.copyWith(
                color: t.alert,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
