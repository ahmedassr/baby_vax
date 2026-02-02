import 'package:baby_vax/app/core/imports/import_manger.dart';

class FireStoreHelperService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(DocumentSnapshot doc) fromDoc,
    Query Function(Query query)? queryBuilder,
  }) async {
    return await _execute(
          operation: "Fetch Collection: $path",
          action: () async {
            Query query = _db.collection(path);

            if (queryBuilder != null) {
              query = queryBuilder(query);
            }

            final snapshot = await query.get();
            return snapshot.docs.map((doc) => fromDoc(doc)).toList();
          },
        ) ??
        [];
  }

  Future<T?> getDocument<T>({
    required String path,
    required T Function(DocumentSnapshot doc) fromDoc,
  }) async {
    return await _execute(
      operation: "Fetch Document: $path",
      action: () async {
        final doc = await _db.doc(path).get();
        if (!doc.exists) {
          logger.w("⚠️ Document not found at $path");
          return null;
        }
        return fromDoc(doc);
      },
    );
  }

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _execute(
      operation: "Set Data: $path",
      action: () => _db.doc(path).set(data, SetOptions(merge: merge)),
    );
  }

  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await _execute(
      operation: "Update Data: $path",
      action: () => _db.doc(path).update(data),
    );
  }

  Future<T?> addDocument<T>({
    required String path,
    required Map<String, dynamic> data,
    required T Function(DocumentSnapshot doc) fromDoc,
  }) async {
    return await _execute(
      operation: "Add Document to: $path",
      action: () async {
        final ref = await _db.collection(path).add(data);
        final snapshot = await ref.get();
        return fromDoc(snapshot);
      },
    );
  }

  Future<void> deleteDocument(String path) async {
    await _execute(
      operation: "Delete Document: $path",
      action: () => _db.doc(path).delete(),
    );
  }

  // --- Internal Helpers ---

  /// The "Workhorse": Handles logging and error boundaries
  Future<T?> _execute<T>({
    required String operation,
    required Future<T?> Function() action,
  }) async {
    try {
      logger.i("🚀 Starting $operation");
      final result = await action();
      logger.i("✅ Success: $operation");
      return result;
    } on FirebaseException catch (e) {
      logger.e("❌ Firebase Error during $operation",
          error: e, stackTrace: StackTrace.current);
      // We do NOT show UI alerts here. Let the Controller handle the error.
      rethrow;
    } catch (e) {
      logger.e("❌ Unexpected Error during $operation", error: e);
      rethrow;
    }
  }
}
