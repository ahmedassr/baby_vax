import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(Get.reset);

  // The longest Arabic vaccine name, as on the details screen.
  const String longTitle =
      'الجرعة الأولى من اللقاح الخماسي وشلل الأطفال الفموي والمكورات الرئوية '
      'وفيروس الروتا';

  Future<void> pumpBar(WidgetTester tester, {required double textScale}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar:
                CustomAppBar(title: longTitle, fontSize: 18, titleMaxLines: 2),
          ),
        ),
      ),
    ));
    // The scale really reaches the title (up to the cap).
    final BuildContext ctx = tester.element(find.text(longTitle));
    expect(
        MediaQuery.textScalerOf(ctx).scale(10),
        closeTo(
            10 * textScale.clamp(1.0, CustomAppBar.wrappedTitleMaxTextScale),
            0.01));
  }

  for (final double scale in [1.0, 1.1, 1.3, 2.0]) {
    testWidgets(
        'a long title wraps to 2 lines, ellipsised, never clipped '
        '(text scale $scale)', (tester) async {
      await pumpBar(tester, textScale: scale);
      final RenderParagraph p =
          tester.renderObject<RenderParagraph>(find.text(longTitle));
      expect(p.didExceedMaxLines, isTrue, reason: 'should end in an ellipsis');
      expect(p.maxLines, 2);
      expect(p.overflow, TextOverflow.ellipsis);

      // The whole paragraph sits inside the app bar.
      final Rect text = tester.getRect(find.text(longTitle));
      final Rect bar = tester.getRect(find.byType(AppBar));
      expect(text.top, greaterThanOrEqualTo(bar.top));
      expect(text.bottom, lessThanOrEqualTo(bar.bottom));
      // And it really is 2 lines tall, not cut to one.
      final double line = 18 *
          CustomAppBar.wrappedTitleLineHeight *
          scale.clamp(1.0, CustomAppBar.wrappedTitleMaxTextScale);
      expect(text.height, closeTo(2 * line, 1));
    });
  }

  test('without titleMaxLines the bar keeps the standard height', () {
    expect(const CustomAppBar(title: 'Settings').preferredSize.height,
        kToolbarHeight);
  });
}
