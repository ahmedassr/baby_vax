import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';

import '../controller/onboarding_controller.dart';

/// Three short pages explaining what Baby Vax does, before sign-in.
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  const AppLogo(size: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Baby Vax',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  const Spacer(),
                  Obx(() => AnimatedOpacity(
                        opacity: controller.isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: TextButton(
                          key: const Key('onboarding_skip'),
                          onPressed:
                              controller.isLast ? null : controller.finish,
                          child: Text("Onboarding_skip".tr),
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: OnboardingController.pages.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (_, int i) =>
                    _OnboardingPageView(page: OnboardingController.pages[i]),
              ),
            ),
            Obx(() => _Dots(
                  count: OnboardingController.pages.length,
                  current: controller.page.value,
                )),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Obx(() => AppButton(
                    key: const Key('onboarding_next'),
                    text: controller.isLast
                        ? "Onboarding_get_started".tr
                        : "next_label".tr,
                    onPressed: controller.next,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Icon(page.icon, size: 80, color: scheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Semantics(
            header: true,
            child: Text(page.titleKey.tr,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(page.bodyKey.tr,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: "step_counter"
          .trParams({'current': '${current + 1}', 'total': '$count'}),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current ? scheme.primary : scheme.outlineVariant,
                borderRadius: AppRadius.pillAll,
              ),
            ),
        ],
      ),
    );
  }
}
