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
    return Column(
      children: 
        Row(
          children: [
            BabyMeasurItemCard(
              type: 'الوزن',
              value: model?.weight.toString() ?? '',
              color: (model?.weight ?? 0) > 12 ? Colors.green: Colors.red,
            ),
            BabyMeasurItemCard(
              type: 'الطول',
              value: model?.height.toString() ?? '',
              color: (model?.height ?? 0) > 12 ? Colors.green: Colors.red,

            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            BabyMeasurItemCard(
              type: 'محيط الراس',
              value: model?.headCircle.toString() ?? '',
              color: (model?.headCircle ?? 0) > 12 ? Colors.green: Colors.red,

            ),
            BabyMeasurItemCard(
              type: 'نسبة الدم',
              value: model?.bloodPercent.toString() ?? '',
              color: (model?.bloodPercent ?? 0) > 12 ? Colors.green: Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}

class BabyMeasurItemCard extends StatelessWidget {
  final String? type;
  final String? value;
  final Color? color;

  const BabyMeasurItemCard({super.key, this.type, this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
        child: Column(
      children: [
        CustomBoldText(title: type ?? '', size: 18, background: myBlackColor),
        const SizedBox(
          height: 10,
        ),
        CustomBoldText(title: value ?? '', size: 18, background: myBlackColor),
      ],
    ));
  }
}
