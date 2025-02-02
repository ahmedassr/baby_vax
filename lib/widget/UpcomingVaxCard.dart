import 'package:baby_vax/model/UpcomingVaxModel.dart';
import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/shared/style/Colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingVaxCard extends StatelessWidget {
  UpcomingVaxModel? model;

  UpcomingVaxCard({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    String date = DateFormat.yMd().format(model?.date as DateTime);
    return Card(
      child: Column(
        children: [
          CustomBoldText(
              title: model?.name ?? '', size: 24, background: myBlackColor),
          const SizedBox(
            height: 10,
          ),
          CustomBoldText(
              title: '${date} : تاريخ المستحق ', size: 20, background: Colors.grey)
        ],
      ),
    );
  }
}
