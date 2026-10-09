import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/vaccine_model.dart';
import '../../../services/vaccine_service.dart';
import '../../../utils/app_ui.dart';

class VaccineManagementScreen extends StatefulWidget {
  const VaccineManagementScreen({super.key});

  @override
  State<VaccineManagementScreen> createState() =>
      _VaccineManagementScreenState();
}

class _VaccineManagementScreenState extends State<VaccineManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _service = VaccineService();

  bool _isSaving = false;
  String? _editingVaccineId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _startEdit(VaccineModel vaccine) {
    setState(() {
      _editingVaccineId = vaccine.id;
      _nameController.text = vaccine.vaccineName;
      _descriptionController.text = vaccine.description;
      _ageController.text = vaccine.ageInMonths.toString();
    });
  }

  void _resetForm() {
    setState(() {
      _editingVaccineId = null;
      _nameController.clear();
      _descriptionController.clear();
      _ageController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isEditing = _editingVaccineId != null;

    setState(() => _isSaving = true);
    try {
      final age = int.parse(_ageController.text.trim());
      if (isEditing) {
        await _service.updateVaccine(
          vaccineId: _editingVaccineId!,
          name: _nameController.text,
          description: _descriptionController.text,
          ageInMonths: age,
        );
      } else {
        await _service.createVaccine(
          name: _nameController.text,
          description: _descriptionController.text,
          ageInMonths: age,
        );
      }

      _resetForm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'تم تعديل التطعيم بنجاح' : 'تمت إضافة التطعيم بنجاح',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر حفظ بيانات التطعيم: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ بيانات التطعيم: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteVaccine(VaccineModel vaccine) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه الجرعة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _service.deleteVaccine(vaccine.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التطعيم من السجل العام')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حذف التطعيم: ${error.message ?? error.code}'),
        ),
      );
    }
  }

  Widget _buildVaccineCard(VaccineModel vaccine) {
    final accent = ageAccent(vaccine.ageInMonths);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIconBadge(
                icon: Icons.vaccines_outlined,
                color: accent,
                background: accent.withOpacity(0.12),
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
              IconButton(
                onPressed: () => _startEdit(vaccine),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () => _deleteVaccine(vaccine),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vaccine.description.isEmpty
                ? 'لا يوجد وصف لهذه الجرعة.'
                : vaccine.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editingVaccineId != null;
    return AppShell(
      appBar: AppBar(title: const Text('إدارة التطعيمات')),
      child: SingleChildScrollView(
        padding: AppThemeTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HighlightBanner(
              icon: Icons.vaccines_outlined,
              title: 'السجل العام للتطعيمات',
              subtitle:
                  'كل عنصر في هذه الصفحة مقروء من Firestore مباشرة، وتنعكس تعديلاته فوراً على شاشات الأطفال والمراكز.',
              color: AppColors.primary,
              background: AppColors.surfaceAlt,
            ),
            AppThemeTokens.sectionGap,
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: editing ? 'تعديل التطعيم' : 'إضافة تطعيم جديد',
                      subtitle: editing
                          ? 'عدّل اسم الجرعة ووصفها والعمر المستهدف ثم احفظ التغييرات.'
                          : 'أدخل بيانات الجرعة ليتم تخزينها في Firebase وإتاحتها داخل سجلات الأطفال.',
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم التطعيم',
                        prefixIcon: Icon(Icons.medical_information_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل اسم التطعيم'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل وصف الجرعة'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'العمر بالأشهر',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null || age < 0) {
                          return 'أدخل عمراً صحيحاً';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _isSaving
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    editing ? 'حفظ التعديل' : 'إضافة الجرعة',
                                  ),
                                ),
                        ),
                        if (editing) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: OutlinedButton(
                              onPressed: _resetForm,
                              child: const Text('إلغاء'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppThemeTokens.sectionGap,
            const SectionTitle(
              title: 'التطعيمات الحالية',
              subtitle: 'جميع العناصر المعروضة هنا قادمة مباشرة من Firestore.',
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<VaccineModel>>(
              stream: _service.streamVaccines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vaccines = snapshot.data ?? [];
                if (vaccines.isEmpty) {
                  return const EmptyStateCard(
                    icon: Icons.vaccines_outlined,
                    title: 'لا توجد تطعيمات حتى الآن',
                    subtitle:
                        'أضف أول جرعة لتبدأ بالظهور في سجلات الأطفال حسب العمر المناسب.',
                  );
                }

                return Column(
                  children: vaccines.map((vaccine) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildVaccineCard(vaccine),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
