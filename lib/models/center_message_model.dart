import 'package:cloud_firestore/cloud_firestore.dart';

class CenterMessageModel {
  final String id;
  final String parentId;
  final String parentName;
  final String centerId;
  final String subject;
  final String message;
  final String? reply;
  final Timestamp createdAt;
  final Timestamp? repliedAt;
  final bool isReadByCenter;
  final bool isReplied;

  CenterMessageModel({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.centerId,
    required this.subject,
    required this.message,
    this.reply,
    required this.createdAt,
    this.repliedAt,
    this.isReadByCenter = false,
    this.isReplied = false,
  });

  factory CenterMessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CenterMessageModel(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      parentName: data['parentName'] ?? '',
      centerId: data['centerId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      reply: data['reply'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      repliedAt: data['repliedAt'],
      isReadByCenter: data['isReadByCenter'] ?? false,
      isReplied: data['isReplied'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'centerId': centerId,
      'subject': subject,
      'message': message,
      'reply': reply,
      'createdAt': createdAt,
      'repliedAt': repliedAt,
      'isReadByCenter': isReadByCenter,
      'isReplied': isReplied,
    };
  }
}
