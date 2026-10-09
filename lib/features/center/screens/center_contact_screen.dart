import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/center_model.dart';
import '../../../models/center_message_model.dart';
import '../../../services/center_service.dart';
import '../../../utils/app_ui.dart';
import 'package:intl/intl.dart';

class CenterContactScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CenterContactScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CenterContactScreen> createState() => _CenterContactScreenState();
}

class _CenterContactScreenState extends State<CenterContactScreen> {
  final _centerService = CenterService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _selectedCenterId;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    }
  }

  Future<void> _sendMessage(String centerId) async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await _centerService.sendMessage(
        parentId: widget.userId,
        parentName: widget.userName,
        centerId: centerId,
        subject: subject,
        message: message,
      );

      _subjectController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرسالة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الإرسال: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildCenterSelector(List<CenterModel> centers, CenterModel selectedCenter) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SoftIconBadge(
            icon: Icons.local_hospital_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'المركز الصحي المستهدف:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCenter.id,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: centers.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    c.centerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCenterId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التواصل مع المركز'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CenterModel>>(
        stream: _centerService.streamCenters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final centers = snapshot.data ?? [];
          if (centers.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.business_outlined,
              title: 'لا توجد مراكز متاحة',
              subtitle: 'سيتم إضافة معلومات المركز الصحي قريباً.',
            );
          }

          // If _selectedCenterId is not set or not in the list, default to first center
          final center = centers.firstWhere(
            (c) => c.id == _selectedCenterId,
            orElse: () => centers.first,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCenterSelector(centers, center),
                const SizedBox(height: 16),
                _buildCenterInfoCard(center),
                const SizedBox(height: 20),
                _buildContactActions(center),
                const SizedBox(height: 24),
                _buildImportantInfoCard(),
                const SizedBox(height: 24),
                _buildMessageForm(center.id),
                const SizedBox(height: 24),
                _buildMessageHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterInfoCard(CenterModel center) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIconBadge(
                icon: Icons.local_hospital_rounded,
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.centerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (center.description.isNotEmpty) ...[
            Text(
              center.description,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          _infoRow(Icons.location_on_outlined, 'العنوان', center.location),
          _infoRow(Icons.access_time_outlined, 'أوقات الدوام', 
              center.workingHours.isNotEmpty ? center.workingHours : 'يومياً من 8 صباحاً حتى 2 ظهراً'),
          _infoRow(Icons.phone_outlined, 'رقم الهاتف', center.phone),
          if (center.email.isNotEmpty)
            _infoRow(Icons.email_outlined, 'البريد الإلكتروني', center.email),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(CenterModel center) {
    return Row(
      children: [
        _contactButton(
          icon: Icons.call,
          label: 'اتصال',
          color: AppColors.success,
          onTap: () => _launchUrl('tel:${center.phone}'),
        ),
        const SizedBox(width: 12),
        _contactButton(
          icon: Icons.message,
          label: 'واتساب',
          color: const Color(0xFF25D366),
          onTap: () => _launchUrl('https://wa.me/${center.phone.replaceAll(RegExp(r'[^0-9]'), '')}'),
        ),
        const SizedBox(width: 12),
        _contactButton(
          icon: Icons.email,
          label: 'إيميل',
          color: AppColors.primary,
          onTap: () => _launchUrl('mailto:${center.email}'),
        ),
      ],
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildImportantInfoCard() {
    return AppCard(
      color: AppColors.primarySoft.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'تعليمات هامة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bulletPoint('يرجى إحضار كرت التطعيم الأصلي في كل زيارة.'),
          _bulletPoint('يفضل الحضور قبل موعد انتهاء الدوام بنصف ساعة على الأقل.'),
          _bulletPoint('في حال وجود حرارة شديدة للطفل، يرجى استشارة الطبيب قبل التطعيم.'),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildMessageForm(String centerId) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إرسال رسالة للمركز',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'عنوان الرسالة',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'نص الرسالة',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : () => _sendMessage(centerId),
              child: _isSending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('إرسال الرسالة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'رسائلك السابقة', subtitle: 'تابع ردود المركز على استفساراتك'),
        const SizedBox(height: 12),
        StreamBuilder<List<CenterMessageModel>>(
          stream: _centerService.userMessagesStream(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final messages = snapshot.data ?? [];
            if (messages.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.mail_outline,
                title: 'لا توجد رسائل',
                subtitle: 'رسائلك وردود المركز ستظهر هنا.',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageTile(msg);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageTile(CenterMessageModel msg) {
    final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(msg.createdAt.toDate());
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  msg.subject,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              StatusChip(
                label: msg.isReplied ? 'تم الرد' : 'بانتظار الرد',
                color: msg.isReplied ? AppColors.success : AppColors.warning,
                background: msg.isReplied ? AppColors.successSoft : AppColors.warningSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg.message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.7)),
          ),
          if (msg.isReplied && msg.reply != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.reply, size: 16, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('رد المركز:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    msg.reply!,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  if (msg.repliedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd hh:mm a').format(msg.repliedAt!.toDate()),
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.7)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
