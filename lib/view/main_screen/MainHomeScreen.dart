import 'package:baby_vax/model/UpcomingVaxModel.dart';
import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/widget/UpcomingVaxCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/style/Colors.dart';

class MainHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CircleAvatar(
                child: Icon(Icons.person),
              ),
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: CustomBoldText(
                    title: 'احمد حسين العصار',
                    size: 24,
                    background: myBlackColor),
              )
            ],
          ),
          const SizedBox(
            height: 70,
          ),
          Card(
            child: SingleChildScrollView(
              child: ListView.separated(
                  itemBuilder: (context, index) {
                    UpcomingVaxModel model = UpcomingVaxModel(
                        name: 'شلل الاطفال', date: '01/02/2025');
                    return UpcomingVaxCard(
                      model: model,
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: 10,
                    );
                  },
                  itemCount: 5),
            ),
          ),
          Column(children: [Row(children: [],)],)
        ],
      )),
    );
  }
}
