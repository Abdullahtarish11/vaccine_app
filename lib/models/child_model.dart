import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String childName;
  final String birthDate;
  final String gender;
  final String parentId;
  final bool approved;
  final String status; // active, inactive, deceased
  final Timestamp? dateOfDeath;

  final Timestamp? createdAt;

  ChildModel({
    required this.id,
    required this.childName,
    required this.birthDate,
    required this.gender,
    required this.parentId,
    required this.approved,
    this.status = 'active',
    this.dateOfDeath,
    this.createdAt,
  });

  factory ChildModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String getString(String key) {
      final value = data[key];
      if (value == null) return '';
      return value.toString().trim();
    }

    return ChildModel(
      id: doc.id,
      childName: getString('childName'),
      birthDate: getString('birthDate'),
      gender: getString('gender'),
      parentId: getString('parentId'),
      approved: data['approved'] == true,
      status: getString('status').isEmpty ? 'active' : getString('status'),
      dateOfDeath: data['dateOfDeath'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childName': childName.trim(),
      'birthDate': birthDate.trim(),
      'gender': gender.trim(),
      'parentId': parentId.trim(),
      'approved': approved,
      'status': status,
      'dateOfDeath': dateOfDeath,
      'createdAt': createdAt,
    };
  }
}
