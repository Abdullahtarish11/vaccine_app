import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String centerId;
  final String childId;
  final String parentId;
  final String vaccineId;
  final String status;
  final Timestamp? appointmentDate;
  final Timestamp? createdAt;

  const AppointmentModel({
    required this.id,
    required this.centerId,
    required this.childId,
    required this.parentId,
    required this.vaccineId,
    required this.status,
    required this.appointmentDate,
    required this.createdAt,
  });

  factory AppointmentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentModel(
      id: doc.id,
      centerId: (data['centerId'] ?? '').toString().trim(),
      childId: (data['childId'] ?? '').toString().trim(),
      parentId: (data['parentId'] ?? '').toString().trim(),
      vaccineId: (data['vaccineId'] ?? '').toString().trim(),
      status: (data['status'] ?? 'pending').toString().trim(),
      appointmentDate: data['appointmentDate'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
