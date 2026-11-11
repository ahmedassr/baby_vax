import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's font comes from `assets/google_fonts/`, never from the network.
///
/// `google_fonts` would otherwise download Cairo from fonts.gstatic.com on
/// first use. That fails on a first launch without a connection (the app
/// would show the system font), and it sends every device's IP address to
/// Google, which the privacy policy would then have to disclose.
///
/// The bundled `Cairo-Regular.ttf` is byte-for-byte the file `google_fonts`
/// 9.0.0 downloads (SHA-256 d33c4f55…b00, pinned in the package), so
/// rendering is unchanged. It is the only weight bundled because it is the
/// only one the app loads: `GoogleFonts.cairo()` with no weight resolves to
/// the `Cairo_regular` family, which the whole theme uses.
///
/// Call once, before the theme is first built.
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // SIL OFL 1.1 requires the licence to travel with the font. Registering it
  // also lists it on the app's Licenses page.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(cairoLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Cairo font'], license);
  });
}

@visibleForTesting
const String cairoLicenseAsset = 'assets/google_fonts/OFL.txt';
