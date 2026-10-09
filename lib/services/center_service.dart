import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/center_model.dart';
import '../models/center_message_model.dart';

class CenterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CenterModel>> streamCenters() {
    return _firestore
        .collection('centers')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CenterModel.fromDocument).toList());
  }

  Future<CenterModel?> fetchCenterForUser(String userId) async {
    final trimmed = userId.trim();
    final exact = await _firestore
        .collection('centers')
        .where('userId', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (exact.docs.isNotEmpty) {
      return CenterModel.fromDocument(exact.docs.first);
    }

    final all = await _firestore.collection('centers').get();
    for (final doc in all.docs) {
      final model = CenterModel.fromDocument(doc);
      if (model.userId
          .split(',')
          .map((part) => part.trim())
          .contains(trimmed)) {
        return model;
      }
    }
    return null;
  }

  Future<void> sendMessage({
    required String parentId,
    required String parentName,
    required String centerId,
    required String subject,
    required String message,
  }) async {
    final docRef = await _firestore.collection('center_messages').add({
      'parentId': parentId,
      'parentName': parentName,
      'centerId': centerId,
      'subject': subject,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isReadByCenter': false,
      'isReplied': false,
    });

    try {
      final centerSnap = await _firestore.collection('centers').doc(centerId).get();
      if (centerSnap.exists) {
        final centerData = centerSnap.data() as Map<String, dynamic>?;
        if (centerData != null) {
          final centerUserId = (centerData['userId'] ?? '').toString().trim();
          final uids = centerUserId.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
          
          for (final uid in uids) {
            await _firestore.collection('notifications').add({
              'title': 'رسالة جديدة',
              'body': 'لديك رسالة جديدة من ولي الأمر',
              'centerId': centerId,
              'targetUserId': uid,
              'senderId': parentId,
              'createdAt': FieldValue.serverTimestamp(),
              'type': 'message',
              'isRead': false,
              'referenceId': docRef.id,
            });
          }
        }
      }
    } catch (_) {
      // Ignore background notification error
    }
  }

  Stream<List<CenterMessageModel>> userMessagesStream(String userId) {
    return _firestore
        .collection('center_messages')
        .where('parentId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(CenterMessageModel.fromDocument).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<CenterMessageModel>> centerMessagesStream(String centerId) {
    return _firestore
        .collection('center_messages')
        .where('centerId', isEqualTo: centerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(CenterMessageModel.fromDocument).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> replyToMessage(String messageId, String replyText) async {
    await _firestore.collection('center_messages').doc(messageId).update({
      'reply': replyText,
      'isReplied': true,
      'repliedAt': FieldValue.serverTimestamp(),
      'isReadByCenter': true,
    });
  }
}
