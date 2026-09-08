/// CARD-EDIT — create and edit.
///
/// Long forms are where people quit. Required fields come first, everything
/// else is collapsed behind progressive disclosure, and every field saves
/// itself: no save button, no save anxiety. Repeatable rows get an obvious add
/// and a non-destructive remove.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../data/suggestions.dart';
import '../../models/care_card.dart';
import '../../routes.dart';
import '../../services/photos.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class CardEditScreen extends StatefulWidget {
  const CardEditScreen({super.key, this.cardId});

  final String? cardId;

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  late CareCardData _card;
  late final bool _isNew;
  late final AppState _app;

  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _doThis = TextEditingController();
  final _dontDo = TextEditingController();
  final _livesWith = TextEditingController();
  final _medications = TextEditingController();
  final _triggers = TextEditingController();
  final _notes = TextEditingController();
  late List<_ContactFields> _contacts;

  Timer? _debounce;
  bool _touched = false;
  bool _showValidation = false;
  bool _disclosureOpen = false;

  /// The printed "version N" should tick once per editing session, not once
  /// per 450ms autosave. Bumped on the first write, then held.
  bool _versionBumped = false;

  int get _nextVersion {
    if (_isNew) return 1;
    if (_versionBumped) return _card.version;
    return _card.version + 1;
  }

  @override
  void initState() {
    super.initState();
    _app = context.appRead;
    final existing = widget.cardId == null
        ? null
        : _app.cardById(widget.cardId!);
    _isNew = existing == null;
    _card =
        existing ??
        CareCardData(
          id: 'card-${DateTime.now().microsecondsSinceEpoch}',
          name: '',
          preparedAt: DateTime.now(),
        );

    _name.text = _card.name;
    _relation.text = _card.relation;
    _doThis.text = _card.doThis.join('\n');
    _dontDo.text = _card.dontDo.join('\n');
    _livesWith.text = _card.livesWith;
    _medications.text = _card.medications;
    _triggers.text = _card.triggers;
    _notes.text = _card.notes;
    _contacts = _card.call.map(_ContactFields.from).toList();
    _disclosureOpen = _card.hasAbout;
  }

  @override
  void dispose() {
    // Flush anything the debounce was still holding: leaving the screen is not
    // a reason to lose the last few words someone typed.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _app.upsertCard(_collect());
    }
    _debounce?.cancel();
    for (final c in [
      _name,
      _relation,
      _doThis,
      _dontDo,
      _livesWith,
      _medications,
      _triggers,
      _notes,
    ]) {
      c.dispose();
    }
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// Autosave. Every keystroke schedules a write; the field says "Saved" once
  /// it lands.
  void _save({bool immediate = false}) {
    _touched = true;
    _debounce?.cancel();
    void write() {
      final updated = _card.copyWith(
        name: _name.text.trim(),
        relation: _relation.text.trim(),
        doThis: _lines(_doThis),
        dontDo: _lines(_dontDo),
        call: _contacts
            .map((c) => c.toContact())
            .where((c) => c.name.isNotEmpty)
            .toList(),
        livesWith: _livesWith.text.trim(),
        medications: _medications.text.trim(),
        triggers: _triggers.text.trim(),
        notes: _notes.text.trim(),
        // Every printed card and PDF carries "version N". Without this bump
        // it stayed at 1 for the life of the card, so a helper holding an old
        // printout had no way to tell it was out of date. Bumps once per
        // editing session (see _nextVersion), not once per autosave.
        version: _nextVersion,
        preparedAt: _card.preparedAt,
      );
      _versionBumped = true;
      _card = updated;
      _app.upsertCard(updated);
      if (mounted) setState(() {});
    }

    if (immediate) {
      write();
    } else {
      _debounce = Timer(const Duration(milliseconds: 450), write);
    }
  }

  CareCardData _collect() => _card.copyWith(
    name: _name.text.trim(),
    relation: _relation.text.trim(),
    doThis: _lines(_doThis),
    dontDo: _lines(_dontDo),
    call: _contacts
        .map((c) => c.toContact())
        .where((c) => c.name.isNotEmpty)
        .toList(),
    livesWith: _livesWith.text.trim(),
    medications: _medications.text.trim(),
    triggers: _triggers.text.trim(),
    notes: _notes.text.trim(),
    version: _isNew ? 1 : _card.version,
  );

  void _toggleLine(TextEditingController controller, String line) {
    final lines = _lines(controller);
    if (lines.contains(line)) {
      lines.remove(line);
    } else {
      lines.add(line);
    }
    controller.text = lines.join('\n');
    _save(immediate: true);
  }

  Future<void> _pickPhoto() async {
    final path = await pickCardPhoto();
    if (path == null || !mounted) return;
    final previous = _card.photoPath;
    _card = _card.copyWith(photoPath: path);
    _app.upsertCard(_card);
    // The replaced copy would otherwise sit in storage forever.
    if (previous != null && previous != path) {
      unawaited(deleteCardPhoto(previous));
    }
    setState(() {});
  }

  Future<void> _delete() async {
    final ok = await DestructiveConfirm.show(
      context,
      title: StateCopy.deleteCardTitle,
      consequence: StateCopy.deleteCardBody,
      confirmLabel: StateCopy.deleteCardConfirm,
      cancelLabel: StateCopy.deleteCardCancel,
    );
    if (!ok || !mounted) return;
    _app.deleteCard(_card.id);
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (r) => false);
  }

  String? get _status {
    if (!_touched && _isNew) return null;
    return 'Saved';
  }

  @override
  Widget build(BuildContext context) {
    final doLines = _lines(_doThis);
    final dontLines = _lines(_dontDo);
    final nameMissing = _name.text.trim().isEmpty;

    return CalmScaffold(
      child: CcScreen(
        gap: CcGap.lg,
        children: [
          const CcBackBar(label: 'Done'),
          CcSpread(
            children: [
              FieldLabel(_isNew ? 'New card' : 'Editing card'),
              Semantics(
                liveRegion: true,
                child: Text(
                  _touched || !_isNew ? 'Saved' : 'Nothing to save yet',
                  style: context.ccText.labelSmall,
                ),
              ),
            ],
          ),

          // 1. Who this is
          TextFieldRow(
            label: 'Who is this card for?',
            controller: _name,
            hint: 'First name is enough',
            status: _status,
            error: _showValidation && nameMissing
                ? 'This card needs a name before it can be shared.'
                : null,
            onChanged: (_) => _save(),
          ),
          TextFieldRow(
            label: 'Their relationship to you',
            controller: _relation,
            hint: 'grandfather · age 9 · brother',
            status: _status,
            onChanged: (_) => _save(),
          ),
          FieldRow(
            label: 'Photo',
            divided: false,
            child: _PhotoRow(
              path: _card.photoPath,
              initial: _name.text.trim().isEmpty
                  ? '+'
                  : _name.text.trim().characters.first.toUpperCase(),
              onPick: _pickPhoto,
              onRemove: _card.photoPath == null
                  ? null
                  : () {
                      final removed = _card.photoPath;
                      _card = _card.copyWith(clearPhoto: true);
                      _app.upsertCard(_card);
                      unawaited(deleteCardPhoto(removed));
                      setState(() {});
                    },
            ),
          ),

          // 2. What to do
          TextFieldRow(
            label: 'What to do',
            controller: _doThis,
            multiline: true,
            status: doLines.isEmpty ? null : 'Saved',
            helper: 'Clear, short steps. Most important first.',
            onChanged: (_) => _save(),
          ),
          SuggestionPicker(
            tone: GuidanceTone.doThis,
            groups: doSuggestions,
            chosen: doLines,
            onToggle: (line) => _toggleLine(_doThis, line),
          ),

          // 3. What not to do
          TextFieldRow(
            label: 'What not to do',
            controller: _dontDo,
            multiline: true,
            status: dontLines.isEmpty ? null : 'Saved',
            helper:
                'Things that make it worse. This is often the most useful '
                'part of the card.',
            onChanged: (_) => _save(),
          ),
          SuggestionPicker(
            tone: GuidanceTone.dontDo,
            groups: dontSuggestions,
            chosen: dontLines,
            onToggle: (line) => _toggleLine(_dontDo, line),
          ),

          // 4. Who to call
          FieldRow(
            label: 'Who to call',
            tone: _contacts.isEmpty ? CcTone.alert : CcTone.neutral,
            divided: false,
            child: CcStack(
              gap: CcGap.lg,
              children: [
                // Said out loud rather than left as an empty space. This is
                // the field a stranger reaches for last and needs most.
                if (_contacts.isEmpty)
                  const CcCaption(
                    'Nobody yet. Whoever picks this card up will have no one '
                    'to ring.',
                  ),
                for (var i = 0; i < _contacts.length; i++)
                  _ContactRowEditor(
                    fields: _contacts[i],
                    onChanged: _save,
                    // Removing is non-destructive: it lifts the row out, and
                    // nothing else on the card moves.
                    onRemove: () {
                      final removed = _contacts.removeAt(i);
                      setState(() {});
                      _save(immediate: true);
                      // Dispose after the frame that unmounts the TextFields;
                      // disposing synchronously here trips "used after being
                      // disposed" when the EditableTexts detach.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => removed.dispose(),
                      );
                    },
                  ),
                _AddRow(
                  label: _contacts.isEmpty
                      ? 'Add someone to call'
                      : 'Add another person',
                  onTap: () =>
                      setState(() => _contacts.add(_ContactFields.empty())),
                ),
              ],
            ),
          ),

          const CcRule(),

          // 5. Everything else, behind progressive disclosure
          _Disclosure(
            open: _disclosureOpen,
            title: 'Everything else — condition, medications, triggers, notes',
            onToggle: () => setState(() => _disclosureOpen = !_disclosureOpen),
            child: CcStack(
              gap: CcGap.lg,
              children: [
                TextFieldRow(
                  label: 'What they live with',
                  controller: _livesWith,
                  multiline: true,
                  status: _livesWith.text.isEmpty ? null : 'Saved',
                  helper:
                      'In your own words. This is for whoever picks up the '
                      'card, not for a doctor.',
                  onChanged: (_) => _save(),
                ),
                TextFieldRow(
                  label: 'Medications',
                  controller: _medications,
                  status: _medications.text.isEmpty ? null : 'Saved',
                  onChanged: (_) => _save(),
                ),
                TextFieldRow(
                  label: 'What can set things off',
                  controller: _triggers,
                  status: _triggers.text.isEmpty ? null : 'Saved',
                  onChanged: (_) => _save(),
                ),
                TextFieldRow(
                  label: 'Anything else',
                  controller: _notes,
                  multiline: true,
                  status: _notes.text.isEmpty ? null : 'Saved',
                  onChanged: (_) => _save(),
                ),
              ],
            ),
          ),

          if (_showValidation && nameMissing)
            const AlertBlock(
              label: 'Not shareable yet',
              body:
                  "A card without a name can't be shared — whoever scans it "
                  "wouldn't know who it's about. It's still saved on this device.",
            ),

          const CcRule(),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                'Share this card',
                variant: CcButtonVariant.secondary,
                fullWidth: true,
                onPressed: () {
                  _save(immediate: true);
                  if (nameMissing) {
                    setState(() => _showValidation = true);
                    return;
                  }
                  Navigator.of(
                    context,
                  ).pushNamed(Routes.cardShare, arguments: _card.id);
                },
              ),
              CcButton(
                'Delete this card',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: _delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactFields {
  _ContactFields(this.name, this.relationship, this.number);

  factory _ContactFields.empty() => _ContactFields(
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  );

  factory _ContactFields.from(CareContact c) => _ContactFields(
    TextEditingController(text: c.name),
    TextEditingController(text: c.relationship),
    TextEditingController(text: c.number ?? ''),
  );

  final TextEditingController name;
  final TextEditingController relationship;
  final TextEditingController number;

  CareContact toContact() => CareContact(
    name: name.text.trim(),
    relationship: relationship.text.trim(),
    number: number.text.trim().isEmpty ? null : number.text.trim(),
  );

  void dispose() {
    name.dispose();
    relationship.dispose();
    number.dispose();
  }
}

class _ContactRowEditor extends StatelessWidget {
  const _ContactRowEditor({
    required this.fields,
    required this.onChanged,
    required this.onRemove,
  });

  final _ContactFields fields;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.md),
      decoration: BoxDecoration(
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: CcStack(
        gap: CcGap.md,
        children: [
          TextFieldRow(
            label: 'Name',
            controller: fields.name,
            hint: 'Their name',
            onChanged: (_) => onChanged(),
          ),
          TextFieldRow(
            label: 'Relationship',
            controller: fields.relationship,
            hint: 'daughter',
            onChanged: (_) => onChanged(),
          ),
          TextFieldRow(
            label: 'Number',
            controller: fields.number,
            hint: '07700 900 118',
            keyboardType: TextInputType.phone,
            onChanged: (_) => onChanged(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CcButton(
              'Remove',
              variant: CcButtonVariant.secondary,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: t.cardBorderRadius,
        child: DottedFrame(
          color: t.rule,
          radius: t.radiusCard,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: CcSpace.lg,
              vertical: CcSpace.md,
            ),
            child: Text(
              label,
              style: context.ccText.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.path,
    required this.initial,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final String initial;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final file = photoFile(path);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: CcSpace.md,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: t.rule, width: CcStructure.cardEdge),
            borderRadius: BorderRadius.circular(3),
          ),
          child: file != null
              ? Image.file(file, fit: BoxFit.cover, width: 56, height: 56)
              : Text(initial, style: context.ccText.titleLarge),
        ),
        Expanded(
          child: CcButton(
            file != null ? 'Change photo' : 'Add a photo (optional)',
            variant: CcButtonVariant.quiet,
            onPressed: onPick,
          ),
        ),
        if (onRemove != null)
          CcButton(
            'Remove',
            variant: CcButtonVariant.quiet,
            onPressed: onRemove,
          ),
      ],
    );
  }
}

/// Progressive disclosure, printed rather than chevroned: the summary line says
/// exactly what is inside.
class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.open,
    required this.title,
    required this.onToggle,
    required this.child,
  });

  final bool open;
  final String title;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return CcStack(
      gap: CcGap.md,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CcStructure.targetMin,
              ),
              child: Row(
                spacing: CcSpace.md,
                children: [
                  Expanded(
                    child: Text(title, style: context.ccText.bodyMedium),
                  ),
                  Icon(
                    open ? Icons.remove : Icons.add,
                    size: 20,
                    color: t.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) child,
      ],
    );
  }
}
