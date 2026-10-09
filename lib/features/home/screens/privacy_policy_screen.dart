import 'package:flutter/material.dart';
import '../../../utils/app_ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'حماية البيانات وأمانها',
              content:
                  'يلتزم نظام التطعيمات بحماية بياناتك وبيانات أطفالك. يتم تخزين كافة المعلومات بشكل آمن ومشفر باستخدام تقنيات Firebase العالمية التابعة لشركة Google، لضمان أعلى مستويات الأمان والخصوصية.',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'الغرض من جمع البيانات',
              content:
                  'تُستخدم المعلومات التي تقدمها (مثل أسماء الأطفال، تواريخ الميلاد، وسجلات التطعيم) فقط للأغراض الصحية وإدارة جدول التطعيمات الوطني، لمساعدتك في متابعة صحة أطفالك وضمان حصولهم على اللقاحات في مواعيدها.',
              icon: Icons.health_and_safety_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'عدم مشاركة البيانات',
              content:
                  'نحن نضمن عدم مشاركة، بيع، أو تأجير بياناتك الشخصية لأي جهات خارجية أو أطراف ثالثة لأغراض تجارية أو تسويقية. البيانات متاحة فقط لك وللمركز الصحي المسؤول عن متابعة الحالة.',
              icon: Icons.visibility_off_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'نظام الإشعارات والتذكير',
              content:
                  'تُستخدم الإشعارات داخل التطبيق لغرض وحيد وهو تذكيرك بمواعيد التطعيمات القادمة، أو إرسال تنبيهات صحية هامة من قبل المركز الصحي التابع له.',
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'تحديث المعلومات',
              content:
                  'لديك الحق الكامل في تحديث بياناتك الشخصية أو بيانات أطفالك من خلال إعدادات الملف الشخصي داخل التطبيق لضمان دقة السجلات الصحية.',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'مسؤولية المركز الصحي',
              content:
                  'المركز الصحي هو الجهة المسؤولة عن مراجعة واعتماد سجلات التطعيم. في حال وجود أي استفسار حول دقة البيانات الصحية، يرجى التواصل مع المركز مباشرة.',
              icon: Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      color: AppColors.primarySoft.withOpacity(0.3),
      child: Row(
        children: [
          const SoftIconBadge(
            icon: Icons.privacy_tip_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'خصوصيتك هي أولويتنا',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'نحن نطبق أعلى معايير الحماية لبياناتك الصحية.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'آخر تحديث: ${DateTime.now().year}/05/15',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'إدارة نظام التطعيمات الذكي',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
