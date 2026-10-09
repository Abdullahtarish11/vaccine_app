import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? targetUserId;
  final String senderId;
  final Timestamp createdAt;
  final String type;
  final bool isRead;
  final String? referenceId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.targetUserId,
    required this.senderId,
    required this.createdAt,
    this.type = 'manual',
    this.isRead = false,
    this.referenceId,
  });

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      targetUserId: data['targetUserId'],
      senderId: data['senderId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      type: data['type'] ?? 'manual',
      isRead: data['isRead'] ?? false,
      referenceId: data['referenceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'targetUserId': targetUserId,
      'senderId': senderId,
      'createdAt': createdAt,
      'type': type,
      'isRead': isRead,
      'referenceId': referenceId,
    };
  }
}
