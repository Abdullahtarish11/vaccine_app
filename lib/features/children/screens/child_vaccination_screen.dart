import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/appointment_model.dart';
import '../../../models/child_model.dart';
import '../../../models/vaccination_record_model.dart';
import '../../../models/vaccine_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/child_service.dart';
import '../../../services/vaccination_record_service.dart';
import '../../../services/vaccine_service.dart';
import '../../../utils/app_ui.dart';
import '../../../utils/date_utils.dart';

class ChildVaccinationScreen extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const ChildVaccinationScreen({
    super.key,
    required this.child,
    required this.parentId,
  });

  @override
  State<ChildVaccinationScreen> createState() => _ChildVaccinationScreenState();
}

class _ChildVaccinationScreenState extends State<ChildVaccinationScreen> {
  final _appointmentService = AppointmentService();
  final _recordService = VaccinationRecordService();
  final _childService = ChildService();
  bool _isRequesting = false;
  bool _isMarkingDeceased = false;

  Future<void> _requestVaccine(VaccineModel vaccine) async {
    setState(() => _isRequesting = true);
    try {
      await _recordService.requestVaccination(
        childId: widget.child.id,
        parentId: widget.parentId,
        vaccineId: vaccine.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة الجرعة إلى سجل الطفل وبانتظار اعتماد المركز',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ الجرعة في سجل الطفل: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _reportDeath() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إبلاغ عن وفاة'),
        content: const Text('هل أنت متأكد من تسجيل حالة الوفاة؟ لا يمكن التراجع عن هذا الإجراء وسيتم إيقاف كافة العمليات المرتبطة بالطفل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد الوفاة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isMarkingDeceased = true);
    try {
      await _childService.markAsDeceased(widget.child.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل حالة الوفاة وتحديث السجل.')),
      );
      Navigator.pop(context); // العودة للرئيسية لتحديث البيانات
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التحديث: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMarkingDeceased = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'تم أخذ الجرعة';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'بانتظار الاعتماد';
    }
  }

  ({Color color, Color bg, IconData icon}) _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return (
          color: AppColors.success,
          bg: AppColors.successSoft,
          icon: Icons.check_circle_outline,
        );
      case 'cancelled':
        return (
          color: AppColors.danger,
          bg: AppColors.dangerSoft,
          icon: Icons.cancel_outlined,
        );
      default:
        return (
          color: AppColors.warning,
          bg: AppColors.warningSoft,
          icon: Icons.schedule_outlined,
        );
    }
  }

  Widget _buildAvailableVaccines(
    List<VaccineModel> vaccines,
    Map<String, String> vaccineStatuses,
    ChildModel currentChild,
  ) {
    final birthDate = DateTime.tryParse(currentChild.birthDate);
    final ageInMonths = birthDate == null ? 0 : calculateAgeInMonths(birthDate);
    final available = vaccines
        .where((vaccine) => vaccine.ageInMonths <= ageInMonths)
        .toList();

    if (available.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.vaccines_outlined,
        title: 'لا توجد تطعيمات مناسبة حالياً',
        subtitle:
            'ستظهر هنا أي جرعة تناسب عمر الطفل عند إضافتها في السجل العام داخل Firebase.',
      );
    }

