import 'package:baby_vax/app/core/values/app_enum/path_validation_type.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

class FireStoreHelperService extends GetxService {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String _usersCollectionName = 'users';
  static const String _docIdField = '_id';

  CollectionReference get usersCollection =>
      _fireStore.collection(_usersCollectionName);

  Future<void> createUser(
      {required String uid, required dynamic userDate}) async {
    return _execute(
        operation: "🆕 Create User",
        action: () async {
          _logger.i("🆕 Creating user document → uid: $uid");
          await usersCollection.doc(uid).set(userDate);
          _logger.i("✅ User created successfully → $uid");
        });
  }

  Future<T?> getUser<T>({
    required String uid,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    return _execute(
        operation: "Get User Data",
        action: () async {
          _logger.i("📥 Fetching user document → uid: $uid");

          final snapshot = await usersCollection.doc(uid).get();

          if (!snapshot.exists) {
            _logger.w("⚠️ User not found → uid: $uid");
            return null;
          }

          final map = _snapshotToMap(snapshot);
          if (map.isEmpty) {
            _logger.w("⚠️ User document is empty or invalid → uid: $uid");
            return null;
          }
          final user = fromMap(map);
          _logger.i("✅ User fetched successfully → $user");
          return user;
        });
  }

  Future<List<T>?> fetchData<T>({
    required List<String> path,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    if (!_validatePath(path, PathValidationType.basic)) return null;

    return _execute(
        operation: "🔍 Fetch Data",
        action: () async {
          _logger.i("🔍 Fetching data at path: ${path.join('/')}");

          final ref = _resolvePathRef(path);

          if (ref == null) {
            _logger.e(
                "❌ Could not resolve FireStore reference → ${path.join('/')}");
            return null;
          }

          if (path.length.isOdd && ref is CollectionReference) {
            final snap = await ref.get();
            if (snap.docs.isEmpty) {
              _logger.w("⚠️ No documents found → ${path.join('/')}");
              return [];
            }
            final data =
                snap.docs.map((doc) => fromMap(_docToMap(doc))).toList();
            _logger.i("✅ Fetched ${data.length} items from → ${path.join('/')} successfully");
            return data;
          }
          if (path.length.isEven && ref is DocumentReference) {
            final snap = await ref.get();
            if (!snap.exists) {
              _logger.w("⚠️ No documents found → ${path.join('/')}");
              return [];
            }
            final data = fromMap(_docToMap(snap));
            return [data];
          }

          _logger.e("❌ Path type mismatch → ${path.join('/')}");
          return null;
        });
  }

  Future<void> updateData(
      {required List<String> path, required dynamic date}) async {
    if (!_validatePath(path, PathValidationType.document)) {
      return;
    }
    _execute(
        operation: "Update Data",
        action: () async {
          DocumentReference? docRef = _resolvePathRef(path);
          if (docRef == null) return;
          _logger.i("✏️ Updating document → ${docRef.path}");
          await docRef.update(date);
          _logger.i("✅ Document updated successfully");
        });
  }

  Future<void> updateFcmToken({String? token}) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      _logger.e("❌ Failed to get FCM Token");
      return;
    }
    await AppConstant.fireStoreHelper.updateData(
        path: ["users", SessionManager.uId],
        date: {'fcmToken': token ?? fcmToken});

    _logger
        .i("✅ FCM Token updated successfully: ${fcmToken.substring(0, 20)}...");
  }

  Future<void> deleteUser(String uid) async {
    _execute(
        operation: "Delete User",
        action: () async {
          _logger.w("🗑️ Deleting user document → uid: $uid");
          await usersCollection.doc(uid).delete();
          _logger.i("✅ User deleted successfully → $uid");
        });
  }

  Future<void> createDynamicPath<T>(
      {required List<String> path,
      required List<T> data,
      required Map<String, dynamic> Function(T) toMap}) async {
    if (!_validatePath(path, PathValidationType.collection)) return;

    _execute(
        operation: "Create Dynamic Path",
        action: () async {
          CollectionReference? currentRef = _resolvePathRef(path);

          if (currentRef == null) return;

          _logger
              .i("🧩 Creating dynamic collection at path: ${path.join('/')}");

          for (var item in data) {
            await currentRef.add(toMap(item));
            _logger.i('📌 Adding item: $item');
          }

          _logger.i("✅ All documents created successfully");
        });
  }

  dynamic _resolvePathRef(List<String> path) {
    final isDoc = path.length.isEven;
    final type =
        isDoc ? PathValidationType.document : PathValidationType.collection;
    if (!_validatePath(path, type)) return null;

    dynamic ref = _fireStore.collection(path.first);
    for (int i = 1; i < path.length; i++) {
      if (i.isOdd) {
        ref = ref.doc(path[i]);
      } else {
        ref = ref.collection(path[i]);
      }

    }
    _logger.i("✅ Path resolved successfully");
    return ref;
  }

  Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) return {};
    return {
      ...data,
      "_id": doc.id,
    };
  }

  bool _validatePath(List<String> path, PathValidationType type) {
    if (path.isEmpty) {
      _logger.e("❌ Path validation failed → Path is empty");
      return false;
    }

    for (final segment in path) {
      if (segment.trim().isEmpty) {
        _logger.e("❌ Path validation failed → Path contains empty segment");
        return false;
      }
    }

    switch (type) {
      case PathValidationType.basic:
        return true;
      case PathValidationType.document:
        return path.length.isEven;
      case PathValidationType.collection:
        return path.length.isOdd;
    }
  }

  Map<String, dynamic> _snapshotToMap(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null || raw is! Map<String, dynamic>) return {};
    return {...raw, _docIdField: doc.id};
  }

  Future<T?> _execute<T>(
      {required String operation,
      required Future<T?> Function() action}) async {
    try {
      return await action();
    } catch (e, s) {
      _handelError(operation, e, s);
      return null;
    }
  }

  void _handelError(String operation, Object error, StackTrace s) {
    _logger.e("❌ Fire store Error during $operation → $error",
        error: error, stackTrace: s);
    AppConstant.alertService.showError(message: 'Error occurred');
  }
}
