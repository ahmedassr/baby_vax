import 'dart:typed_data';

import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../config/themes/app_palette.dart';
import '../../../config/themes/app_status_colors.dart';
import 'vaccination_card_data.dart';

/// Draws the vaccination card as an A4 PDF, entirely on the device.
///
/// Bilingual throughout: every label is English with Arabic beside it, and
/// each vaccine name is printed in both languages, so the same card works at
/// a clinic in either language. The bundled Cairo font covers both scripts;
/// the pdf package shapes Arabic and lays it out right to left.
class VaccinationCardPdf {
  const VaccinationCardPdf._();

  /// The PDF bytes for [data], drawn with [font] (Cairo).
  static Future<Uint8List> build(
    VaccinationCardData data, {
    required pw.Font font,
    Map<String, Map<String, String>>? translations,
  }) async {
    final Map<String, Map<String, String>> t =
        translations ?? AppTranslations().keys;
    String en(String k) => t['en']?[k] ?? k;
    String ar(String k) => t['ar']?[k] ?? en(k);

    final PdfColor ink = PdfColor.fromInt(AppPalette.lightOnSurface.toARGB32());
    final PdfColor muted =
        PdfColor.fromInt(AppPalette.lightOnSurfaceVariant.toARGB32());
    final PdfColor brand = PdfColor.fromInt(AppPalette.brandDark.toARGB32());
    final PdfColor line =
        PdfColor.fromInt(AppPalette.lightOutlineVariant.toARGB32());
    final PdfColor band =
        PdfColor.fromInt(AppPalette.lightPrimaryContainer.toARGB32());

    pw.TextStyle style(double size, {PdfColor? color}) =>
        pw.TextStyle(font: font, fontSize: size, color: color ?? ink);

    pw.Widget arText(String text, double size, {PdfColor? color}) => pw.Text(
          text,
          style: style(size, color: color),
          textDirection: pw.TextDirection.rtl,
        );

    /// English on top, Arabic under it, right-aligned.
    pw.Widget both(String e, String a, double size, {PdfColor? color}) =>
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Text(e, style: style(size, color: color)),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: arText(a, size, color: color),
            ),
          ],
        );

    pw.Widget factWidget(String key, pw.Widget value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.SizedBox(
                width: 150,
                child: pw.Row(children: <pw.Widget>[
                  pw.Text('${en(key)} / ', style: style(9, color: muted)),
                  arText(ar(key), 9, color: muted),
                ]),
              ),
              pw.Expanded(child: value),
            ],
          ),
        );

    /// "Label / التسمية: value". Values start at the same edge whatever
    /// their script, so an Arabic name lines up with the dates under it.
    pw.Widget fact(String key, String value) => factWidget(
        key,
        pw.Text(value,
            style: style(11),
            textAlign: pw.TextAlign.left,
            textDirection: _hasArabic(value) ? pw.TextDirection.rtl : null));

    PdfColor statusColor(DoseDisplayStatus s) {
      final c = AppStatusColors.light.forStatus(s).foreground;
      return PdfColor.fromInt(c.toARGB32());
    }

    final List<pw.Widget> header = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: band,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('Baby Vax', style: style(10, color: brand)),
                  pw.Text(en('Card_title'), style: style(18)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  arText(ar('app_name'), 10, color: brand),
                  arText(ar('Card_title'), 18),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      fact('Signup_baby_name_label',
          data.childName.isEmpty ? '—' : data.childName),
      fact('date_of_birth_label', data.birthDate ?? '—'),
      data.sex == null
          ? fact('Signup_sex_label', '—')
          : factWidget(
              'Signup_sex_label',
              pw.Row(children: <pw.Widget>[
                pw.Text('${data.sex!.en} / ', style: style(11)),
                arText(data.sex!.ar, 11),
              ])),
      pw.SizedBox(height: 12),
    ];

    final List<String> columns = <String>[
      'Card_col_vaccine',
      'Card_col_status',
      'Card_col_scheduled',
      'Card_col_given',
      'Card_col_clinic',
      'Card_col_lot',
    ];

    final pw.Table table = pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: line, width: 0.5),
        bottom: pw.BorderSide(color: line, width: 0.5),
        top: pw.BorderSide(color: line, width: 0.5),
      ),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(3.2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(1.3),
        4: pw.FlexColumnWidth(1.8),
        5: pw.FlexColumnWidth(1.2),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: band),
          children: <pw.Widget>[
            for (final String c in columns)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: both(en(c), ar(c), 8, color: muted),
              ),
          ],
        ),
        for (final CardRow r in data.rows)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: both(r.vaccine.en, r.vaccine.ar, 8.5),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: both(r.status.en, r.status.ar, 8.5,
                    color: statusColor(r.displayStatus)),
              ),
              _cell(r.scheduled, style(8.5)),
              _cell(r.given ?? '—', style(8.5)),
              _cell(r.clinic ?? '—', style(8.5)),
              _cell(r.lot ?? '—', style(8.5)),
            ],
          ),
      ],
    );

    final pw.Document doc = pw.Document(
      title: '${en('Card_title')} — ${data.childName}',
      author: 'Baby Vax',
      creator: 'Baby Vax',
    );
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      build: (pw.Context _) => <pw.Widget>[...header, table],
      footer: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Divider(color: line, thickness: 0.5),
          pw.Text(en('MedicalDisclaimer_body'), style: style(7, color: muted)),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: arText(ar('MedicalDisclaimer_body'), 7, color: muted),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  '${en('Card_generated')} ${data.generatedOn}',
                  style: style(7, color: muted),
                ),
              ),
              pw.Text('${ctx.pageNumber}/${ctx.pagesCount}',
                  style: style(7, color: muted)),
            ],
          ),
        ],
      ),
    ));
    return doc.save();
  }

  static pw.Widget _cell(String text, pw.TextStyle style) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: _auto(text, style),
      );

  /// User text (clinic names, notes) in whichever script it was typed in.
  static pw.Widget _auto(String text, pw.TextStyle style) => pw.Text(
        text,
        style: style,
        textDirection: _hasArabic(text) ? pw.TextDirection.rtl : null,
      );

  static bool _hasArabic(String s) =>
      s.runes.any((int r) => r >= 0x0600 && r <= 0x06FF);
}
