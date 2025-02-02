import 'package:baby_vax/shared/style/Colors.dart';
import 'package:baby_vax/view/layout/Home.dart';
import 'package:baby_vax/view/login_screen/LoginScreen.dart';
import 'package:baby_vax/view/onboarding_screen/Text.dart';
import 'package:baby_vax/widget/buildOnboardingItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../shared/Components.dart';
import 'model/OnboardingModel.dart';

class OnboardingScreen extends ConsumerWidget {
  OnboardingScreen({super.key});

  List<OnboardingModel> onboardingList = [
    OnboardingModel(image: 'assets/images/onboarding1.png', title: text1),
    OnboardingModel(image: 'assets/images/onboarding2.png', title: text2),
    OnboardingModel(image: 'assets/images/onboarding3.png', title: text3),
  ];
  var pageController = PageController();
  int? currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextButton(
                onPressed: () {
                  myNavigator(context,  LoginScreen());
                },
                child: CustomBoldText(
                    title: 'تخطي', size: 24, background: primaryColor)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: onboardingList.length,
              itemBuilder: (context, index) {
                return BuildOnboardingItem(model: onboardingList[index], index: index,);
              },
              onPageChanged: (index) {
                currentIndex = index;
              },
            ),
          ),
          const SizedBox(
            height: 100,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SmoothPageIndicator(
                  controller: pageController,
                  count: onboardingList.length,
                  effect: const WormEffect(
                    activeDotColor: primaryColor,
                    dotHeight: 12,
                    dotWidth: 25,
                    type: WormType.normal,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                FloatingActionButton(
                  onPressed: () {
                    if (currentIndex != onboardingList.length - 1) {
                      pageController.nextPage(
                           duration: const Duration(milliseconds: 1),
                          curve: Curves.bounceInOut);
                    } else {
                      myNavigator(context, LoginScreen());
                    }
                  },
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child:
                      const Icon(color: Colors.white, Icons.arrow_forward_ios),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
