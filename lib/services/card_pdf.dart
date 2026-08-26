/// CARD-PDF — the printable care card.
///
/// A card that works on paper, on a fridge door, in a school bag. Pure black on
/// white, no gradients and no background fills that eat ink, the same fixed
/// information order and the same micro-labels as the screen. The lower third
/// is a cut-and-fold wallet card carrying the two sections that matter.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/care_card.dart';

enum PaperSize { a4, letter }

extension PaperSizeX on PaperSize {
  PdfPageFormat get format =>
      this == PaperSize.a4 ? PdfPageFormat.a4 : PdfPageFormat.letter;

  String get label =>
      this == PaperSize.a4 ? 'A4 · 210 × 297 mm' : 'US Letter · 8.5 × 11 in';
}

class _Faces {
  const _Faces(this.content, this.contentBold, this.label);

  final pw.Font content;
  final pw.Font contentBold;
  final pw.Font label;
}

_Faces? _cached;

Future<_Faces> _faces() async {
  if (_cached != null) return _cached!;
  Future<pw.Font> load(String path) async =>
      pw.Font.ttf(await rootBundle.load(path));
  _cached = _Faces(
    await load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'),
    await load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'),
    await load('assets/fonts/IBMPlexMono-SemiBold.ttf'),
  );
  return _cached!;
}

Future<Uint8List> buildCardPdf(
  CareCardData card, {
  PaperSize paper = PaperSize.a4,
}) async {
  final f = await _faces();
  final doc = pw.Document(
    title: '${card.name} — care card',
    author: 'CalmCheck',
  );

  pw.TextStyle body([double size = 10.5, bool bold = false]) => pw.TextStyle(
    font: bold ? f.contentBold : f.content,
    fontSize: size,
    color: PdfColors.black,
    lineSpacing: 2.2,
  );

  pw.Widget microLabel(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        font: f.label,
        fontSize: 7.5,
        letterSpacing: 1.2,
        color: PdfColors.black,
      ),
    ),
  );

  /// Channel two: shape. A filled square is Do; an open ring with a bar
  /// through it is Do not. Both survive a greyscale printer.
  pw.Widget marker({required bool isDo}) => pw.Container(
    width: 9,
    height: 9,
    margin: const pw.EdgeInsets.only(top: 3, right: 7),
    decoration: pw.BoxDecoration(
      color: isDo ? PdfColors.black : null,
      shape: isDo ? pw.BoxShape.rectangle : pw.BoxShape.circle,
      border: isDo ? null : pw.Border.all(width: 1.2),
    ),
    child: isDo
        ? null
        : pw.Center(
            child: pw.Container(width: 9, height: 1.4, color: PdfColors.black),
          ),
  );

  pw.Widget guidance(String text, {required bool isDo, double size = 10.5}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            marker(isDo: isDo),
            pw.Expanded(child: pw.Text(text, style: body(size, !isDo))),
          ],
        ),
      );

  pw.Widget rule() => pw.Container(
    height: 0.7,
    margin: const pw.EdgeInsets.symmetric(vertical: 10),
    color: PdfColors.black,
  );

  pw.Widget dashed(String caption) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Expanded(child: pw.Container(height: 0.7, color: PdfColors.grey600)),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
        child: pw.Text(
          caption,
          style: pw.TextStyle(
            font: f.label,
            fontSize: 7,
            letterSpacing: 1.2,
            color: PdfColors.grey700,
          ),
        ),
      ),
      pw.Expanded(child: pw.Container(height: 0.7, color: PdfColors.grey600)),
    ],
  );

  doc.addPage(
    pw.Page(
      pageFormat: paper.format,
      margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. Who this is
          microLabel('Care card'),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: card.name, style: body(20, true)),
                if (card.relation.isNotEmpty)
                  pw.TextSpan(text: '  — ${card.relation}', style: body(13)),
              ],
            ),
          ),
          if (card.livesWith.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            microLabel('What they live with'),
            pw.Text(card.livesWith, style: body()),
          ],
          rule(),

          // 2. WHAT TO DO
          if (card.doThis.isNotEmpty) ...[
            microLabel('What to do'),
            ...card.doThis.map((t) => guidance(t, isDo: true)),
            pw.SizedBox(height: 10),
          ],

          // 3. DO NOT
          if (card.dontDo.isNotEmpty) ...[
            microLabel('Do not'),
            ...card.dontDo.map((t) => guidance(t, isDo: false)),
            pw.SizedBox(height: 10),
          ],

          // 4. CALL
          if (card.call.isNotEmpty) ...[
            microLabel('Call'),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1.4),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                for (final c in card.call)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: c.name, style: body(11, true)),
                              if (c.relationship.isNotEmpty)
                                pw.TextSpan(
                                  text: '  ${c.relationship}',
                                  style: body(9),
                                ),
                            ],
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Text(
                          c.number ?? 'No number saved',
                          style: pw.TextStyle(
                            font: f.label,
                            fontSize: 10.5,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // 5. Everything else
          if (card.hasAbout) ...[
            microLabel('About'),
            if (card.medications.isNotEmpty)
              _dl(f, 'Medications', card.medications),
            if (card.triggers.isNotEmpty)
              _dl(f, 'What can set things off', card.triggers),
            if (card.notes.isNotEmpty) _dl(f, 'Anything else', card.notes),
          ],

          pw.Spacer(),

          // The direction's thesis made literal: cut it out and carry it.
          pw.SizedBox(height: 12),
          dashed('cut here'),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 150,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(9),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        microLabel('Care card · ${card.name}'),
                        microLabel('Do not'),
                        ...card.dontDo
                            .take(4)
                            .map((t) => guidance(t, isDo: false, size: 8.5)),
                      ],
                    ),
                  ),
                ),
                pw.Container(width: 0.7, color: PdfColors.grey600),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(9),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        microLabel('What to do'),
                        ...card.doThis
                            .take(4)
                            .map((t) => guidance(t, isDo: true, size: 8.5)),
                        pw.Spacer(),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: card.toShareString(),
                              width: 46,
                              height: 46,
                              drawText: false,
                              color: PdfColors.black,
                            ),
                            pw.SizedBox(width: 8),
                            if (card.call.isNotEmpty)
                              pw.Expanded(
                                child: pw.Text(
                                  'Call ${card.call.first.name} '
                                  '${card.call.first.number ?? ''}',
                                  style: pw.TextStyle(
                                    font: f.label,
                                    fontSize: 7.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'fold along the centre line',
              style: pw.TextStyle(
                font: f.label,
                fontSize: 7,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            card.meta,
            style: pw.TextStyle(
              font: f.label,
              fontSize: 7.5,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _dl(_Faces f, String term, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 5),
  child: pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '${term.toUpperCase()}   ',
          style: pw.TextStyle(font: f.label, fontSize: 7.5, letterSpacing: 1.2),
        ),
        pw.TextSpan(
          text: value,
          style: pw.TextStyle(
            font: f.content,
            fontSize: 10.5,
            lineSpacing: 2.2,
          ),
        ),
      ],
    ),
  ),
);
