import 'dart:developer' as devtools;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotebook/constants/string_constants.dart';
import 'package:mynotebook/services/crud/note_service_exceptions.dart';
import 'dart:async';

class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService _instance = CloudSyncService._();
  factory CloudSyncService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///Returns the collection that represents the set of notes for the user with given uid
  CollectionReference<Map<String, dynamic>> _userNotes(String uid) {
    return _firestore
        .collection(StringConstants.collectionName)
        .doc(uid)
        .collection(StringConstants.subCollectionName);
  }

  /// Pushes (creates or overwrites) a single note document in Firestore.
  ///
  /// Throws [CloudSyncException] if remote push failed
  Future<void> pushNote({
    required String uid,
    required String firestoreNoteId,
    required String title,
    required String content,
  }) async {
    try {
      await _userNotes(uid).doc(firestoreNoteId).set({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      devtools.log("Firestore push failed:", error: e, stackTrace: st);
      throw CloudSyncException("Failed to push note to cloud");
    }
  }

  /// Deletes a single note document from Firestore.
  ///
  /// Throws [CloudSyncException] if remote delete fails
  Future<void> deleteNote(
      {required String uid, required String firestoreNoteId}) async {
    try {
      await _userNotes(uid).doc(firestoreNoteId).delete();
    } on FirebaseException catch (e, st) {
      devtools.log("Firestore delete failed:", error: e, stackTrace: st);
      throw CloudSyncException("Failed to delete note in cloud");
    }
  }

  /// Streams real-time changes to a user's notes subcollection.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotes(String uid) {
    return _userNotes(uid).snapshots();
  }
}
