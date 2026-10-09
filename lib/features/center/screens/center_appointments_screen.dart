import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../models/center_model.dart';
import '../../../models/child_model.dart';
import '../../../models/vaccine_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/center_service.dart';
import '../../../services/child_service.dart';
import '../../../services/vaccination_record_service.dart';
import '../../../services/vaccine_service.dart';
import '../../../utils/app_ui.dart';
import '../../../utils/date_utils.dart';

class CenterAppointmentsScreen extends StatefulWidget {
  final String currentUserId;

  const CenterAppointmentsScreen({super.key, required this.currentUserId});

  @override
  State<CenterAppointmentsScreen> createState() =>
      _CenterAppointmentsScreenState();
}

class _CenterAppointmentsScreenState extends State<CenterAppointmentsScreen> {
  final _centerService = CenterService();
  final _childService = ChildService();
  final _recordService = VaccinationRecordService();
  final _appointmentService = AppointmentService();
  final _notesController = TextEditingController(text: 'تم التطعيم بنجاح');

  String? _processingAppointmentId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markVaccinated(
    AppointmentModel appointment,
    CenterModel center,
  ) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اعتماد الجرعة'),
        content: TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'ملاحظات'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _notesController.text.trim()),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );

    if (notes == null || notes.isEmpty) return;

    setState(() => _processingAppointmentId = appointment.id);
    try {
      await _recordService.markAsVaccinated(
        appointmentId: appointment.id,
        centerId: center.id,
        childId: appointment.childId,
        parentId: appointment.parentId,
        vaccineId: appointment.vaccineId,
        notes: notes,
        approvedBy: widget.currentUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم اعتماد الجرعة تحت ${center.centerName}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث حالة الجرعة')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingAppointmentId = null);
      }
    }
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconBadge(icon: icon, color: color, background: background),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentCard(
    AppointmentModel appointment,
    Map<String, ChildModel> childrenById,
    Map<String, VaccineModel> vaccinesById,
    CenterModel center,
  ) {
    final child = childrenById[appointment.childId];
    final vaccine = vaccinesById[appointment.vaccineId];
    final isCompleted = appointment.status == 'completed';
    final isBusy = _processingAppointmentId == appointment.id;
    final style = isCompleted
        ? (color: AppColors.success, bg: AppColors.successSoft)
        : (color: AppColors.warning, bg: AppColors.warningSoft);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIconBadge(
                icon: isCompleted
                    ? Icons.verified_outlined
                    : Icons.schedule_outlined,
                color: style.color,
                background: style.bg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child?.childName ?? appointment.childId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vaccine?.vaccineName ?? appointment.vaccineId,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: isCompleted ? 'مكتمل' : 'بانتظار الاعتماد',
                color: style.color,
                background: style.bg,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoBadge(
                label: 'الميلاد: ${child?.birthDate ?? '-'}',
                icon: Icons.cake_outlined,
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
              InfoBadge(
                label: formatTimestamp(appointment.appointmentDate),
                icon: Icons.event_outlined,
                color: AppColors.success,
                background: AppColors.successSoft,
              ),
              InfoBadge(
                label: center.centerName,
                icon: Icons.local_hospital_outlined,
                color: AppColors.warning,
                background: AppColors.warningSoft,
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _markVaccinated(appointment, center),
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('اعتماد الجرعة'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CenterModel?>(
      future: _centerService.fetchCenterForUser(widget.currentUserId),
      builder: (context, centerSnapshot) {
        if (centerSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final center = centerSnapshot.data;
        if (center == null) {
          return const AppShell(
            appBar: null,
            child: Padding(
              padding: AppThemeTokens.pagePadding,
              child: EmptyStateCard(
                icon: Icons.location_off_outlined,
                title: 'الحساب غير مرتبط بمركز',
                subtitle:
                    'أضف مستند المركز داخل مجموعة centers واربطه بالمستخدم الحالي حتى يتمكن من اعتماد الجرعات.',
              ),
            ),
          );
        }

        return AppShell(
          appBar: AppBar(title: Text('اعتماد الجرعات - ${center.centerName}')),
          child: StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentService.streamAllAppointments(),
            builder: (context, appointmentSnapshot) {
              if (appointmentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final appointments = appointmentSnapshot.data ?? [];
              final visibleAppointments = appointments.where((item) {
                if (item.status == 'pending') return true;
                return item.centerId == center.id;
              }).toList();

              return StreamBuilder<List<ChildModel>>(
                stream: _childService.allChildrenStream(),
                builder: (context, childSnapshot) {
                  final children = childSnapshot.data ?? [];
                  final childrenById = {
                    for (final child in children) child.id: child,
                  };

                  return StreamBuilder<List<VaccineModel>>(
                    stream: VaccineService().streamVaccines(),
                    builder: (context, vaccineSnapshot) {
                      final vaccines = vaccineSnapshot.data ?? [];
                      final vaccinesById = {
                        for (final vaccine in vaccines) vaccine.id: vaccine,
                      };

                      final pendingCount = visibleAppointments
                          .where((item) => item.status == 'pending')
                          .length;
                      final completedCount = visibleAppointments
                          .where((item) => item.status == 'completed')
                          .length;

                      return SingleChildScrollView(
                        padding: AppThemeTokens.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HighlightBanner(
                              icon: Icons.local_hospital_outlined,
                              title: center.centerName,
                              subtitle:
                                  'الطلبات هنا معروضة من Firebase مباشرة، واعتماد الجرعة يحدّث appointment وينشئ أو يحدث سجل التطعيم.',
                              color: AppColors.primary,
                              background: AppColors.surfaceAlt,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InfoBadge(
                                  label: center.location.isEmpty
                                      ? 'الموقع غير محدد'
                                      : center.location,
                                  icon: Icons.place_outlined,
                                  color: AppColors.primary,
                                  background: AppColors.primarySoft,
                                ),
                                InfoBadge(
                                  label: center.phone.isEmpty ? '-' : center.phone,
                                  icon: Icons.phone_outlined,
                                  color: AppColors.success,
                                  background: AppColors.successSoft,
                                ),
                              ],
                            ),
                            AppThemeTokens.sectionGap,
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.12,
                              children: [
                                _summaryCard(
                                  title: 'طلبات معلقة',
                                  value: pendingCount.toString(),
                                  icon: Icons.pending_actions_outlined,
                                  color: AppColors.warning,
                                  background: AppColors.warningSoft,
                                ),
                                _summaryCard(
                                  title: 'طلبات مكتملة',
                                  value: completedCount.toString(),
                                  icon: Icons.verified_outlined,
                                  color: AppColors.success,
                                  background: AppColors.successSoft,
                                ),
                              ],
                            ),
                            AppThemeTokens.sectionGap,
                            const SectionTitle(
                              title: 'سجل الطلبات',
                              subtitle:
                                  'الطلبات المكتملة المعروضة هنا تخص هذا المركز، بينما الطلبات المعلقة تبقى متاحة للمراجعة والاعتماد.',
                            ),
                            const SizedBox(height: 12),
                            if (visibleAppointments.isEmpty)
                              const EmptyStateCard(
                                icon: Icons.inbox_outlined,
                                title: 'لا توجد طلبات حالياً',
                                subtitle:
                                    'عند إرسال ولي الأمر طلب تطعيم جديد سيظهر هنا مباشرة ليتم اعتماده من المركز.',
                              )
                            else
                              Column(
                                children: visibleAppointments.map((appointment) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _appointmentCard(
                                      appointment,
                                      childrenById,
                                      vaccinesById,
                                      center,
                                    ),
                                  );
                                }).toList(),
                              ),
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
