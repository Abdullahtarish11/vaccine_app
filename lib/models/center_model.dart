import 'package:cloud_firestore/cloud_firestore.dart';

class CenterModel {
  final String id;
  final String centerName;
  final String location;
  final String phone;
  final String userId;
  final Timestamp? createdAt;

  final String email;
  final String description;
  final String workingHours;

  const CenterModel({
    required this.id,
    required this.centerName,
    required this.location,
    required this.phone,
    required this.userId,
    required this.createdAt,
    this.email = '',
    this.description = '',
    this.workingHours = '',
  });

  factory CenterModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CenterModel(
      id: doc.id,
      centerName: (data['centerName'] ?? '').toString().trim(),
      location: (data['location'] ?? '').toString().trim(),
      phone: (data['phone'] ?? '').toString().trim(),
      userId: (data['userId'] ?? '').toString().trim(),
      createdAt: data['createdAt'] as Timestamp?,
      email: (data['email'] ?? '').toString().trim(),
      description: (data['description'] ?? '').toString().trim(),
      workingHours: (data['workingHours'] ?? '').toString().trim(),
    );
  }
}
