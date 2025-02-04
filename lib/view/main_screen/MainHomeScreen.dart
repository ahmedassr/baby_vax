import 'package:baby_vax/model/UpcomingVaxModel.dart';
import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/widget/BabyMeasurementsCard.dart';
import 'package:baby_vax/widget/UpcomingVaxCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/UserModel.dart';
import '../../shared/style/Colors.dart';

class MainHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    UpcomingVaxModel model =
    UpcomingVaxModel(date: DateTime(2005, 12, 1), name: 'شلل الاطفال');
    UserModel userModel = UserModel(
        height: 20, bloodPercent: 12, headCircle: 25, weight: 45);
    return Scaffold(
      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: .19,
                        color: primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CustomBoldText(
                                title: 'احمد حسين العصار',
                                size: 24,
                                background: myBlackColor),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        const CircleAvatar(
                          radius: 25,
                          child: Icon(
                            Icons.person,
                            size: 27,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 70,
                ),
                Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomBoldText(
                                  title: ': التطعيمات القادمة ',
                                  fontWeight: FontWeight.w900,
                                  size: 24,
                                  background: primaryColor)),
                        ),
                        UpcomingVaxCard(
                          model: model,
                        ),
                      ],
                    )),
                BabyMeasurItems(model:userModel,)
              ],
            ),
          )),
    );
  }
}
