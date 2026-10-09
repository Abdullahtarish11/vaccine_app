import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/app_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManualNotificationScreen extends StatefulWidget {
  const ManualNotificationScreen({super.key});

  @override
  State<ManualNotificationScreen> createState() => _ManualNotificationScreenState();
}

class _ManualNotificationScreenState extends State<ManualNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _authService = AuthService();
  final _notificationService = NotificationService();
  
  bool _sendToAll = true;
  Map<String, dynamic>? _selectedUser;
  bool _isSending = false;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final _searchController = TextEditingController();

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _authService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان ونص الإشعار')),
      );
      return;
    }

    if (!_sendToAll && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار مستخدم محدد أو الإرسال للكل')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await _notificationService.sendManualNotification(
        title: title,
        body: body,
        targetUserId: _sendToAll ? null : _selectedUser!['uid'],
        senderId: currentUser?.uid ?? 'unknown',
      );

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
          title: const Text('تم بنجاح'),
          content: const Text('تم إرسال الإشعار وحفظه في النظام بنجاح.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الإرسال: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعار يدوي'),
      ),
      body: SingleChildScrollView(
        padding: AppThemeTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'بيانات الإشعار',
              subtitle: 'أدخل تفاصيل الإشعار الذي سيظهر للمستخدمين.',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'نص الإشعار',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.text_fields_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(
              title: 'الجمهور المستهدف',
              subtitle: 'حدد من سيستلم هذا الإشعار.',
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('إرسال لجميع المستخدمين'),
                    value: true,
                    groupValue: _sendToAll,
                    onChanged: (val) => setState(() => _sendToAll = val!),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    title: const Text('إرسال لمستخدم محدد'),
                    value: false,
                    groupValue: _sendToAll,
                    onChanged: (val) => setState(() => _sendToAll = val!),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_sendToAll) ...[
                    const Divider(height: 24),
                    if (_selectedUser != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedUser!['fullName'] ?? 'بدون اسم',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _selectedUser!['email'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _selectedUser = null),
                              icon: const Icon(Icons.close_rounded, color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _searchController,
                        onChanged: _searchUsers,
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو البريد الإلكتروني...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _isSearching 
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(user['fullName'] ?? ''),
                                subtitle: Text(user['email'] ?? ''),
                                onTap: () {
                                  setState(() {
                                    _selectedUser = user;
                                    _searchResults = [];
                                    _searchController.clear();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendNotification,
                icon: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
                label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال الإشعار الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
