import 'package:baby_vax/app/core/imports/import_manger.dart';

extension SizedBoxExtension on num {
  SizedBox get sbh => SizedBox(height: toDouble().h);

  SizedBox get sbw => SizedBox(width: toDouble().w);
}


