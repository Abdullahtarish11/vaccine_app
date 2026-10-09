import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineModel {
  final String id;
  final String vaccineName;
  final String description;
  final int ageInMonths;
  final Timestamp? createdAt;

  const VaccineModel({
    required this.id,
    required this.vaccineName,
    required this.description,
    required this.ageInMonths,
    required this.createdAt,
  });

  factory VaccineModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VaccineModel(
      id: doc.id,
      vaccineName: (data['vaccineName'] ?? data['name'] ?? '').toString().trim(),
      description: (data['description'] ?? '').toString().trim(),
      ageInMonths: (data['ageInMonths'] ?? 0) is int
          ? (data['ageInMonths'] ?? 0) as int
          : int.tryParse((data['ageInMonths'] ?? '0').toString()) ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vaccineName': vaccineName.trim(),
      'description': description.trim(),
      'ageInMonths': ageInMonths,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
