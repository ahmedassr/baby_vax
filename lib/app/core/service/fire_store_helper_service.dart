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

  /// Deletes every document in a collection, in batches.
  ///
  /// Firestore does not delete subcollections when you delete their parent
  /// document, so account deletion has to walk them explicitly or the child's
  /// vaccination records are orphaned and left in the project forever.
  ///
  /// Batched because a write batch is capped at 500 operations, and paged so a
  /// large collection does not have to be held in memory at once.
  Future<int> deleteCollection({
    required String path,
    int batchSize = 300,
  }) async {
    return await _execute(
          operation: "Delete Collection: $path",
          action: () async {
            int deleted = 0;
            while (true) {
              final QuerySnapshot<Map<String, dynamic>> snapshot =
                  await _db.collection(path).limit(batchSize).get();

              if (snapshot.docs.isEmpty) break;

              final WriteBatch batch = _db.batch();
              for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                  in snapshot.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              deleted += snapshot.docs.length;

              // A short page means that was the last one.
              if (snapshot.docs.length < batchSize) break;
            }
            logger.i("Deleted $deleted document(s) from $path");
            return deleted;
          },
        ) ??
        0;
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
