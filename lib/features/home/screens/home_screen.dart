import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/child_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/child_service.dart';
import '../../../utils/app_ui.dart';
import '../../admin/screens/search_user_screen.dart';
import '../../admin/screens/vaccine_management_screen.dart';
import '../../admin/screens/center_management_screen.dart';
import '../../center/screens/center_appointments_screen.dart';
import '../../children/screens/add_child_screen.dart';
import '../../children/screens/child_vaccination_screen.dart';
import '../../admin/screens/report_screen.dart';
import '../../center/screens/manual_notification_screen.dart';
import '../../center/screens/center_inbox_screen.dart';
import '../../center/screens/center_contact_screen.dart';
import '../../../services/notification_service.dart';
import '../../../services/appointment_service.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _authService = AuthService();
  final _childService = ChildService();
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loadingUserData = true;
  String? _userDataError;
  List<ChildModel> _children = [];
  bool _loadingChildren = false;
  String? _childrenError;
  StreamSubscription<List<ChildModel>>? _childrenSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _childrenSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _loadingUserData = false;
        _userDataError = 'لا يوجد مستخدم مسجل دخول حاليًا.';
      });
      return;
    }

    setState(() {
      _loadingUserData = true;
      _userDataError = null;
    });

    try {
      final data = await _authService.fetchUserByUid(uid);
      if (!mounted) return;

      final role = (data?['role'] ?? '').toString().trim();
      setState(() {
        _userData = data;
        _loadingUserData = false;
        _userDataError = data == null
            ? 'تم تسجيل الدخول لكن لم يتم العثور على مستند المستخدم داخل مجموعة users.'
            : null;
      });

      if (role == 'user') {
        _subscribeChildren(uid);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingUserData = false;
        _userDataError = error.toString();
      });
    }
  }

  void _subscribeChildren(String uid) {
    _childrenSub?.cancel();
    setState(() {
      _loadingChildren = true;
      _childrenError = null;
    });

    _childrenSub = _childService
        .childrenForParent(uid)
        .listen(
          (list) {
            if (!mounted) return;
            setState(() {
              _children = list;
              _loadingChildren = false;
              _childrenError = null;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _loadingChildren = false;
              _childrenError = error.toString();
            });
          },
        );
  }

  bool _isManagementRole(String role) {
    final normalized = role.trim();
    return normalized == 'counter' || normalized == 'center';
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text(
              'خروج',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    if (role == 'admin') return 'مدير النظام';
    return _isManagementRole(role) ? 'المركز الصحي' : 'ولي الأمر';
  }

  String _firstName(String fullName) {
    final value = fullName.trim();
    if (value.isEmpty) return 'المستخدم';
    return value.split(' ').first;
  }

  double _tileWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 52) / 2;
    return itemWidth < 160 ? 160 : itemWidth;
  }

  void _showProfileDialog() {
    if (_userData == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow('الاسم', (_userData!['fullName'] ?? '-').toString()),
            _profileRow('البريد', (_userData!['email'] ?? '-').toString()),
            _profileRow('الهاتف', (_userData!['phone'] ?? '-').toString()),
            _profileRow(
              'الدور',
              _roleLabel((_userData!['role'] ?? '').toString()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
            child: const Text(
              'سياسة الخصوصية',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditProfileDialog();
            },
            child: const Text(
              'تعديل البيانات',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_userData == null || currentUser == null) return;

    final nameController = TextEditingController(
      text: (_userData!['fullName'] ?? '').toString(),
    );
    final phoneController = TextEditingController(
      text: (_userData!['phone'] ?? '').toString(),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      if (name.isEmpty || phone.isEmpty) return;

                      setStateDialog(() => isSaving = true);
                      try {
                        await _firestore
                            .collection('users')
                            .doc(currentUser!.uid)
                            .update({'fullName': name, 'phone': phone});
                        if (!mounted) return;
                        Navigator.pop(context);
                        _loadUserData(); // Reload the updated data
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث البيانات بنجاح'),
                          ),
                        );
                      } catch (e) {
                        setStateDialog(() => isSaving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء التحديث: $e')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(String role) {
    final isAdmin = role == 'admin';
    final management = _isManagementRole(role) || isAdmin;
    final name = _firstName((_userData?['fullName'] ?? '').toString());

    String subtitle =
        'استعرض أطفالك، اختر الجرعات المناسبة، وتابع حالة السجل والتطعيمات من حسابك مباشرة.';
    if (isAdmin) {
      subtitle = 'لوحة تحكم النظام للإشراف وإدارة المراكز الصحية بسهولة.';
    } else if (_isManagementRole(role)) {
      subtitle =
          'تابع الطلبات والجرعات وإدارة الأطفال من لوحة تحكم مرتبطة ببيانات Firebase الحية.';
    }

    IconData icon = Icons.family_restroom_outlined;
    if (isAdmin) {
      icon = Icons.admin_panel_settings_outlined;
    } else if (_isManagementRole(role)) {
      icon = Icons.local_hospital_outlined;
    }

    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBadge(
                  label: _roleLabel(role),
                  color: management ? AppColors.success : AppColors.primary,
                  background: management
                      ? AppColors.successSoft
                      : AppColors.primarySoft,
                ),
                const SizedBox(height: 14),
                Text(
                  'مرحبًا، $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _showProfileDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 88,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: management
                    ? AppColors.successSoft
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: management
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SoftIconBadge(
                    icon: icon,
                    color: management ? AppColors.success : AppColors.primary,
                    background: Colors.transparent,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الحساب',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: management ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SoftIconBadge(
            icon: icon,
            color: color,
            background: color.withOpacity(0.12),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconBadge(
              icon: icon,
              color: color,
              background: color.withOpacity(0.12),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _childAddTile() {
    return InkWell(
      onTap: () async {
        if (currentUser == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddChildScreen(parentId: currentUser!.uid),
          ),
        );
        if (!mounted || currentUser == null) return;
        _subscribeChildren(currentUser!.uid);
      },
      borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
      child: SizedBox(
        width: 180,
        child: AppCard(
          color: AppColors.surfaceAlt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SoftIconBadge(
                icon: Icons.add_rounded,
                color: AppColors.primary,
                background: AppColors.primarySoft,
                size: 28,
              ),
              Spacer(),
              Text(
                'إضافة طفل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'إضافة ملف جديد وربطه بسجل التطعيمات.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _childTile(ChildModel child) {
    final birthDate = DateTime.tryParse(child.birthDate);
    final ageInMonths = birthDate == null
        ? 0
        : DateTime.now().difference(birthDate).inDays ~/ 30;
    final accent = ageAccent(ageInMonths);

    return InkWell(
      onTap: () {
        if (currentUser == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChildVaccinationScreen(
              child: child,
              parentId: currentUser!.uid,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
      child: SizedBox(
        width: 250,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Center(
                    child: SoftIconBadge(
                      icon: child.gender == 'male'
                          ? Icons.boy_outlined
                          : Icons.girl_outlined,
                      color: accent,
                      background: accent.withOpacity(0.12),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: StatusChip(
                      label: child.approved ? 'مفعل' : 'مراجعة',
                      color: child.approved
                          ? AppColors.success
                          : AppColors.warning,
                      background: child.approved
                          ? AppColors.successSoft
                          : AppColors.warningSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                child.childName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cake_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    child.birthDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline_outlined, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    '${ageInMonths >= 12 ? '${ageInMonths ~/ 12} سنة' : '$ageInMonths شهر'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'عرض السجل الطبي',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parentDashboard(String role) {
    final uid = currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(role),
        AppThemeTokens.sectionGap,
        const SectionTitle(
          title: 'أطفالك',
          subtitle: 'اختر الطفل لعرض الجرعات المتاحة وسجل التطعيمات.',
        ),
        const SizedBox(height: 12),
        if (_loadingChildren)
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: AppCard(child: SizedBox(width: 250, height: 240)),
                );
              },
            ),
          )
        else if (_childrenError != null)
          EmptyStateCard(
            icon: Icons.error_outline,
            title: 'تعذر تحميل الأطفال',
            subtitle: _childrenError!,
            action: OutlinedButton.icon(
              onPressed: uid.isEmpty ? null : () => _subscribeChildren(uid),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _children.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _childAddTile();
                return _childTile(_children[index - 1]);
              },
            ),
          ),
        AppThemeTokens.sectionGap,
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('appointments')
              .where('parentId', isEqualTo: uid)
              .snapshots(),
          builder: (context, appointmentsSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('vaccination_records')
                  .where('parentId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, recordsSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore.collection('vaccines').snapshots(),
                  builder: (context, vaccinesSnapshot) {
                    final appointments = appointmentsSnapshot.data?.docs ?? [];
                    final records = recordsSnapshot.data?.docs ?? [];
                    final vaccines = vaccinesSnapshot.data?.docs ?? [];

                    final pendingCount = appointments.where((doc) {
                      return (doc.data()['status'] ?? '').toString().trim() ==
                          'pending';
                    }).length;
                    final completedCount = records.where((doc) {
                      return (doc.data()['status'] ?? '').toString().trim() ==
                          'completed';
                    }).length;

                    return Column(
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.0,
                          children: [
                            _metricTile(
                              title: 'الأطفال',
                              value: _children.length.toString(),
                              subtitle: 'ملفات مرتبطة بحسابك',
                              icon: Icons.child_care_outlined,
                              color: AppColors.primary,
                            ),
                            _metricTile(
                              title: 'طلبات قيد الانتظار',
                              value: pendingCount.toString(),
                              subtitle: 'بانتظار اعتماد المركز',
                              icon: Icons.schedule_outlined,
                              color: AppColors.warning,
                            ),
                            _metricTile(
                              title: 'جرعات مكتملة',
                              value: completedCount.toString(),
                              subtitle: 'جرعات معتمدة',
                              icon: Icons.verified_outlined,
                              color: AppColors.success,
                            ),
                            _metricTile(
                              title: 'اللقاحات العامة',
                              value: vaccines.length.toString(),
                              subtitle: 'متاحة حسب العمر',
                              icon: Icons.vaccines_outlined,
                              color: AppColors.purple,
                            ),
                          ],
                        ),
                        AppThemeTokens.sectionGap,
                        const HighlightBanner(
                          icon: Icons.info_outline,
                          title: 'متابعة السجل',
                          subtitle:
                              'اضغط على أي طفل لعرض الجرعات المناسبة لعمره ثم أرسل الطلب ليظهر في السجل مباشرة.',
                          color: AppColors.primary,
                          background: AppColors.surfaceAlt,
                        ),
                        AppThemeTokens.sectionGap,
                        const SectionTitle(
                          title: 'تواصل مع المركز',
                          subtitle:
                              'لأي استفسارات أو بلاغات، يمكنك التواصل مباشرة مع الإدارة.',
                        ),
                        const SizedBox(height: 12),
                        _quickAction(
                          title: 'معلومات التواصل والرسائل',
                          subtitle:
                              'أرقام المركز، الموقع، وإرسال رسائل مباشرة مع متابعة الردود.',
                          icon: Icons.contact_support_outlined,
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CenterContactScreen(
                                  userId: uid,
                                  userName: (_userData?['fullName'] ?? 'مستخدم')
                                      .toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _managementDashboard(String role) {
    final uid = currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(role),
        AppThemeTokens.sectionGap,
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('children').snapshots(),
          builder: (context, childrenSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('appointments').snapshots(),
              builder: (context, appointmentsSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('vaccination_records')
                      .snapshots(),
                  builder: (context, recordsSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore.collection('vaccines').snapshots(),
                      builder: (context, vaccinesSnapshot) {
                        final childrenCount =
                            childrenSnapshot.data?.docs.length ?? 0;
                        final appointments =
                            appointmentsSnapshot.data?.docs ?? [];
                        final records = recordsSnapshot.data?.docs ?? [];
                        final vaccinesCount =
                            vaccinesSnapshot.data?.docs.length ?? 0;

                        final pendingCount = appointments.where((doc) {
                          return (doc.data()['status'] ?? '')
                                  .toString()
                                  .trim() ==
                              'pending';
                        }).length;
                        final completedCount = records.where((doc) {
                          return (doc.data()['status'] ?? '')
                                  .toString()
                                  .trim() ==
                              'completed';
                        }).length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.0,
                              children: [
                                _metricTile(
                                  title: 'الأطفال',
                                  value: childrenCount.toString(),
                                  subtitle: 'ملفات في النظام',
                                  icon: Icons.groups_2_outlined,
                                  color: AppColors.primary,
                                ),
                                _metricTile(
                                  title: 'طلبات معلقة',
                                  value: pendingCount.toString(),
                                  subtitle: 'بانتظار الاعتماد',
                                  icon: Icons.pending_actions_outlined,
                                  color: AppColors.warning,
                                ),
                                _metricTile(
                                  title: 'جرعات معتمدة',
                                  value: completedCount.toString(),
                                  subtitle: 'سجلات مكتملة',
                                  icon: Icons.verified_outlined,
                                  color: AppColors.success,
                                ),
                                _metricTile(
                                  title: 'لقاحات عامة',
                                  value: vaccinesCount.toString(),
                                  subtitle: 'متاحة للجميع',
                                  icon: Icons.vaccines_outlined,
                                  color: AppColors.purple,
                                ),
                              ],
                            ),
                            AppThemeTokens.sectionGap,
                            const SectionTitle(
                              title: 'إجراءات سريعة',
                              subtitle:
                                  'كل بطاقة تنقلك مباشرة إلى ميزة مرتبطة ببيانات Firebase الحقيقية.',
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.05,
                              children: [
                                _quickAction(
                                  title: 'إدارة التطعيمات',
                                  subtitle:
                                      'إضافة أو تعديل الجرعات العامة التي تظهر في سجلات الأطفال.',
                                  icon: Icons.vaccines_outlined,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const VaccineManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'اعتماد الجرعات',
                                  subtitle:
                                      'مراجعة الطلبات وتحويلها إلى جرعات مكتملة تحت المركز.',
                                  icon: Icons.fact_check_outlined,
                                  color: AppColors.success,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CenterAppointmentsScreen(
                                              currentUserId: uid,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'إدارة الأطفال',
                                  subtitle:
                                      'البحث عن المستخدمين وتعديل الأطفال وحذف السجلات عند الحاجة.',
                                  icon: Icons.manage_accounts_outlined,
                                  color: AppColors.warning,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SearchUserScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'التقارير والإحصائيات',
                                  subtitle:
                                      'عرض الرسوم البيانية، ونظرة عامة على نشاط الأطفال والمواعيد.',
                                  icon: Icons.bar_chart_outlined,
                                  color: AppColors.purple,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ReportScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'بريد الشكاوي والرسائل',
                                  subtitle:
                                      'استلام ملاحظات الأهالي والرد عليها ومتابعة الاستفسارات.',
                                  icon: Icons.mark_as_unread_outlined,
                                  color: AppColors.secondary,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CenterInboxScreen(userId: uid),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'إرسال تنبيه عام',
                                  subtitle:
                                      'إرسال إشعارات يدوية للأهالي سواء للكل أو لمستخدم محدد.',
                                  icon: Icons.campaign_outlined,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ManualNotificationScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _quickAction(
                                  title: 'إدارة المراكز الصحية',
                                  subtitle:
                                      'عرض المراكز وإنشاء حسابات جديدة وإدارتها.',
                                  icon: Icons.local_hospital_rounded,
                                  color: AppColors.success,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CenterManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            AppThemeTokens.sectionGap,
                            OutlinedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout_outlined),
                              label: const Text('تسجيل الخروج'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _adminDashboard(String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(role),
        AppThemeTokens.sectionGap,
        const SectionTitle(
          title: 'إدارة النظام',
          subtitle: 'التحكم الكامل وإضافة مراكز صحية جديدة.',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: [
            _quickAction(
              title: 'إدارة المراكز الصحية',
              subtitle: 'عرض وتعديل المراكز وإنشاء حسابات جديدة.',
              icon: Icons.local_hospital_rounded,
              color: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CenterManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        AppThemeTokens.sectionGap,
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_outlined),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (_userData?['role'] ?? '').toString();
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام التطعيمات الذكي'),
        leading: IconButton(
          tooltip: 'الإعدادات',
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (_userData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(userData: _userData!),
                ),
              );
            }
          },
        ),
        actions: [
          if (uid.isNotEmpty)
            StreamBuilder<int>(
              stream: NotificationService().unreadCountStream(uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 26),
                      tooltip: 'الإشعارات',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationsScreen(userId: uid),
                          ),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            tooltip: 'الملف الشخصي',
            onPressed: _showProfileDialog,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _userDataError != null
          ? Padding(
              padding: AppThemeTokens.pagePadding,
              child: EmptyStateCard(
                icon: Icons.person_search_outlined,
                title: 'تعذر فتح الصفحة الرئيسية',
                subtitle: _userDataError!,
                action: OutlinedButton.icon(
                  onPressed: _loadUserData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            )
          : _userData == null
          ? Padding(
              padding: AppThemeTokens.pagePadding,
              child: EmptyStateCard(
                icon: Icons.person_off_outlined,
                title: 'بيانات الحساب غير مكتملة',
                subtitle:
                    'تم تسجيل الدخول لكن لم يتم العثور على مستند المستخدم داخل مجموعة users.',
                action: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserData();
                if (role == 'user' && currentUser != null) {
                  _subscribeChildren(currentUser!.uid);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppThemeTokens.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (role == 'user') _parentDashboard(role),
                    if (_isManagementRole(role)) _managementDashboard(role),
                    if (role == 'admin') _adminDashboard(role),
                    if (role.isNotEmpty &&
                        role != 'user' &&
                        role != 'admin' &&
                        !_isManagementRole(role))
                      const EmptyStateCard(
                        icon: Icons.policy_outlined,
                        title: 'الدور غير مدعوم',
                        subtitle:
                            'قيمة role الحالية لا تطابق user أو counter أو center أو admin.',
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
