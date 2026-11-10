import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/firestore_access_guard.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FireStoreHelperService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(DocumentSnapshot doc) fromDoc,
    Query Function(Query query)? queryBuilder,
  }) async {
    return await _execute(
          path: path,
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
      path: path,
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

  // Writes return as soon as Firestore has the change locally (see
  // awaitAck). Offline they report WriteOutcome.pendingSync instead of
  // waiting for a server acknowledgement that may not come for hours.

  Future<WriteOutcome> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) =>
      _write(
        path: path,
        operation: "Set Data: $path",
        ack: () => _db.doc(path).set(data, SetOptions(merge: merge)),
      );

  Future<WriteOutcome> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) =>
      _write(
        path: path,
        operation: "Update Data: $path",
        ack: () => _db.doc(path).update(data),
      );

  /// A new document id in [collectionPath], generated on the device so a
  /// record can be written offline.
  String newDocumentId(String collectionPath) =>
      _db.collection(collectionPath).doc().id;

  /// Writes every entry of [sets] (document path -> data) in one atomic
  /// batch: either all of them are stored or none are.
  Future<WriteOutcome> commitSets(Map<String, Map<String, dynamic>> sets) {
    for (final String path in sets.keys) {
      FirestoreAccessGuard.check(path, SessionManager.signedInUid);
    }
    return _write(
      path: sets.keys.isEmpty ? '' : sets.keys.first,
      operation: "Batch Set: ${sets.length} document(s)",
      ack: () {
        final WriteBatch batch = _db.batch();
        sets.forEach((path, data) => batch.set(_db.doc(path), data));
        return batch.commit();
      },
    );
  }

  Future<void> deleteDocument(String path) async {
    await _execute(
      path: path,
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
          path: path,
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
    required String path,
    required String operation,
    required Future<T?> Function() action,
  }) async {
    // Refuse before sending anything: the rules would deny it anyway, and a
    // read with an empty or stale uid must never reach Firestore.
    try {
      FirestoreAccessGuard.check(path, SessionManager.signedInUid);
    } on NotSignedInException {
      logger.w("Refused $operation: not signed in");
      rethrow;
    }
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

  /// [_execute] for writes: waits for the server only briefly (awaitAck).
  Future<WriteOutcome> _write({
    required String path,
    required String operation,
    required Future<void> Function() ack,
  }) async {
    return await _execute<WriteOutcome>(
          path: path,
          operation: operation,
          action: () => awaitAck(
            ack(),
            onLateError: (e, s) {
              // The UI already said "will sync". A rejection that arrives
              // after reconnecting is recorded, so it is not lost silently.
              logger.e("❌ Late failure of $operation", error: e);
              FirebaseCrashlytics.instance.recordError(e, s,
                  reason: 'Late failure of a queued Firestore write');
            },
          ),
        ) ??
        WriteOutcome.pendingSync;
  }
}
