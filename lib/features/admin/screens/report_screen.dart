import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/app_ui.dart';
import '../../../services/monthly_report_service.dart';
import '../../../services/center_service.dart';
import '../../../models/center_model.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return MultiStreamBuilder(
      firestore: firestore,
      builder: (context, childrenDocs, appointmentsDocs, vaccinesDocs) {
        // Children Stats
        final totalChildren = childrenDocs.length;

        // Appointment Stats
        final pendingAppointments = appointmentsDocs.where((d) {
          final data = d.data() as Map<String, dynamic>?;
          return data?['status'] == 'pending';
        }).length;
        final totalAppointments = appointmentsDocs.length;

        // Vaccine Stats
        final completedDoses = vaccinesDocs.length;

        return AppShell(
          appBar: AppBar(
            title: const Text('لوحة الإحصائيات'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'تصدير PDF',
                onPressed: () => _generatePdf(
                  context,
                  totalChildren,
                  totalAppointments,
                  completedDoses,
                  pendingAppointments,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                tooltip: 'التقرير الشهري',
                onPressed: () => _showMonthPicker(context, isExcel: false),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart_rounded),
                tooltip: 'تصدير Excel',
                onPressed: () => _exportToExcel(
                  context,
                  totalChildren,
                  totalAppointments,
                  completedDoses,
                  pendingAppointments,
                ),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: 'نظرة عامة',
                  subtitle: 'ملخص لأهم الإحصائيات في النظام',
                ),
                const SizedBox(height: 24),

                // Statistics Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _StatCard(
                      title: 'إجمالي الأطفال',
                      value: totalChildren.toString(),
                      icon: Icons.child_care_rounded,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primarySoft,
                    ),
                    _StatCard(
                      title: 'إجمالي المواعيد',
                      value: totalAppointments.toString(),
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.secondary,
                      backgroundColor: AppColors.secondarySoft,
                    ),
                    _StatCard(
                      title: 'الجرعات المكتملة',
                      value: completedDoses.toString(),
                      icon: Icons.vaccines_rounded,
                      color: AppColors.success,
                      backgroundColor: AppColors.successSoft,
                    ),
                    _StatCard(
                      title: 'الطلبات المعلقة',
                      value: pendingAppointments.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                      backgroundColor: AppColors.warningSoft,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const SectionTitle(
                  title: 'تحليل المواعيد',
                  subtitle: 'نسبة المواعيد المكتملة مقارنة بالمعلقة',
                ),
                const SizedBox(height: 16),

                // Single Simple Chart
                if (totalAppointments > 0)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  color: AppColors.success,
                                  value:
                                      (totalAppointments - pendingAppointments)
                                          .toDouble(),
                                  title:
                                      '${totalAppointments - pendingAppointments}',
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  badgeWidget: _Badge(
                                    'مؤكدة',
                                    AppColors.success,
                                  ),
                                  badgePositionPercentageOffset: 1.4,
                                ),
                                PieChartSectionData(
                                  color: AppColors.warning,
                                  value: pendingAppointments.toDouble(),
                                  title: '$pendingAppointments',
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  badgeWidget: _Badge(
                                    'معلقة',
                                    AppColors.warning,
                                  ),
                                  badgePositionPercentageOffset: 1.4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendItem(
                              color: AppColors.success,
                              label: 'مواعيد مؤكدة',
                            ),
                            const SizedBox(width: 24),
                            _LegendItem(
                              color: AppColors.warning,
                              label: 'طلبات معلقة',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  const EmptyStateCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'لا توجد بيانات كافية',
                    subtitle: 'الرسم البياني سيظهر هنا عند إضافة مواعيد',
                  ),

                const SizedBox(height: 32),
                HighlightBanner(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'معلومة',
                  subtitle:
                      'يتم تحديث هذه الإحصائيات بشكل لحظي لتعكس أحدث التغييرات في النظام.',
                  color: AppColors.primary,
                  background: AppColors.surfaceAlt,
                ),

                const SizedBox(height: 32),
                const SectionTitle(
                  title: 'التقارير المتخصصة',
                  subtitle: 'استخراج تقارير تفصيلية للمركز الصحي',
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'التقرير الشهري الشامل',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'تقرير PDF يحتوي على قائمة الأطفال وحالة تطعيماتهم لكل شهر.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showMonthPicker(context, isExcel: false),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: const Text('PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showMonthPicker(context, isExcel: true),
                            icon: const Icon(
                              Icons.table_view_outlined,
                              size: 18,
                            ),
                            label: const Text('Excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    int totalChildren,
    int totalAppointments,
    int completedDoses,
    int pendingAppointments,
  ) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.cairoRegular();
      final boldFont = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'تقرير نظام التطعيمات',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'إحصائيات عامة:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                  cellAlignment: pw.Alignment.centerRight,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue100,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 14),
                  data: <List<String>>[
                    ['البيان', 'العدد'],
                    ['إجمالي الأطفال المسجلين', totalChildren.toString()],
                    ['إجمالي المواعيد المحجوزة', totalAppointments.toString()],
                    ['الجرعات المكتملة', completedDoses.toString()],
                    [
                      'الطلبات بانتظار الاعتماد',
                      pendingAppointments.toString(),
                    ],
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'ملاحظة:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'تم إنشاء هذا التقرير آلياً من نظام إدارة التطعيمات.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'تقرير_التطعيمات_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إعداد التقرير للطباعة: $e')),
      );
    }
  }

  Future<DateTime?> _showCustomMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('اختر شهر التقرير'),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text('شهر ${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedMonth = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      isExpanded: true,
                      items: List.generate(10, (index) {
                        final year = now.year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedYear = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(selectedYear, selectedMonth),
                  ),
                  child: const Text('اختيار'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context, {
    required bool isExcel,
  }) async {
    final DateTime? picked = await _showCustomMonthYearPicker(context);

    if (picked != null) {
      if (!context.mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        String centerName = 'المركز الصحي الرئيسي';

        if (uid != null) {
          final center = await CenterService().fetchCenterForUser(uid);
          if (center != null) {
            centerName = center.centerName;
          }
        }

        if (isExcel) {
          await MonthlyReportService().generateMonthlyExcelReport(
            selectedMonth: picked,
            centerName: centerName,
          );
        } else {
          await MonthlyReportService().generateMonthlyReport(
            selectedMonth: picked,
            centerName: centerName,
          );
        }

        if (context.mounted) Navigator.pop(context); // Close loading
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel(
    BuildContext context,
    int totalChildren,
    int totalAppointments,
    int completedDoses,
    int pendingAppointments,
  ) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // إضافة العناوين
      sheetObject.appendRow([TextCellValue('البيان'), TextCellValue('العدد')]);

      // إضافة البيانات
      sheetObject.appendRow([
        TextCellValue('إجمالي الأطفال المسجلين'),
        IntCellValue(totalChildren),
      ]);
      sheetObject.appendRow([
        TextCellValue('إجمالي المواعيد المحجوزة'),
        IntCellValue(totalAppointments),
      ]);
      sheetObject.appendRow([
        TextCellValue('الجرعات المكتملة'),
        IntCellValue(completedDoses),
      ]);
      sheetObject.appendRow([
        TextCellValue('الطلبات بانتظار الاعتماد'),
        IntCellValue(pendingAppointments),
      ]);

      // حفظ الملف
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final fileName =
            'تقرير_التطعيمات_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final path = "${directory.path}/$fileName";

        final file = File(path);
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(path)],
          text: 'تقرير نظام التطعيمات',
          subject: 'تصدير بيانات التطعيمات',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تصدير ملف Excel: $e')),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SoftIconBadge(
                icon: icon,
                color: color,
                background: backgroundColor,
                size: 26,
              ),
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.textSecondary.withOpacity(0.3),
                size: 24,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// A helper widget to combine multiple streams cleanly
class MultiStreamBuilder extends StatelessWidget {
  final FirebaseFirestore firestore;
  final Widget Function(
    BuildContext context,
    List<QueryDocumentSnapshot> childrenDocs,
    List<QueryDocumentSnapshot> appointmentsDocs,
    List<QueryDocumentSnapshot> vaccinesDocs,
  )
  builder;

  const MultiStreamBuilder({
    super.key,
    required this.firestore,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('children').snapshots(),
      builder: (context, childrenSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('appointments').snapshots(),
          builder: (context, appointmentsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('vaccination_records').snapshots(),
              builder: (context, vaccinesSnapshot) {
                if (childrenSnapshot.hasError ||
                    appointmentsSnapshot.hasError ||
                    vaccinesSnapshot.hasError) {
                  return const Center(child: Text('حدث خطأ في تحميل البيانات'));
                }

                if (!childrenSnapshot.hasData ||
                    !appointmentsSnapshot.hasData ||
                    !vaccinesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return builder(
                  context,
                  childrenSnapshot.data!.docs,
                  appointmentsSnapshot.data!.docs,
                  vaccinesSnapshot.data!.docs,
                );
              },
            );
          },
        );
      },
    );
  }
}
