import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationRecordModel {
  final String id;
  final String centerId;
  final String childId;
  final String parentId;
  final String vaccineId;
  final String status;
  final String notes;
  final String approvedBy;
  final Timestamp? vaccinationDate;

  const VaccinationRecordModel({
    required this.id,
    required this.centerId,
    required this.childId,
    required this.parentId,
    required this.vaccineId,
    required this.status,
    required this.notes,
    required this.approvedBy,
    required this.vaccinationDate,
  });

  factory VaccinationRecordModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VaccinationRecordModel(
      id: doc.id,
      centerId: (data['centerId'] ?? '').toString().trim(),
      childId: (data['childId'] ?? '').toString().trim(),
      parentId: (data['parentId'] ?? '').toString().trim(),
      vaccineId: (data['vaccineId'] ?? '').toString().trim(),
      status: (data['status'] ?? 'pending').toString().trim(),
      notes: (data['notes'] ?? '').toString().trim(),
      approvedBy: (data['approvedBy'] ?? '').toString().trim(),
      vaccinationDate: data['vaccinationDate'] as Timestamp?,
    );
  }
}
