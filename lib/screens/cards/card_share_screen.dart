/// CARD-SHARE.
///
/// The QR is the hero: it has to scan from a screen at arm's length in poor
/// light, so it sits on forced paper-white with a generous quiet zone. The code
/// carries the whole card — there is no link, no lookup and no account behind
/// it, which is why it works with no signal.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../routes.dart';
import '../../services/card_file.dart';
import '../../services/card_pdf.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

enum _ShareState { idle, generating, ready }

class CardShareScreen extends StatefulWidget {
  const CardShareScreen({super.key, required this.cardId});

  final String cardId;

  @override
  State<CardShareScreen> createState() => _CardShareScreenState();
}

class _CardShareScreenState extends State<CardShareScreen> {
  final GlobalKey _shareButtonKey = GlobalKey();
  _ShareState _state = _ShareState.idle;
  PaperSize _paper = PaperSize.a4;
  String? _pdfPath;
  String? _error;

  Future<void> _makePdf() async {
    final app = context.appRead;
    final card = app.cardById(widget.cardId);
    if (card == null) return;

    // PDF export is Pro; reading, calling and sharing a card never are.
    if (!app.canExportPdf) {
      Navigator.of(context).pushNamed(Routes.paywall, arguments: 'pdf-export');
      return;
    }

    setState(() {
      _state = _ShareState.generating;
      _error = null;
    });
    try {
      final bytes = await buildCardPdf(card, paper: _paper);
      final dir = await getApplicationDocumentsDirectory();
      final safeName = card.name
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
          .toLowerCase();
      final file = File('${dir.path}/$safeName-care-card.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
        _state = _ShareState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ShareState.idle;
        _error = "The PDF didn't finish. Nothing has changed on the card.";
      });
    }
  }

  Future<void> _openPdf() async {
    final card = context.appRead.cardById(widget.cardId);
    if (card == null) return;
    final bytes = await buildCardPdf(card, paper: _paper);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${card.name} — care card',
    );
  }

  /// Shares the card file — the counterpart to "Open a card file instead" on
  /// the scan screen — plus the PDF if one has been made. Both are files on
  /// this device; neither is uploaded anywhere.
  Future<void> _shareFile() async {
    final card = context.appRead.cardById(widget.cardId);
    if (card == null) return;
    final cardFile = await writeCardFile(card);
    // Popped while the file was being written: a defunct State has no
    // MediaQuery to anchor the share sheet to.
    if (!mounted) return;
    final files = <XFile>[XFile(cardFile.path)];
    if (_pdfPath != null) files.add(XFile(_pdfPath!));
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: '${card.name} — care card',
        // iPadOS anchors the share sheet to a rectangle and throws without
        // one. The app is portrait-first but it still runs on an iPad.
        sharePositionOrigin: _shareOrigin(),
      ),
    );
  }

  /// The share button's own rectangle, in global coordinates.
  Rect _shareOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromLTWH(size.width / 2, size.height - 1, 1, 1);
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final card = app.cardById(widget.cardId);
    if (card == null) {
      return const CalmScaffold(child: CcScreen(children: [CcBackBar()]));
    }

    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              const CcHeadline('Share this card'),
              const CcBody(
                'Anyone can scan this code to read the card. No app account, '
                'no internet needed.',
              ),
              QrPanel(
                data: card.toShareString(),
                caption: '${card.name} — care card · version ${card.version}',
              ),
              _PaperChoice(
                paper: _paper,
                onChanged: (p) => setState(() {
                  _paper = p;
                  _state = _ShareState.idle;
                  _pdfPath = null;
                }),
              ),
              if (_state == _ShareState.ready)
                AlertBlock(
                  label: 'PDF ready',
                  body:
                      '${_pdfPath!.split('/').last} — one page, '
                      '${_paper == PaperSize.a4 ? 'A4' : 'US Letter'}. '
                      'Saved to this device.',
                ),
              if (_error != null)
                NoticeBlock(label: 'Not saved', body: _error!),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                _state == _ShareState.ready ? 'Open PDF' : 'Save as PDF',
                size: CcButtonSize.lg,
                fullWidth: true,
                loading: _state == _ShareState.generating,
                loadingLabel: 'Making the PDF…',
                onPressed: _state == _ShareState.ready ? _openPdf : _makePdf,
              ),
              KeyedSubtree(
                key: _shareButtonKey,
                child: CcButton(
                  'Share file',
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: _shareFile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The same artifact on two papers. A4 and US Letter, nothing else to choose.
class _PaperChoice extends StatelessWidget {
  const _PaperChoice({required this.paper, required this.onChanged});

  final PaperSize paper;
  final ValueChanged<PaperSize> onChanged;

  @override
  Widget build(BuildContext context) {
    return CcStack(
      gap: CcGap.sm,
      children: [
        FieldLabel('Paper'),
        CcCaption(paper.label),
        Row(
          spacing: CcSpace.md,
          children: [
            for (final size in PaperSize.values)
              Expanded(
                child: CcButton(
                  size == PaperSize.a4 ? 'A4' : 'US Letter',
                  variant: paper == size
                      ? CcButtonVariant.primary
                      : CcButtonVariant.secondary,
                  onPressed: () => onChanged(size),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
