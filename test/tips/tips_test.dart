import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tip_details/view/tip_details_view.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';
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
