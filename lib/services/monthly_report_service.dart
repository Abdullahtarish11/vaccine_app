import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/child_model.dart';
import '../models/vaccination_record_model.dart';
import '../models/vaccine_model.dart';

class MonthlyReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateMonthlyReport({
    required DateTime selectedMonth,
    required String centerName,
  }) async {
    // 1. Calculate date range for the selected month
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    // 2. Fetch children created in this month
    final childrenSnap = await _firestore
        .collection('children')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final children = childrenSnap.docs
        .map((d) => ChildModel.fromDocument(d))
        .toList();

    if (children.isEmpty) {
      throw Exception('لا يوجد أطفال مسجلين في هذا الشهر');
    }

    // 3. Fetch vaccines to create table columns
    final vaccinesSnap = await _firestore.collection('vaccines').get();
    final vaccines = vaccinesSnap.docs
        .map((d) => VaccineModel.fromDocument(d))
        .toList();
    vaccines.sort((a, b) => a.ageInMonths.compareTo(b.ageInMonths));

    // 4. Fetch parent names
    final parentIds = children.map((c) => c.parentId).toSet().toList();
    final Map<String, String> parentNames = {};

    // Fetch users in chunks if necessary, but here we assume a reasonable number
    for (var i = 0; i < parentIds.length; i += 10) {
      final chunk = parentIds.sublist(
        i,
        i + 10 > parentIds.length ? parentIds.length : i + 10,
      );
      final parentsSnap = await _firestore
          .collection('users')
          .where('uid', whereIn: chunk)
          .get();
      for (var doc in parentsSnap.docs) {
        parentNames[doc.id] = doc.data()['fullName'] ?? 'غير معروف';
      }
    }

    // 5. Fetch vaccination records for these children
    final Map<String, List<VaccinationRecordModel>> childRecords = {};
    for (var child in children) {
      final recordsSnap = await _firestore
          .collection('vaccination_records')
          .where('childId', isEqualTo: child.id)
          .get();
      childRecords[child.id] = recordsSnap.docs
          .map((d) => VaccinationRecordModel.fromDocument(d))
          .toList();
    }

    // 6. Generate PDF
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final headers = [
      'اسم الطفل',
      'تاريخ الميلاد',
      'ولي الأمر',
      ...vaccines.map((v) => v.vaccineName),
    ];

    final data = children.map((child) {
      final List<String> row = [
        child.childName,
        child.birthDate,
        parentNames[child.parentId] ?? 'غير معروف',
      ];

      for (var vaccine in vaccines) {
        final record = childRecords[child.id]?.firstWhere(
          (r) => r.vaccineId == vaccine.id,
          orElse: () => VaccinationRecordModel(
            id: '',
            centerId: '',
            childId: '',
            parentId: '',
            vaccineId: '',
            status: 'none',
            notes: '',
            approvedBy: '',
            vaccinationDate: null,
          ),
        );

        if (record == null || record.status == 'none') {
          row.add('لم يتم التطعيم');
        } else if (record.status == 'pending') {
          row.add('قيد المراجعة');
        } else if (record.status == 'approved' ||
            record.status == 'completed') {
          final dateStr = record.vaccinationDate != null
              ? '\n(${record.vaccinationDate!.toDate().toString().split(' ')[0]})'
              : '';
          row.add('✔️$dateStr');
        } else {
          row.add('لم يتم التطعيم');
        }
      }
      return row;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for more columns
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'المركز الصحي: $centerName',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'الشهر: ${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'تاريخ الإنشاء: ${DateTime.now().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'عدد الأطفال: ${children.length}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'التقرير الشهري لتطعيمات الأطفال',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.5),
              for (var i = 0; i < vaccines.length; i++)
                i + 3: const pw.FlexColumnWidth(1),
            },
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Monthly_Report_${selectedMonth.year}_${selectedMonth.month}.pdf',
    );
  }

  Future<void> generateMonthlyExcelReport({
    required DateTime selectedMonth,
    required String centerName,
  }) async {
    // 1. Fetch data (Reusing logic similar to PDF)
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    final childrenSnap = await _firestore
        .collection('children')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final children = childrenSnap.docs
        .map((d) => ChildModel.fromDocument(d))
        .toList();
    if (children.isEmpty) throw Exception('لا يوجد أطفال مسجلين في هذا الشهر');

    final vaccinesSnap = await _firestore.collection('vaccines').get();
    final vaccines = vaccinesSnap.docs
        .map((d) => VaccineModel.fromDocument(d))
        .toList();
    vaccines.sort((a, b) => a.ageInMonths.compareTo(b.ageInMonths));

    final parentIds = children.map((c) => c.parentId).toSet().toList();
    final Map<String, String> parentNames = {};
    for (var i = 0; i < parentIds.length; i += 10) {
      final chunk = parentIds.sublist(
        i,
        i + 10 > parentIds.length ? parentIds.length : i + 10,
      );
      final parentsSnap = await _firestore
          .collection('users')
          .where('uid', whereIn: chunk)
          .get();
      for (var doc in parentsSnap.docs)
        parentNames[doc.id] = doc.data()['fullName'] ?? 'غير معروف';
    }

    final Map<String, List<VaccinationRecordModel>> childRecords = {};
    for (var child in children) {
      final recordsSnap = await _firestore
          .collection('vaccination_records')
          .where('childId', isEqualTo: child.id)
          .get();
      childRecords[child.id] = recordsSnap.docs
          .map((d) => VaccinationRecordModel.fromDocument(d))
          .toList();
    }

    // 2. Create Excel
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    excel.delete('Sheet1'); // Avoid duplication if needed
    sheetObject = excel['التقرير الشهري'];

    // Headers
    List<CellValue> headers = [
      TextCellValue('اسم الطفل'),
      TextCellValue('تاريخ الميلاد'),
      TextCellValue('ولي الأمر'),
      ...vaccines.map((v) => TextCellValue(v.vaccineName)),
    ];
    sheetObject.appendRow(headers);

    // Data rows
    for (var child in children) {
      List<CellValue> row = [
        TextCellValue(child.childName),
        TextCellValue(child.birthDate),
        TextCellValue(parentNames[child.parentId] ?? 'غير معروف'),
      ];

      for (var vaccine in vaccines) {
        final record = childRecords[child.id]?.firstWhere(
          (r) => r.vaccineId == vaccine.id,
          orElse: () => const VaccinationRecordModel(
            id: '',
            centerId: '',
            childId: '',
            parentId: '',
            vaccineId: '',
            status: 'none',
            notes: '',
            approvedBy: '',
            vaccinationDate: null,
          ),
        );

        String statusText = 'لم يتم';
        if (record?.status == 'approved' || record?.status == 'completed') {
          statusText = 'نعم';
          if (record?.vaccinationDate != null) {
            statusText +=
                ' (${record!.vaccinationDate!.toDate().toString().split(' ')[0]})';
          }
        } else if (record?.status == 'pending') {
          statusText = 'قيد المراجعة';
        }
        row.add(TextCellValue(statusText));
      }
      sheetObject.appendRow(row);
    }

    // 3. Save and Share
    final fileName =
        'Monthly_Report_${selectedMonth.year}_${selectedMonth.month}.xlsx';
    final bytes = excel.encode();

    if (bytes == null) throw Exception('تعذر توليد ملف الإكسيل');
    final uint8list = Uint8List.fromList(bytes);

    if (kIsWeb) {
      // On Web, Printing can also handle byte downloads
      await Printing.sharePdf(bytes: uint8list, filename: fileName);
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(uint8list);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'التقرير الشهري لمركز $centerName');
    }
  }
}
