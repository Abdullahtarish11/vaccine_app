import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/app_ui.dart';
import 'privacy_policy_screen.dart';
import 'notifications_screen.dart';
import '../../center/screens/center_contact_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SettingsScreen({super.key, required this.userData});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'notifications_enabled') _notificationsEnabled = value;
      if (key == 'reminders_enabled') _remindersEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isManagement = widget.userData['role'] == 'counter' || widget.userData['role'] == 'center';
    final name = widget.userData['fullName'] ?? 'المستخدم';
    final email = widget.userData['email'] ?? 'لا يوجد بريد';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAccountHeader(name, email, isManagement),
            const SizedBox(height: 24),
            _buildSection(
              title: isManagement ? 'إعدادات الحساب الإداري' : 'إعدادات الحساب',
              items: [
                _buildListTile(
                  icon: Icons.person_outline_rounded,
                  title: 'تعديل الملف الشخصي',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يمكنك تعديل الملف الشخصي من الشاشة الرئيسية')),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'تغيير كلمة المرور',
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'التنبيهات',
              items: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: isManagement ? 'إشعارات الطلبات الجديدة' : 'الإشعارات العامة',
                  value: _notificationsEnabled,
                  onChanged: (val) => _updateSetting('notifications_enabled', val),
                ),
                if (!isManagement)
                  _buildSwitchTile(
                    icon: Icons.alarm_on_rounded,
                    title: 'تذكير بمواعيد التطعيم',
                    value: _remindersEnabled,
                    onChanged: (val) => _updateSetting('reminders_enabled', val),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'المزيد',
              items: [
                _buildListTile(
                  icon: Icons.history_rounded,
                  title: isManagement ? 'سجل الإشعارات المرسلة' : 'سجل الإشعارات',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
                    ),
                  ),
                ),
                if (!isManagement)
                  _buildListTile(
                    icon: Icons.support_agent_rounded,
                    title: 'التواصل مع المركز الصحي',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CenterContactScreen(
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                          userName: name,
                        ),
                      ),
                    ),
                  ),
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'سياسة الخصوصية',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                _buildListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'حول التطبيق',
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'الدعم والملاحظات',
              items: [
                _buildListTile(
                  icon: Icons.feedback_outlined,
                  title: 'إرسال ملاحظات للتقنيين',
                  onTap: () => _showFeedbackDialog('ملاحظات'),
                ),
                _buildListTile(
                  icon: Icons.report_problem_outlined,
                  title: 'الإبلاغ عن عطل فني',
                  color: AppColors.danger,
                  onTap: () => _showFeedbackDialog('إبلاغ عن مشكلة'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeader(String name, String email, bool isManagement) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: isManagement ? AppColors.successSoft : AppColors.primarySoft,
            child: Icon(
              isManagement ? Icons.admin_panel_settings_rounded : Icons.person,
              size: 40,
              color: isManagement ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                if (isManagement) ...[
                  const SizedBox(height: 8),
                  InfoBadge(
                    label: 'حساب إداري / مركز',
                    color: AppColors.success,
                    background: AppColors.successSoft,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, color: color ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Trigger logout logic from parent if possible, or just sign out
          FirebaseAuth.instance.signOut();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: const Text('سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني المسجل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final email = FirebaseAuth.instance.currentUser?.email;
              if (email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرابط بنجاح')));
                }
              }
            },
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'نظام التطعيمات الذكي',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 40),
      children: const [
        Text('نظام متكامل لإدارة تطعيمات الأطفال ومتابعة مواعيدهم الصحية بدقة واحترافية.'),
      ],
    );
  }

  void _showFeedbackDialog(String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'اكتب هنا...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ملاحظاتك بنجاح. شكراً لك!')));
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
