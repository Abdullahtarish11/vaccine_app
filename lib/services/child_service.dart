import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

class ChildService {
  final FirebaseFirestore _firestore;
  static const _collection = 'children';

  ChildService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addChild({
    required String parentId,
    required String childName,
    required String birthDate, // ISO string
    required String gender,
  }) async {
    final doc = {
      'parentId': parentId.trim(),
      'childName': childName.trim(),
      'birthDate': birthDate,
      'gender': gender.trim(),
      'approved': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection(_collection).add(doc);
  }

  Stream<List<ChildModel>> childrenForParent(String parentId) {
    final uid = parentId.trim();
    return _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ChildModel.fromDocument(d)).toList(),
        );
  }

  Future<List<ChildModel>> fetchChildrenForParent(String parentId) async {
    final uid = parentId.trim();
    final snap = await _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: uid)
        .get();
    return snap.docs.map((d) => ChildModel.fromDocument(d)).toList();
  }

  Future<void> setApproved(String childId, bool approved) async {
    await _firestore.collection(_collection).doc(childId).update({
      'approved': approved,
    });
  }

  Future<void> updateChild({
    required String childId,
    required String childName,
    required String birthDate,
    required String gender,
    required bool approved,
  }) async {
    await _firestore.collection(_collection).doc(childId).update({
      'childName': childName.trim(),
      'birthDate': birthDate.trim(),
      'gender': gender.trim(),
      'approved': approved,
    });
  }

  Future<void> markAsDeceased(String childId) async {
    await _firestore.collection(_collection).doc(childId).update({
      'status': 'deceased',
      'dateOfDeath': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChildCascade(String childId) async {
    final batch = _firestore.batch();
    final childRef = _firestore.collection(_collection).doc(childId);

    final appointments = await _firestore
        .collection('appointments')
        .where('childId', isEqualTo: childId.trim())
        .get();
    for (final doc in appointments.docs) {
      batch.delete(doc.reference);
    }

    final records = await _firestore
        .collection('vaccination_records')
        .where('childId', isEqualTo: childId.trim())
        .get();
    for (final doc in records.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(childRef);
    await batch.commit();
  }

  /// For admin/center usage: returns all children belonging to a specific
  /// user by uid (stored as parentId). This proxies to the parent query.
  Future<List<ChildModel>> fetchChildrenForUser(String userUid) {
    return fetchChildrenForParent(userUid.trim());
  }

  /// stream version for admin UI
  Stream<List<ChildModel>> childrenForUserStream(String userUid) {
    return childrenForParent(userUid.trim());
  }

  Stream<List<ChildModel>> allChildrenStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ChildModel.fromDocument(d)).toList(),
        );
  }

  /// One-time helper: trims whitespace from stored `parentId` fields across
  /// all documents in the `children` collection. Returns number of updated docs.
  Future<int> trimAllParentIds() async {
    final snap = await _firestore.collection(_collection).get();
    var updated = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final raw = data['parentId'];
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed != raw) {
          await doc.reference.update({'parentId': trimmed});
          updated++;
        }
      }
    }
    return updated;
  }
}
