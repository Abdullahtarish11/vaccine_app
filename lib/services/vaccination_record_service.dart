import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vaccination_record_model.dart';

class VaccinationRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<VaccinationRecordModel>> streamRecordsForChild(String childId) {
    return _firestore
        .collection('vaccination_records')
        .where('childId', isEqualTo: childId.trim())
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(VaccinationRecordModel.fromDocument)
              .toList();
          list.sort((a, b) {
            final ad = a.vaccinationDate?.millisecondsSinceEpoch ?? 0;
            final bd = b.vaccinationDate?.millisecondsSinceEpoch ?? 0;
            return bd.compareTo(ad);
          });
          return list;
        });
  }

  Future<void> requestVaccination({
    required String childId,
    required String parentId,
    required String vaccineId,
    DateTime? requestDate,
  }) async {
    final normalizedChildId = childId.trim();
    final normalizedParentId = parentId.trim();
    final normalizedVaccineId = vaccineId.trim();
    final requestedAt = Timestamp.fromDate(requestDate ?? DateTime.now());

    final existingAppointment = await _firestore
        .collection('appointments')
        .where('childId', isEqualTo: normalizedChildId)
        .where('vaccineId', isEqualTo: normalizedVaccineId)
        .get();
    final hasActiveAppointment = existingAppointment.docs.any((doc) {
      final status = (doc.data()['status'] ?? '').toString().trim();
      return status != 'cancelled';
    });

    final existingRecord = await _firestore
        .collection('vaccination_records')
        .where('childId', isEqualTo: normalizedChildId)
        .where('vaccineId', isEqualTo: normalizedVaccineId)
        .limit(1)
        .get();

    if (hasActiveAppointment && existingRecord.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();

    if (!hasActiveAppointment) {
      final appointmentRef = _firestore.collection('appointments').doc();
      batch.set(appointmentRef, {
        'centerId': '',
        'childId': normalizedChildId,
        'parentId': normalizedParentId,
        'vaccineId': normalizedVaccineId,
        'status': 'pending',
        'appointmentDate': requestedAt,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (existingRecord.docs.isEmpty) {
      final recordRef = _firestore.collection('vaccination_records').doc();
      batch.set(recordRef, {
        'centerId': '',
        'childId': normalizedChildId,
        'parentId': normalizedParentId,
        'vaccineId': normalizedVaccineId,
        'status': 'pending',
        'notes': '',
        'approvedBy': '',
        'vaccinationDate': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> markAsVaccinated({
    required String appointmentId,
    required String centerId,
    required String childId,
    required String parentId,
    required String vaccineId,
    required String notes,
    required String approvedBy,
    DateTime? vaccinationDate,
  }) async {
    final batch = _firestore.batch();
    final appointmentRef = _firestore
        .collection('appointments')
        .doc(appointmentId);
    final existingRecord = await _firestore
        .collection('vaccination_records')
        .where('childId', isEqualTo: childId.trim())
        .where('vaccineId', isEqualTo: vaccineId.trim())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    final recordRef = existingRecord.docs.isNotEmpty
        ? existingRecord.docs.first.reference
        : _firestore.collection('vaccination_records').doc();

    batch.set(recordRef, {
      'centerId': centerId.trim(),
      'childId': childId.trim(),
      'parentId': parentId.trim(),
      'vaccineId': vaccineId.trim(),
      'status': 'completed',
      'notes': notes.trim(),
      'approvedBy': approvedBy.trim(),
      'vaccinationDate': Timestamp.fromDate(vaccinationDate ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.update(appointmentRef, {
      'status': 'completed',
      'centerId': centerId.trim(),
    });

    await batch.commit();
  }

  Future<void> deleteRecord(String recordId) async {
    await _firestore.collection('vaccination_records').doc(recordId).delete();
  }
}
