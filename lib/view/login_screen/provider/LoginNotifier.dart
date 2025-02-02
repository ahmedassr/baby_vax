import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/view/login_screen/LoginScreen.dart';
import 'package:baby_vax/view/login_screen/provider/LoginStates.dart';
import 'package:baby_vax/view/signup_screen/SignupScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginNotifierProvider =
    StateNotifierProvider<LoginNotifier, LoginStates>((ref) {
  return LoginNotifier();
});

enum LoginState { initial, loading, success, error }

class LoginNotifier extends StateNotifier<LoginStates> {
  LoginNotifier() : super(LoginStates());

  void toggleLoginScreen(context, bool inLogin) {
    state = state.copyWith(inLoginScreen: inLogin);
    if (inLogin) {
      myNavigator(context, LoginScreen());
    } else {
      myNavigator(context, SignupScreen());
    }
  }

  bool isVisible = false;

  void togglePasswordIcon() {
    isVisible = !isVisible;
    state = state.copyWith(isVisible: isVisible);
  }

  Future userLogin({required String email, required String password}) async {
    try {
      state = state.copyWith(success: false, isLoading: true, error: null);
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) {
        state = state.copyWith(success: true, isLoading: false, error: null);
      });
    } catch (e) {
      state = state.copyWith(
          success: false,
          isLoading: false,
          error: 'Error when user try to login the Error : $e');
    }
  }
}
