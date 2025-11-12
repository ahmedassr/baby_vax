import 'package:baby_vax/app/core/imports/import_library.dart';

import '../../config/constant/app_constant.dart';

class FireStoreHelperService extends GetxService {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  CollectionReference get usersCollection => _fireStore.collection("users");

  Future<void> createUser(
      {required String uid, required dynamic userDate}) async {
    try {
      _logger.i("🆕 Creating user document → uid: $uid");
      await usersCollection.doc(uid).set(userDate);
      _logger.i("✅ User created successfully → $uid");
    } catch (e, s) {
      _handelError("createUser", e, s);
    }
  }

  Future<T?> getUser<T>({
    required String uid,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      _logger.i("📥 Fetching user document → uid: $uid");

      final snapshot = await usersCollection.doc(uid).get();

      if (!snapshot.exists) {
        _logger.w("⚠️ User not found → uid: $uid");
        return null;
      }

      final data = snapshot.data();
      if (data == null || data is! Map<String, dynamic>) {
        _logger.w("⚠️ User document is empty or invalid → uid: $uid");
        return null;
      }
      final result = fromMap(data);
      _logger.i("✅ User fetched successfully → $result");
      return result;

    } catch (e, s) {
      _handelError("getUser", e, s);
      return null;
    }
  }

  Future<List<T>?> fetchData<T>({
    required List<String> path,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    _logger.i("🔍 Fetching data at path: ${path.join('/')}");
    try {
      CollectionReference currentRef = _fireStore.collection(path.first);
     if(path.length > 1){
       for (int i = 1; i < path.length; i += 2) {
         final docId = path[i];
         final nextCollectionName = (i + 1 < path.length) ? path[i + 1] : "";
         if (docId.isEmpty) {
           _logger.e("❌ Invalid path: missing docId at segment $i");
           AppConstant.alertService.showError(message: 'Error occurred');
         } else {
           currentRef = currentRef.doc(docId).collection(nextCollectionName);
         }
       }
     }
      final snapShot = await currentRef.get();
      if (snapShot.docs.isEmpty) {
        _logger.w("⚠️ No documents found at path: ${path.join('/')}");
        return [];
      }
      final data = snapShot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      _logger.i("✅ Fetched ${data.length} items successfully");
      return data;
    } catch (e, s) {
      _handelError("fetchData", e, s);
      return null;
    }
  }

  Future<void> updateUser(
      {required String uid, required dynamic updatedDate}) async {
    try {
      _logger.i("✏️ Updating user document → uid: $uid");
      await usersCollection.doc(uid).update(updatedDate);
      _logger.i("✅ User updated successfully → uid: $uid");
    } catch (e, s) {
      _handelError("updateUser", e, s);
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      _logger.w("🗑️ Deleting user document → uid: $uid");
      await usersCollection.doc(uid).delete();
      _logger.i("✅ User deleted successfully → $uid");
    } catch (e, s) {
      _handelError("deleteUser", e, s);
    }
  }

  Future<void> createDynamicPath<T>(
      {required List<String> path,
      required List<T> data,
      required Map<String, dynamic> Function(T) toMap}) async {
    assert(path.isNotEmpty && path.length.isOdd,
        "❌ Invalid Fire-store path structure. Must end with a collection name.");
    try {
      CollectionReference currentRef = _fireStore.collection(path.first);
      for (int i = 1; i < path.length; i += 2) {
        final docId = path[i];
        final nextCollectionName = (i + 1 < path.length) ? path[i + 1] : "";
        if (docId.isEmpty) {
          DocumentReference newDoc = await currentRef.add({});
          currentRef = newDoc.collection(nextCollectionName);
        } else {
          currentRef = currentRef.doc(docId).collection(nextCollectionName);
        }
      }
      _logger.i("🧩 Creating dynamic collection at path: ${path.join('/')}");
      for (var item in data) {
        await currentRef.add(toMap(item));
        _logger.i('✅ Adding item: $item');
      }
      _logger.i("✅ Successfully created documents under: ${path.join('/')}");
    } catch (e, s) {
      _handelError("createDynamicPath", e, s);
    }
  }

  void _handelError(String operation, Object error, StackTrace s) {
    _logger.e("❌ Fire store Error during $operation → $error",
        error: error, stackTrace: s);
    AppConstant.alertService.showError(message: 'Error occurred');
  }
}
