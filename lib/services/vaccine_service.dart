import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vaccine_model.dart';

class VaccineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<VaccineModel>> streamVaccines() {
    return _firestore.collection('vaccines').snapshots().map((snap) {
      final vaccines = snap.docs.map(VaccineModel.fromDocument).toList();
      vaccines.sort((a, b) {
        final ageCompare = a.ageInMonths.compareTo(b.ageInMonths);
        if (ageCompare != 0) return ageCompare;
        final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aCreated.compareTo(bCreated);
      });
      return vaccines;
    });
  }

  Future<void> createVaccine({
    required String name,
    required String description,
    required int ageInMonths,
  }) async {
    await _firestore.collection('vaccines').add({
      'vaccineName': name.trim(),
      'description': description.trim(),
      'ageInMonths': ageInMonths,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVaccine({
    required String vaccineId,
    required String name,
    required String description,
    required int ageInMonths,
  }) async {
    await _firestore.collection('vaccines').doc(vaccineId).update({
      'vaccineName': name.trim(),
      'description': description.trim(),
      'ageInMonths': ageInMonths,
    });
  }

  Future<void> deleteVaccine(String vaccineId) async {
    await _firestore.collection('vaccines').doc(vaccineId).delete();
  }
}
