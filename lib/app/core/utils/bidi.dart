import 'package:get/get.dart';

/// FIRST STRONG ISOLATE: the text up to [_pdi] takes its direction from its
/// own first strong character, independently of what surrounds it.
final String _fsi = String.fromCharCode(0x2068);

/// POP DIRECTIONAL ISOLATE: ends the isolate opened by [_fsi].
final String _pdi = String.fromCharCode(0x2069);

/// Wraps [text] so it keeps its own direction inside text of the other
/// direction.
///
/// Without this an English name in the Arabic UI ("BCG and Hepatitis B (1st
/// dose)", a custom date, an email) has its trailing ")" or "." pulled to
/// the wrong end, and an Arabic child name inside an English reminder
/// reorders the words around it. Paragraph alignment is unchanged: the
/// isolate only fixes the order inside the value.
///
/// Use it for any text that is data (user input, names, emails, dates
/// inserted into a sentence), not for whole translated strings.
String bidiIsolate(String text) {
  if (text.isEmpty) return text;
  if (text.startsWith(_fsi) && text.endsWith(_pdi)) return text;
  return '$_fsi$text$_pdi';
}

/// Removes the isolate marks again, for comparisons and tests.
String stripBidiIsolates(String text) =>
    text.replaceAll(_fsi, '').replaceAll(_pdi, '');

extension BidiTranslate on String {
  /// [trParams] with every inserted value isolated (see [bidiIsolate]).
  String trIsolated(Map<String, String> params) => trParams(<String, String>{
        for (final MapEntry<String, String> p in params.entries)
          p.key: bidiIsolate(p.value),
      });
}
