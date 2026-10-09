import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../models/child_model.dart';
import '../../../models/vaccination_record_model.dart';
import '../../../models/vaccine_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/center_service.dart';
import '../../../services/child_service.dart';
import '../../../services/vaccination_record_service.dart';
import '../../../services/vaccine_service.dart';
import '../../../utils/app_ui.dart';
import '../../../utils/date_utils.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _queryController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await AuthService().searchUsers(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _error = results.isEmpty ? 'لم يتم العثور على مستخدم' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'حدث خطأ أثناء البحث');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChildren(Map<String, dynamic> user) {
    final uid = (user['uid'] ?? '').toString().trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserChildrenScreen(
          userUid: uid,
          userName: (user['fullName'] ?? '').toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(
        title: const Text('بحث عن مستخدم'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'تنظيف parentId',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: () async {
                final count = await ChildService().trimAllParentIds();
                if (!mounted) return;
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('تم تحديث $count سجل')));
              },
            ),
        ],
      ),
      child: Padding(
        padding: AppThemeTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'إدارة أطفال المستخدمين',
              subtitle: 'ابحث باسم ولي الأمر أو بريده أو رقم الهاتف.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'اسم أو بريد أو هاتف',
                      prefixIcon: Icon(Icons.search_outlined),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: 'بحث',
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: EmptyStateCard(
                  icon: Icons.person_search_outlined,
                  title: _error!,
                  subtitle: 'تأكد من البيانات ثم أعد المحاولة.',
                ),
              )
            else if (_results.isEmpty)
              const Expanded(
                child: EmptyStateCard(
                  icon: Icons.manage_search_outlined,
                  title: 'ابدأ البحث',
                  subtitle: 'ستظهر النتائج هنا بعد إدخال بيانات المستخدم.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final user = _results[index];
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: ListTile(
                        leading: const SoftIconBadge(
                          icon: Icons.person_outline,
                          color: AppColors.primary,
                          background: AppColors.primarySoft,
                        ),
                        title: Text((user['fullName'] ?? '-').toString()),
                        subtitle: Text((user['email'] ?? '-').toString()),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openChildren(user),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UserChildrenScreen extends StatefulWidget {
  final String userUid;
  final String userName;

  const UserChildrenScreen({
    super.key,
    required this.userUid,
    required this.userName,
  });

  @override
  State<UserChildrenScreen> createState() => _UserChildrenScreenState();
}

class _UserChildrenScreenState extends State<UserChildrenScreen> {
  final _childService = ChildService();

  Future<void> _toggleApproval(ChildModel child) async {
    await _childService.setApproved(child.id, !child.approved);
  }

  Future<void> _deleteChild(ChildModel child) async {
    await _childService.deleteChildCascade(child.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حذف الطفل وسجلاته')));
  }

  Future<void> _showEditChildDialog(ChildModel child) async {
    final nameController = TextEditingController(text: child.childName);
    final birthDateController = TextEditingController(text: child.birthDate);
    String gender = child.gender;
    bool approved = child.approved;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الطفل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الطفل'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: birthDateController,
                  decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ذكر')),
                    DropdownMenuItem(value: 'female', child: Text('أنثى')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => gender = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: approved,
                  title: const Text('ملف معتمد'),
                  onChanged: (value) => setDialogState(() => approved = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _childService.updateChild(
                  childId: child.id,
                  childName: nameController.text,
                  birthDate: birthDateController.text,
                  gender: gender,
                  approved: approved,
                );
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    birthDateController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تعديل بيانات الطفل')));
    }
  }

  void _openChildRecords(ChildModel child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChildRecordsManagementScreen(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(title: Text('أطفال ${widget.userName}')),
      child: Padding(
        padding: AppThemeTokens.pagePadding,
        child: StreamBuilder<List<ChildModel>>(
          stream: _childService.childrenForUserStream(widget.userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return EmptyStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الأطفال',
                subtitle: snapshot.error.toString(),
              );
            }

            final children = snapshot.data ?? [];
            if (children.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.child_care_outlined,
                title: 'لا يوجد أطفال',
                subtitle: 'لم يتم إضافة أطفال لهذا المستخدم حتى الآن.',
              );
            }

            return ListView.separated(
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final child = children[index];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: ListTile(
                    onTap: () => _openChildRecords(child),
                    leading: SoftIconBadge(
                      icon: child.gender == 'male'
                          ? Icons.boy_outlined
                          : Icons.girl_outlined,
                      color: child.approved
                          ? AppColors.success
                          : AppColors.warning,
                      background: child.approved
                          ? AppColors.successSoft
                          : AppColors.warningSoft,
                    ),
                    title: Text(child.childName),
                    subtitle: Text('الميلاد: ${child.birthDate}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'approve') _toggleApproval(child);
                        if (value == 'edit') _showEditChildDialog(child);
                        if (value == 'delete') _deleteChild(child);
                        if (value == 'records') _openChildRecords(child);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'approve',
                          child: Text(
                            child.approved ? 'إلغاء الاعتماد' : 'اعتماد الملف',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        const PopupMenuItem(
                          value: 'records',
                          child: Text('السجلات'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ChildRecordsManagementScreen extends StatefulWidget {
  final ChildModel child;

  const ChildRecordsManagementScreen({super.key, required this.child});

  @override
  State<ChildRecordsManagementScreen> createState() =>
      _ChildRecordsManagementScreenState();
}

class _ChildRecordsManagementScreenState
    extends State<ChildRecordsManagementScreen> {
  final _appointmentService = AppointmentService();
  final _recordService = VaccinationRecordService();
  final _vaccineService = VaccineService();
  final _centerService = CenterService();

  String? _processingAppointmentId;

  Future<void> _approveAppointment(AppointmentModel appointment) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    final center = await _centerService.fetchCenterForUser(currentUserId);
    if (!mounted) return;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم ربط هذا الحساب بمركز صحي')),
      );
      return;
    }

    setState(() => _processingAppointmentId = appointment.id);
    try {
      await _recordService.markAsVaccinated(
        appointmentId: appointment.id,
        centerId: center.id,
        childId: appointment.childId,
        parentId: appointment.parentId,
        vaccineId: appointment.vaccineId,
        notes: 'تم اعتماد الجرعة من المركز',
        approvedBy: currentUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اعتماد الجرعة وستظهر لولي الأمر')),
      );
    } finally {
      if (mounted) setState(() => _processingAppointmentId = null);
    }
  }

  Widget _statusIcon(bool completed) {
    return SoftIconBadge(
      icon: completed ? Icons.check_circle_outline : Icons.schedule_outlined,
      color: completed ? AppColors.success : AppColors.warning,
      background: completed ? AppColors.successSoft : AppColors.warningSoft,
    );
  }

  Widget _appointmentCard(
    AppointmentModel appointment,
    Map<String, String> vaccines,
  ) {
    final completed = appointment.status == 'completed';
    final isBusy = _processingAppointmentId == appointment.id;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusIcon(completed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccines[appointment.vaccineId] ?? appointment.vaccineId,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'تم أخذ الجرعة - ${formatTimestamp(appointment.appointmentDate)}'
                          : 'بانتظار الاعتماد - ${formatTimestamp(appointment.appointmentDate)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: completed ? 'تم أخذ الجرعة' : 'معلقة',
                color: completed ? AppColors.success : AppColors.warning,
                background: completed
                    ? AppColors.successSoft
                    : AppColors.warningSoft,
              ),
            ],
          ),
          if (!completed) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => _approveAppointment(appointment),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('اعتماد الجرعة'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recordCard(
    VaccinationRecordModel record,
    Map<String, String> vaccines,
  ) {
    final completed = record.status == 'completed';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _statusIcon(completed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccines[record.vaccineId] ?? record.vaccineId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? 'تم أخذ الجرعة بتاريخ: ${formatTimestamp(record.vaccinationDate)}'
                      : 'بانتظار اعتماد المركز',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle_outline, color: AppColors.success),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(title: Text('سجلات ${widget.child.childName}')),
      child: StreamBuilder<List<VaccineModel>>(
        stream: _vaccineService.streamVaccines(),
        builder: (context, vaccineSnapshot) {
          if (vaccineSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vaccineSnapshot.hasError) {
            return Padding(
              padding: AppThemeTokens.pagePadding,
              child: EmptyStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل اللقاحات',
                subtitle: vaccineSnapshot.error.toString(),
              ),
            );
          }

          final vaccines = {
            for (final vaccine in vaccineSnapshot.data ?? <VaccineModel>[])
              vaccine.id: vaccine.vaccineName,
          };

          return ListView(
            padding: AppThemeTokens.pagePadding,
            children: [
              const SectionTitle(
                title: 'طلبات الجرعات',
                subtitle:
                    'يمكن اعتماد الجرعة من هنا لتظهر لولي الأمر بعلامة صح.',
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<AppointmentModel>>(
                stream: _appointmentService.streamAppointmentsForChild(
                  widget.child.id,
                ),
                builder: (context, appointmentSnapshot) {
                  if (appointmentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (appointmentSnapshot.hasError) {
                    return EmptyStateCard(
                      icon: Icons.error_outline,
                      title: 'تعذر تحميل طلبات الجرعات',
                      subtitle: appointmentSnapshot.error.toString(),
                    );
                  }

                  final appointments = appointmentSnapshot.data ?? [];
                  if (appointments.isEmpty) {
                    return const EmptyStateCard(
                      icon: Icons.inbox_outlined,
                      title: 'لا توجد طلبات',
                      subtitle: 'لم يرسل ولي الأمر أي طلب جرعة لهذا الطفل.',
                    );
                  }

                  return Column(
                    children: appointments.map((appointment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _appointmentCard(appointment, vaccines),
                      );
                    }).toList(),
                  );
                },
              ),
              AppThemeTokens.sectionGap,
              const SectionTitle(
                title: 'سجل التطعيمات',
                subtitle:
                    'الجرعات المعتمدة تظهر هنا وتظهر أيضاً عند ولي الأمر.',
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<VaccinationRecordModel>>(
                stream: _recordService.streamRecordsForChild(widget.child.id),
                builder: (context, recordSnapshot) {
                  if (recordSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (recordSnapshot.hasError) {
                    return EmptyStateCard(
                      icon: Icons.error_outline,
                      title: 'تعذر تحميل سجل التطعيمات',
                      subtitle: recordSnapshot.error.toString(),
                    );
                  }

                  final records = recordSnapshot.data ?? [];
                  if (records.isEmpty) {
                    return const EmptyStateCard(
                      icon: Icons.history_toggle_off_outlined,
                      title: 'لا توجد سجلات',
                      subtitle: 'ستظهر الجرعات هنا بعد إرسال الطلب أو اعتماده.',
                    );
                  }

                  return Column(
                    children: records.map((record) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _recordCard(record, vaccines),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
