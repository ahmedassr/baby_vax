import 'package:baby_vax/app/core/imports/import_library.dart';

class FireStoreHelperService extends GetxService{
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  CollectionReference get usersCollection => _fireStore.collection("users");

  Future<void> createUser(
      {required String uid, required dynamic userDate}) async {
    await usersCollection.doc(uid).set(userDate);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  Future<void> updateUser(
      {required String uid, required dynamic updatedDate}) async {
    await usersCollection.doc(uid).update(updatedDate);
  }

  Future<void> deleteUser(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  Future<void> createSubCollection<T>({
    required String parentCollection,
    required String subCollection,
    required String uid,
    required List<T> data,
    required Map<String, dynamic> Function(T) toMap,
  }) async {
    try {
      final collectionRef = _fireStore
          .collection(parentCollection)
          .doc(uid)
          .collection(subCollection);
      for (var item in data) {
        collectionRef.add(toMap(item));
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
