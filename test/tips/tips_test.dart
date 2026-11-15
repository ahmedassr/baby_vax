import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tip_details/view/tip_details_view.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';
import 'package:baby_vax/app/modules/tips/widget/tip_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  final List<TipsModel> tips = <TipsModel>[
    TipsModel(
        id: 't1',
        title: 'نوم آمن للرضيع',
        description: 'ضع طفلك على ظهره عند النوم. ' * 6),
    TipsModel(id: 't2', title: 'Bath time', description: 'Short and warm.'),
  ];

  for (final Variant v in mainVariants) {
    testWidgets('tips list fits ($v)', (tester) async {
      Get.put<TipsController>(TipsController(load: (_) async => tips));
      await pumpApp(tester, const Scaffold(body: TipsView()), variant: v);
      await tester.pumpAndSettle();
      expect(find.textContaining('Bath time'), findsOneWidget);
      expectNoOverflow(tester);
    });
  }

  /// The fill of every tip card on screen, top to bottom.
  List<Color?> cardColors(WidgetTester tester) => <Color?>[
        for (final Element e in find.byType(TipCard).evaluate())
          tester
              .widget<Material>(find
                  .descendant(
                      of: find.byWidget(e.widget),
                      matching: find.byType(Material))
                  .first)
              .color,
      ];

  for (final Variant v in mainVariants) {
    testWidgets('every tip card has the same background ($v)', (tester) async {
      Get.put<TipsController>(
          TipsController(load: (_) async => <TipsModel>[...tips, ...tips]));
      await pumpApp(tester, const Scaffold(body: TipsView()), variant: v);
      await tester.pumpAndSettle();
      final ColorScheme scheme =
          Theme.of(tester.element(find.byType(TipsView))).colorScheme;
      final List<Color?> colors = cardColors(tester);
      expect(colors.length, greaterThan(1));
      expect(colors.toSet(), <Color?>{scheme.surface});
      expectNoOverflow(tester);
    });
  }

  testWidgets('keyboard focus rings a card instead of changing its fill',
      (tester) async {
    Get.put<TipsController>(TipsController(load: (_) async => tips));
    await pumpApp(tester, const Scaffold(body: TipsView()),
        variant: const Variant('ar', Brightness.dark, 1.3));
    await tester.pumpAndSettle();
    final ColorScheme scheme =
        Theme.of(tester.element(find.byType(TipsView))).colorScheme;
    // A key press switches Flutter to keyboard highlights, as the Back key
    // can on Android; then focus the first card.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
    expect(cardColors(tester).toSet(), <Color?>{scheme.surface});
    final Material first = tester.widget<Material>(find
        .descendant(
            of: find.byType(TipCard).first, matching: find.byType(Material))
        .first);
    final RoundedRectangleBorder shape = first.shape! as RoundedRectangleBorder;
    expect(shape.side.color, scheme.primary, reason: 'focus ring');
    // No translucent focus fill is painted over the card either.
    final InkWell ink = tester.widget<InkWell>(find
        .descendant(
            of: find.byType(TipCard).first, matching: find.byType(InkWell))
        .first);
    expect(ink.focusColor, Colors.transparent);
    expect(ink.highlightColor, Colors.transparent);
  });

  testWidgets('loads the collection for the current language', (tester) async {
    final List<String> asked = <String>[];
    Get.put<TipsController>(TipsController(load: (c) async {
      asked.add(c);
      return tips;
    }));
    await pumpApp(tester, const Scaffold(body: TipsView()),
        variant: const Variant('ar', Brightness.light, 1.0));
    await tester.pumpAndSettle();
    expect(asked.last, 'tips');
  });

  testWidgets('empty state', (tester) async {
    Get.put<TipsController>(TipsController(load: (_) async => <TipsModel>[]));
    await pumpApp(tester, const Scaffold(body: TipsView()));
    await tester.pumpAndSettle();
    expect(find.text('No tips yet'), findsOneWidget);
  });

  testWidgets('a failed load shows Retry', (tester) async {
    Get.put<TipsController>(
        TipsController(load: (_) async => throw Exception('offline')));
    await pumpApp(tester, const Scaffold(body: TipsView()));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });

  for (final Variant v in mainVariants) {
    testWidgets('tip details fit, with the disclaimer ($v)', (tester) async {
      Get.put<TipDetailsController>(TipDetailsController(tip: tips[0]));
      await pumpApp(tester, const TipDetailsView(), variant: v);
      await tester.pumpAndSettle();
      expect(find.textContaining('نوم آمن'), findsOneWidget);
      expectNoOverflow(tester);
    });
  }

  testWidgets('tip details without a tip offers a way back', (tester) async {
    Get.put<TipDetailsController>(TipDetailsController());
    await pumpApp(tester, const TipDetailsView());
    expect(find.text('Back'), findsOneWidget);
  });
}
