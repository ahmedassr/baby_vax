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
    String date = DateFormat.yMd().format(model?.date ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: .5,
              color: primaryColor,
            ),
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(
            children: [
              CustomBoldText(
                  title: model?.name ?? '', size: 24, background: myBlackColor),
              const SizedBox(
                height: 10,
              ),
              CustomBoldText(
                  title: '${date} : تاريخ المستحق ',
                  size: 20,
                  background: Colors.grey)
            ],
          ),
        ),
      ),
    );
  }
}
