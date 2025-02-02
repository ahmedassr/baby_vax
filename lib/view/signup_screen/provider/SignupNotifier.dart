import 'package:baby_vax/model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'SignupStates.dart';

final signupNotifierProvider =
    StateNotifierProvider<SignupNotifier, SignupStates>((ref) {
  return SignupNotifier();
});

class SignupNotifier extends StateNotifier<SignupStates> {
  SignupNotifier() : super(SignupStates());

  bool isVisible = false;

  void togglePasswordIcon() {
    isVisible = !isVisible;
    state = state.copyWith(isVisible: isVisible);
  }

  bool isNext = false;

  void toggleNextAddPassword() {
    isNext = !isNext;
    state = state.copyWith(isNext: isNext);
  }

  String? selectedDateText;

  void datePicker(context) {
    DateTime today = DateTime.now();
    DateTime selectedDate;
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(today.year - 15, today.month, today.day),
            lastDate: DateTime.now())
        .then((value) {
      if (value != null) {
        selectedDate = value;
        selectedDateText = DateFormat.yMd().format(selectedDate);
        state = state.copyWith(dataIsSelected: true);
      }
    });
  }

  Future userSignup(
      {required String email,
      required String password,
      required String name,
      required String birthDate,
      required int weight,
      required int bloodPercent,
      required int height,
      required int headCircle}) async {
    try {
      state = state.copyWith(isLoading: true);
      FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) {
        createUser(
            email: email,
            name: name,
            uId: value.user?.uid,
            weight: weight,
            headCircle: headCircle,
            bloodPercent: bloodPercent,
            birthDate: birthDate,
            height: height);
        state = state.copyWith(success: true, isLoading: false);
      });
    } on FirebaseException catch (e) {
      state =
          state.copyWith(error: e.toString(), success: false, isLoading: false);
    } catch (e) {
      state =
          state.copyWith(error: e.toString(), success: false, isLoading: false);
    }
  }

  Future createUser(
      {String? email,
      String? uId,
      String? name,
      String? birthDate,
      int? weight,
      int? bloodPercent,
      int? height,
      int? headCircle}) async {
    UserModel userModel = UserModel(
        name: name,
        email: email,
        height: height,
        birthDate: birthDate,
        bloodPercent: bloodPercent,
        headCircle: headCircle,
        weight: weight,
        uId: uId);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .set(userModel.toMap());
    } on FirebaseException catch (e) {
      state.copyWith(error: e.toString(), success: false, isLoading: false);
    } catch (e) {
      state.copyWith(error: e.toString(), success: false, isLoading: false);
    }
  }
}
