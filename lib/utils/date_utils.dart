import 'package:cloud_firestore/cloud_firestore.dart';

String formatDate(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$year-$month-$day';
}

String formatTimestamp(Timestamp? timestamp) {
  return formatDate(timestamp?.toDate());
}

int calculateAgeInMonths(DateTime birthDate, {DateTime? today}) {
  final now = today ?? DateTime.now();
  var months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
  if (now.day < birthDate.day) {
    months--;
  }
  return months < 0 ? 0 : months;
}
