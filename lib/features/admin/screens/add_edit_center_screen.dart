import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_ui.dart';
import '../../../services/admin_service.dart';

class AddEditCenterScreen extends StatefulWidget {
  final Map<String, dynamic>? centerData;
  final String? uid;

  const AddEditCenterScreen({super.key, this.centerData, this.uid});

  @override
  State<AddEditCenterScreen> createState() => _AddEditCenterScreenState();
}

class _AddEditCenterScreenState extends State<AddEditCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _centerNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _centerIdController;
  late final TextEditingController _governorateController;
  late final TextEditingController _districtController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.centerData != null;

  @override
  void initState() {
    super.initState();
    final data = widget.centerData ?? {};
    
    _centerNameController = TextEditingController(text: (data['centerName'] ?? data['fullName'] ?? '').toString());
    _emailController = TextEditingController(text: (data['email'] ?? '').toString());
    _passwordController = TextEditingController();
    _centerIdController = TextEditingController(text: (data['centerId'] ?? '').toString());
    _governorateController = TextEditingController(text: (data['governorate'] ?? '').toString());
    _districtController = TextEditingController(text: (data['district'] ?? '').toString());
    _addressController = TextEditingController(text: (data['address'] ?? '').toString());
    _phoneController = TextEditingController(text: (data['phone'] ?? '').toString());
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _centerIdController.dispose();
    _governorateController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveCenter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        // تحديث بيانات المركز فقط
        // ملاحظة: لا يمكن تحديث البريد الإلكتروني أو كلمة المرور من هنا إلا عبر Admin SDK (الخطوة 5)
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'centerName': _centerNameController.text.trim(),
          'fullName': _centerNameController.text.trim(),
          'centerId': _centerIdController.text.trim(),
          'governorate': _governorateController.text.trim(),
          'district': _districtController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات المركز بنجاح.')),
        );
        Navigator.pop(context);
      } else {
        await AdminService().createCenterAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          centerName: _centerNameController.text.trim(),
          centerId: _centerIdController.text.trim(),
          governorate: _governorateController.text.trim(),
          district: _districtController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (!mounted) return;
        _showCredentialsDialog(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المركز' : 'إضافة مركز جديد'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppThemeTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                color: AppColors.surfaceAlt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isEditing ? 'تحديث البيانات' : 'بيانات المركز الجديد',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'قم بتعديل بيانات المركز أدناه واحفظ التغييرات.'
                          : 'أدخل تفاصيل المركز الصحي لإنشاء حساب جديد يمكن استخدامه فوراً.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
              AppThemeTokens.sectionGap,
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _centerNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المركز الصحي',
                          prefixIcon: Icon(Icons.local_hospital_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        readOnly: _isEditing, // منع التعديل على البريد الإلكتروني إذا كان تعديلاً
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          hintText: 'center@example.com',
                          filled: _isEditing,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty || !v.contains('@')) {
                            return 'أدخل بريداً إلكترونياً صحيحاً';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      if (!_isEditing) ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور المؤقتة',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 6) {
                              return 'مطلوب 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _centerIdController,
                        decoration: const InputDecoration(
                          labelText: 'رقم المركز (Center ID)',
                          prefixIcon: Icon(Icons.pin_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _governorateController,
                              decoration: const InputDecoration(
                                labelText: 'المحافظة',
                                prefixIcon: Icon(Icons.map_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(
                                labelText: 'المديرية',
                                prefixIcon: Icon(Icons.location_city_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان التفصيلي',
                          prefixIcon: Icon(Icons.place_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3C1C1)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _saveCenter,
                              icon: Icon(_isEditing ? Icons.save_rounded : Icons.check_circle_rounded),
                              label: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الحساب'),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCredentialsDialog({
    required String email,
    required String password,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'بيانات تسجيل الدخول',
          textDirection: TextDirection.rtl,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _credentialRow('البريد الإلكتروني', email),
            const SizedBox(height: 12),
            _credentialRow('كلمة المرور', password),
            const SizedBox(height: 16),
            Text(
              'يمكنك نسخ هذه البيانات ومشاركتها مع المسؤول.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(
                ClipboardData(text: 'البريد: $email\nكلمة المرور: $password'),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ بيانات الدخول إلى الحافظة'),
                ),
              );
            },
            child: const Text('نسخ البيانات'),
          ),
        ],
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
