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
                statusColor: (model?.weight ?? 0) > 12 ? Colors.green : Colors.red,
              ),
              const Spacer(),
              BabyMeasurItemCard(
                type: 'الطول',
                value: model?.height.toString() ?? '',
                statusColor: (model?.height ?? 0) > 12 ? Colors.green : Colors.red,
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
                statusColor:
                    (model?.headCircle ?? 0) > 12 ? Colors.green : Colors.red,
              ),
              Spacer(),
              BabyMeasurItemCard(
                type: 'نسبة\nالدم',
                value: model?.bloodPercent.toString() ?? '',
                statusColor:
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
  final Color? statusColor;

  const BabyMeasurItemCard(
      {super.key, this.type, this.value, this.stableValue, this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: statusColor),
            ),
          ),
          Container(
              width: 135,
              height: 150,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor ?? myBlackColor, width: 1)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 5),
                child: Column(
                  children: [
                    CustomBoldText(
                        title: type ?? '',
                        size: 22,
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.w800,
                        maxLines: 2,
                        background: myBlackColor),
                    const SizedBox(
                      height: 10,
                    ),
                    CustomBoldText(
                        title: value ?? '', size: 18, background: myBlackColor),

                  ],
                ),
              ))
        ],
      ),
    );
  }
}