    return Column(
      children: available.map((vaccine) {
        final accent = ageAccent(vaccine.ageInMonths);
        final status = vaccineStatuses[vaccine.id];
        final alreadyRequested = status != null;
        final completed = status == 'completed';
        final style = _statusStyle(status ?? 'pending');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SoftIconBadge(
                      icon: completed
                          ? Icons.check_circle_outline
                          : Icons.vaccines_outlined,
                      color: completed ? AppColors.success : accent,
                      background: completed
                          ? AppColors.successSoft
                          : accent.withOpacity(0.12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaccine.vaccineName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'العمر المناسب: ${vaccine.ageInMonths} شهر',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (alreadyRequested)
                      StatusChip(
                        label: _statusLabel(status),
                        color: style.color,
                        background: style.bg,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  vaccine.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: currentChild.status == 'deceased' || alreadyRequested || _isRequesting
                      ? null
                      : () => _requestVaccine(vaccine),
                  icon: Icon(
                    completed
                        ? Icons.check_circle_outline
                        : alreadyRequested
                        ? Icons.schedule_outlined
                        : Icons.add_circle_outline,
                  ),
                  label: Text(
                    completed
                        ? 'تم أخذ الجرعة'
                        : alreadyRequested
                        ? 'بانتظار اعتماد المركز'
                        : 'إضافة إلى سجل الطفل',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistory(
    List<AppointmentModel> appointments,
    List<VaccinationRecordModel> records,
    List<VaccineModel> vaccines,
  ) {
    if (appointments.isEmpty && records.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.history_toggle_off_outlined,
        title: 'لا يوجد سجل تطعيمات بعد',
        subtitle:
            'بعد اختيار الجرعات ستظهر هنا الطلبات الحالية وحالة كل جرعة في سجل الطفل.',
      );
    }

    final vaccineNames = {
      for (final vaccine in vaccines) vaccine.id: vaccine.vaccineName,
    };
    final appointmentsByVaccine = {
      for (final appointment in appointments)
        appointment.vaccineId: appointment,
    };
    final recordsByVaccine = {
      for (final record in records) record.vaccineId: record,
    };

    final vaccineIds =
        <String>{
          ...appointmentsByVaccine.keys,
          ...recordsByVaccine.keys,
        }.toList()..sort((a, b) {
          final appointmentA = appointmentsByVaccine[a];
          final appointmentB = appointmentsByVaccine[b];
          final recordA = recordsByVaccine[a];
          final recordB = recordsByVaccine[b];
          final timeA =
              recordA?.vaccinationDate?.millisecondsSinceEpoch ??
              appointmentA?.appointmentDate?.millisecondsSinceEpoch ??
              0;
          final timeB =
              recordB?.vaccinationDate?.millisecondsSinceEpoch ??
              appointmentB?.appointmentDate?.millisecondsSinceEpoch ??
              0;
          return timeB.compareTo(timeA);
        });

    return Column(
      children: vaccineIds.map((vaccineId) {
        final appointment = appointmentsByVaccine[vaccineId];
        final record = recordsByVaccine[vaccineId];
        final rawStatus = record?.status.isNotEmpty == true
            ? record!.status
            : (appointment?.status ?? 'pending');
        final label = _statusLabel(rawStatus);
        final style = _statusStyle(rawStatus);
        final completed = rawStatus == 'completed';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SoftIconBadge(
                      icon: style.icon,
                      color: style.color,
                      background: style.bg,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vaccineNames[vaccineId] ?? vaccineId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: label,
                      color: style.color,
                      background: style.bg,
                    ),
                  ],
                ),
                if (appointment != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'تاريخ الطلب: ${formatTimestamp(appointment.appointmentDate)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (record != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    completed
                        ? 'تم أخذ الجرعة بتاريخ: ${formatTimestamp(record.vaccinationDate)}'
                        : 'الجرعة محفوظة في السجل وبانتظار اعتماد المركز الصحي.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظات: ${record.notes}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('children').doc(widget.child.id).snapshots(),
      builder: (context, childSnap) {
        if (childSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final childData = childSnap.data;
        if (childData == null || !childData.exists) {
          return const Scaffold(body: Center(child: Text('لم يتم العثور على بيانات الطفل')));
        }
        
        final currentChild = ChildModel.fromDocument(childData);
        final birthDate = DateTime.tryParse(currentChild.birthDate);
        final ageInMonths = birthDate == null ? 0 : calculateAgeInMonths(birthDate);

        return AppShell(
          appBar: AppBar(title: Text('تطعيمات ${currentChild.childName}')),
          child: StreamBuilder<List<VaccineModel>>(
            stream: VaccineService().streamVaccines(),
            builder: (context, vaccineSnapshot) {
              final vaccines = vaccineSnapshot.data ?? [];
              return StreamBuilder<List<AppointmentModel>>(
                stream: _appointmentService.streamAppointmentsForChild(currentChild.id),
                builder: (context, appointmentSnapshot) {
                  final appointments = appointmentSnapshot.data ?? [];
                  return StreamBuilder<List<VaccinationRecordModel>>(
                    stream: _recordService.streamRecordsForChild(currentChild.id),
                    builder: (context, recordSnapshot) {
                      final records = recordSnapshot.data ?? [];
                      final waiting =
                          vaccineSnapshot.connectionState == ConnectionState.waiting ||
                          appointmentSnapshot.connectionState == ConnectionState.waiting ||
                          recordSnapshot.connectionState == ConnectionState.waiting;

                      if (waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final vaccineStatuses = <String, String>{
                        for (final item in appointments) item.vaccineId: item.status,
                        for (final item in records) item.vaccineId: item.status,
                      };

                      return SingleChildScrollView(
                        padding: AppThemeTokens.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCard(
                              color: AppColors.surfaceAlt,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SoftIconBadge(
                                        icon: currentChild.gender == 'male'
                                            ? Icons.boy_outlined
                                            : Icons.girl_outlined,
                                        color: AppColors.primary,
                                        background: AppColors.primarySoft,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentChild.childName,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 20,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'تاريخ الميلاد: ${currentChild.birthDate}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (currentChild.status == 'deceased')
                                        StatusChip(
                                          label: 'متوفى',
                                          color: AppColors.danger,
                                          background: AppColors.dangerSoft,
                                        )
                                      else
                                        StatusChip(
                                          label: currentChild.approved ? 'ملف معتمد' : 'بانتظار المراجعة',
                                          color: currentChild.approved ? AppColors.success : AppColors.warning,
                                          background: currentChild.approved ? AppColors.successSoft : AppColors.warningSoft,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      InfoBadge(
                                        label: 'العمر الحالي: $ageInMonths شهر',
                                        icon: Icons.timeline_outlined,
                                        color: AppColors.primary,
                                        background: AppColors.primarySoft,
                                      ),
                                      InfoBadge(
                                        label: 'الطلبات: ${appointments.length} | السجل: ${records.length}',
                                        icon: Icons.fact_check_outlined,
                                        color: AppColors.purple,
                                        background: AppColors.purpleSoft,
                                      ),
                                      if (currentChild.status != 'deceased')
                                        ActionChip(
                                          avatar: _isMarkingDeceased
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(Icons.heart_broken_outlined,
                                                  size: 14, color: AppColors.danger),
                                          label: const Text('إبلاغ عن وفاة',
                                              style: TextStyle(
                                                  color: AppColors.danger,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700)),
                                          backgroundColor: AppColors.dangerSoft,
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                          onPressed: _isMarkingDeceased ? null : _reportDeath,
                                        ),
                                    ],
                                  ),
                                  if (currentChild.status == 'deceased') ...[
                                    const SizedBox(height: 14),
                                    const HighlightBanner(
                                      icon: Icons.info_outline,
                                      title: 'تنبيه',
                                      subtitle: 'هذا الطفل متوفى، لا يمكن إجراء عمليات جديدة.',
                                      color: AppColors.danger,
                                      background: AppColors.dangerSoft,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            AppThemeTokens.sectionGap,
                            const HighlightBanner(
                              icon: Icons.medical_services_outlined,
                              title: 'الجرعات المتاحة',
                              subtitle:
                                  'هذه القائمة تُبنى من بيانات التطعيمات المخزنة في Firebase حسب عمر الطفل، وتُظهر علامة صح عند اعتماد الجرعة من المركز.',
                              color: AppColors.primary,
                              background: AppColors.surfaceAlt,
                            ),
                            const SizedBox(height: 12),
                            _buildAvailableVaccines(vaccines, vaccineStatuses, currentChild),
                            AppThemeTokens.sectionGap,
                            const SectionTitle(
                              title: 'سجل الطفل',
                              subtitle: 'يعرض هنا سجل الطلبات والجرعات التي تم اعتمادها أو ما زالت بانتظار الموافقة.',
                            ),
                            const SizedBox(height: 12),
                            _buildHistory(appointments, records, vaccines),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
