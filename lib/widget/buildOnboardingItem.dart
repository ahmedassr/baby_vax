import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/shared/style/Colors.dart';
import 'package:baby_vax/view/layout/Home.dart';
import 'package:baby_vax/view/login_screen/LoginScreen.dart';
import 'package:baby_vax/view/onboarding_screen/model/OnboardingModel.dart';
import 'package:flutter/material.dart';

import '../data/local/CashHelper.dart';

class BuildOnboardingItem extends StatelessWidget {
  final OnboardingModel model;
  final int index; // Declare as final since it's immutable

  // Constructor using required fields
  const BuildOnboardingItem(
      {Key? key, required this.model, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Slightly increase padding for better spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        // Center-align content horizontally
        children: [
          const SizedBox(height: 50,),
          Expanded(
            flex: 2,
            child: Center(
              child: Image.asset(
                model.image,
                fit: BoxFit
                    .contain, // Use BoxFit.contain to avoid image distortion
              ),
            ),
          ),
          const SizedBox(
            height: 50, // Reduced space for a cleaner design
          ),
          Expanded(
            flex: 2,
            child: Text(
              model.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          index == 2
              ? defaultButton(
              width: 140,
              background: primaryColor,
              radius: 25,
              onPressed: () {
                myNavigator(context,  LoginScreen());
                CashHelper.putValue(key: 'isNewUser', value: false);
              },
              child: CustomBoldText(
                  title: 'ابدء الان', size: 24, background: Colors.white))
              : const SizedBox()
        ],
      ),
    );
  }
}
