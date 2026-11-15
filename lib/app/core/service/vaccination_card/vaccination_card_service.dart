import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../modules/medical_dates/model/medical_dates_model.dart';
import '../../utils/app_shared_model/user_model.dart';
import 'vaccination_card_data.dart';
import 'vaccination_card_pdf.dart';

/// Builds the vaccination card PDF on the device and hands it to the
/// system share or print sheet. Works offline: the font is bundled and
/// nothing is uploaded.
class VaccinationCardService {
  VaccinationCardService({
    Future<pw.Font> Function()? loadFont,
    Future<void> Function(Uint8List bytes, String fileName)? share,
    Future<void> Function(Uint8List bytes, String fileName)? print,
    DateTime Function()? clock,
  })  : _loadFont = loadFont ?? _bundledCairo,
        _share = share ?? _systemShare,
        _print = print ?? _systemPrint,
        _now = clock ?? DateTime.now;

  final Future<pw.Font> Function() _loadFont;
  final Future<void> Function(Uint8List, String) _share;
  final Future<void> Function(Uint8List, String) _print;
  final DateTime Function() _now;

  /// The same Cairo file the app's UI uses; it covers Latin and Arabic.
  static const String fontAsset = 'assets/google_fonts/Cairo-Regular.ttf';

  static Future<pw.Font> _bundledCairo() async =>
      pw.Font.ttf(await rootBundle.load(fontAsset));

  static Future<void> _systemShare(Uint8List bytes, String name) async {
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  static Future<void> _systemPrint(Uint8List bytes, String name) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
  }

  /// The card's content and its PDF bytes.
  Future<(VaccinationCardData, Uint8List)> build(
      UserModel user, Iterable<MedicalDatesModel> doses) async {
    final VaccinationCardData data =
        VaccinationCardData.build(user: user, doses: doses, now: _now());
    final Uint8List bytes =
        await VaccinationCardPdf.build(data, font: await _loadFont());
    return (data, bytes);
  }

  Future<void> share(UserModel user, Iterable<MedicalDatesModel> doses) async {
    final (VaccinationCardData data, Uint8List bytes) =
        await build(user, doses);
    await _share(bytes, data.fileName);
  }

  Future<void> print(UserModel user, Iterable<MedicalDatesModel> doses) async {
    final (VaccinationCardData data, Uint8List bytes) =
        await build(user, doses);
    await _print(bytes, data.fileName);
  }
}
