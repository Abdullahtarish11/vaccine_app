import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> requestAppointment({
    required String childId,
    required String parentId,
    required String vaccineId,
    DateTime? appointmentDate,
  }) async {
    await _firestore.collection('appointments').add({
      'centerId': '',
      'childId': childId.trim(),
      'parentId': parentId.trim(),
      'vaccineId': vaccineId.trim(),
      'status': 'pending',
      'appointmentDate': Timestamp.fromDate(appointmentDate ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppointmentModel>> streamAppointmentsForChild(String childId) {
    return _firestore
        .collection('appointments')
        .where('childId', isEqualTo: childId.trim())
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AppointmentModel.fromDocument).toList();
      list.sort((a, b) {
        final ad = a.appointmentDate?.millisecondsSinceEpoch ?? 0;
        final bd = b.appointmentDate?.millisecondsSinceEpoch ?? 0;
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Stream<List<AppointmentModel>> streamAppointmentsForCenter(String centerId) {
    return _firestore
        .collection('appointments')
        .where('centerId', isEqualTo: centerId.trim())
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AppointmentModel.fromDocument).toList();
      list.sort((a, b) {
        final ad = a.appointmentDate?.millisecondsSinceEpoch ?? 0;
        final bd = b.appointmentDate?.millisecondsSinceEpoch ?? 0;
        return ad.compareTo(bd);
      });
      return list;
    });
  }

  Stream<List<AppointmentModel>> streamAllAppointments() {
    return _firestore.collection('appointments').snapshots().map((snap) {
      final list = snap.docs.map(AppointmentModel.fromDocument).toList();
      list.sort((a, b) {
        final ad = a.appointmentDate?.millisecondsSinceEpoch ?? 0;
        final bd = b.appointmentDate?.millisecondsSinceEpoch ?? 0;
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Future<void> updateStatus(String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.trim(),
    });
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }
}
