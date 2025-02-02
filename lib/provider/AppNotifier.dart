import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'AppStates.dart';

class AppNotifier  extends StateNotifier<AppStates>{
  AppNotifier() : super(AppStates());
}