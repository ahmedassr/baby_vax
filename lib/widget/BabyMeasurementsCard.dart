import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/shared/style/Colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/UserModel.dart';

class BabyMeasurItems extends StatelessWidget {
  UserModel? model;

  BabyMeasurItems({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BabyMeasurItemCard(
                type: 'الوزن',
                value: model?.weight.toString() ?? '',
                stableValue: ' الوزن السليم :40',
                color: (model?.weight ?? 0) > 12 ? Colors.green : Colors.red,
              ),
              Spacer(),
              BabyMeasurItemCard(
                type: 'الطول',
                value: model?.height.toString() ?? '',
                color: (model?.height ?? 0) > 12 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              BabyMeasurItemCard(
                type: 'محيط\nالراس',
                value: model?.headCircle.toString() ?? '',
                color:
                    (model?.headCircle ?? 0) > 12 ? Colors.green : Colors.red,
              ),
              Spacer(),
              BabyMeasurItemCard(
                type: 'نسبة الدم',
                value: model?.bloodPercent.toString() ?? '',
                color:
                    (model?.bloodPercent ?? 0) > 12 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BabyMeasurItemCard extends StatelessWidget {
  final String? type;
  final String? value;
  final String? stableValue;
  final Color? color;

  const BabyMeasurItemCard(
      {super.key, this.type, this.value, this.stableValue, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          width: 135,
          height: 160,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: myBlackColor, width: 1)),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: CustomBoldText(
                      title: type ?? '',
                      size: 22,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w800,
                      maxLines: 2,
                      background: myBlackColor),
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: CustomBoldText(
                      title: value ?? '', size: 18, background: myBlackColor),
                ),
                Expanded(
                  child: CustomBoldText(
                      title: stableValue ?? '',
                      size: 14,
                      maxLines: 2,
                      background: myWhiteColor),
                ),
              ],
            ),
          )),
    );
  }
}
