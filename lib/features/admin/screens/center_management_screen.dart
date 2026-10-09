import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_ui.dart';
import '../../../services/admin_service.dart';
import 'add_edit_center_screen.dart';

class CenterManagementScreen extends StatefulWidget {
  const CenterManagementScreen({super.key});

  @override
  State<CenterManagementScreen> createState() => _CenterManagementScreenState();
}

class _CenterManagementScreenState extends State<CenterManagementScreen> {
  String _searchQuery = '';
  final _firestore = FirebaseFirestore.instance;
  String? _currentUserRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loadingRole = false);
        return;
      }
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = (userDoc.data()?['role'] ?? '').toString().trim();
        setState(() {
          _currentUserRole = role;
          _loadingRole = false;
        });
      } else {
        setState(() => _loadingRole = false);
      }
    } catch (e) {
      setState(() => _loadingRole = false);
    }
  }

  bool get _canManageCenters =>
      _currentUserRole == 'admin' ||
      _currentUserRole == 'center' ||
      _currentUserRole == 'counter';

  Future<void> _deleteCenter(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المركز'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المركز؟ لا يمكن التراجع عن هذه العملية وسيتم مسح جميع بياناته.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService().deleteCenterAccount(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف حساب المركز بنجاح.')),
      );
    } on FirebaseException catch (e) {
      String message = 'حدث خطأ أثناء الحذف';
      if (e.code == 'permission-denied') {
        message =
            'ليس لديك صلاحية كافية لحذف المركز. هذه الميزة متاحة للمدير والمراكز الصحية فقط.';
      } else {
        message = 'حدث خطأ: ${e.message ?? e.code}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')));
    }
  }

  Future<void> _toggleActive(String uid, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'active': !currentStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? 'تم تفعيل الحساب' : 'تم إيقاف الحساب'),
        ),
      );
    } on FirebaseException catch (e) {
      String message = 'خطأ أثناء التحديث';
      if (e.code == 'permission-denied') {
        message =
            'ليس لديك صلاحية كافية لتغيير حالة المركز. هذه الميزة متاحة للمدير والمراكز الصحية فقط.';
      } else {
        message = 'خطأ: ${e.message ?? e.code}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ أثناء التحديث: $e')));
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني للمركز.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال رابط إعادة التعيين: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المراكز الصحية')),
      floatingActionButton: _canManageCenters
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditCenterScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('إضافة مركز'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppThemeTokens.pagePadding,
              child: TextField(
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'البحث عن مركز...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_currentUserRole == 'user' && !_loadingRole)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HighlightBanner(
                  icon: Icons.info_outline,
                  title: 'وضع العرض فقط',
                  subtitle:
                      'لديك صلاحية عرض المراكز فقط. لإدارة المراكز يجب أن يكون لديك دور مدير النظام أو مركز صحي.',
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                ),
              ),
            Expanded(
              child: _loadingRole
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .where('role', whereIn: ['center', 'counter'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('حدث خطأ: ${snapshot.error}'),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              (data['fullName'] ?? data['centerName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                          final email = (data['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          return name.contains(_searchQuery) ||
                              email.contains(_searchQuery);
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return const EmptyStateCard(
                            icon: Icons.domain_disabled_rounded,
                            title: 'لا توجد مراكز صحية',
                            subtitle: 'اضغط على زر الإضافة لإنشاء مركز جديد.',
                          );
                        }

                        return ListView.separated(
                          padding: AppThemeTokens.pagePadding,
                          itemCount: filteredDocs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final uid = doc.id;
                            final name =
                                (data['fullName'] ??
                                        data['centerName'] ??
                                        'بدون اسم')
                                    .toString();
                            final email = (data['email'] ?? 'بدون بريد')
                                .toString();
                            final phone = (data['phone'] ?? '').toString();
                            final isActive = data['active'] ?? true;

                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SoftIconBadge(
                                        icon: Icons.local_hospital_rounded,
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.danger,
                                        background:
                                            (isActive
                                                    ? AppColors.success
                                                    : AppColors.danger)
                                                .withOpacity(0.12),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              email,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusChip(
                                        label: isActive ? 'نشط' : 'موقوف',
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.danger,
                                        background:
                                            (isActive
                                                    ? AppColors.success
                                                    : AppColors.danger)
                                                .withOpacity(0.12),
                                      ),
                                    ],
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_rounded,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (_canManageCenters) ...[
                                        _actionButton(
                                          icon: Icons.edit_rounded,
                                          label: 'تعديل',
                                          color: AppColors.primary,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddEditCenterScreen(
                                                      centerData: data,
                                                      uid: uid,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        _actionButton(
                                          icon: isActive
                                              ? Icons.block_rounded
                                              : Icons
                                                    .check_circle_outline_rounded,
                                          label: isActive ? 'إيقاف' : 'تفعيل',
                                          color: isActive
                                              ? AppColors.warning
                                              : AppColors.success,
                                          onTap: () =>
                                              _toggleActive(uid, isActive),
                                        ),
                                        _actionButton(
                                          icon: Icons.lock_reset_rounded,
                                          label: 'كلمة المرور',
                                          color: AppColors.secondary,
                                          onTap: () => _resetPassword(email),
                                        ),
                                        _actionButton(
                                          icon: Icons.delete_outline_rounded,
                                          label: 'حذف',
                                          color: AppColors.danger,
                                          onTap: () => _deleteCenter(uid),
                                        ),
                                      ] else
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            'عرض فقط - صلاحية الإدارة متاحة للمدير والمراكز الصحية',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
