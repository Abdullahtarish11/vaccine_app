import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/center_model.dart';
import '../../../models/center_message_model.dart';
import '../../../services/center_service.dart';
import '../../../utils/app_ui.dart';
import 'package:shimmer/shimmer.dart';

class CenterInboxScreen extends StatefulWidget {
  final String userId;
  final String? initialMessageId;

  const CenterInboxScreen({
    super.key,
    required this.userId,
    this.initialMessageId,
  });

  @override
  State<CenterInboxScreen> createState() => _CenterInboxScreenState();
}

class _CenterInboxScreenState extends State<CenterInboxScreen> {
  final _centerService = CenterService();
  final _replyController = TextEditingController();
  bool _isFirstLoad = true;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _showReplyDialog(CenterMessageModel message) {
    _replyController.text = message.reply ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على: ${message.subject}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المرسل: ${message.parentName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message.message, style: const TextStyle(fontSize: 14)),
            const Divider(height: 24),
            TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                labelText: 'نص الرد',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reply = _replyController.text.trim();
              if (reply.isEmpty) return;

              await _centerService.replyToMessage(message.id, reply);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CenterModel?>(
      future: _centerService.fetchCenterForUser(widget.userId),
      builder: (context, centerSnapshot) {
        if (centerSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final center = centerSnapshot.data;
        if (center == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرسائل والشكاوي')),
            body: const Center(child: Text('الحساب غير مرتبط بمركز صحي')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('بريد المركز - ${center.centerName}'),
            centerTitle: true,
          ),
          body: StreamBuilder<List<CenterMessageModel>>(
            stream: _centerService.centerMessagesStream(center.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: AppCard(
                        child: Container(
                          height: 100,
                          width: double.infinity,
                        ),
                      ),
                    );
                  },
                );
              }

              final messages = snapshot.data ?? [];

              if (_isFirstLoad && widget.initialMessageId != null) {
                _isFirstLoad = false;
                try {
                  final initialMsg = messages.firstWhere(
                    (m) => m.id == widget.initialMessageId,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showReplyDialog(initialMsg);
                  });
                } catch (_) {
                  // Message not found or already deleted
                }
              }

              final newCount = messages.where((m) => !m.isReplied).length;
              final repliedCount = messages.where((m) => m.isReplied).length;

              return CustomScrollView(
                slivers: [
                  // ─── Hero Banner / Logo ───────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.75),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 24),
                        child: Column(
                          children: [
                            // ── Big icon ──
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.mark_as_unread_outlined,
                                size: 46,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ── Center name ──
                            Text(
                              center.centerName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'صندوق الشكاوي والرسائل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ── Stats row ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _statBadge(
                                  label: 'جديدة',
                                  count: newCount,
                                  icon: Icons.fiber_new_outlined,
                                ),
                                const SizedBox(width: 16),
                                _statBadge(
                                  label: 'تم الرد',
                                  count: repliedCount,
                                  icon: Icons.check_circle_outline,
                                ),
                                const SizedBox(width: 16),
                                _statBadge(
                                  label: 'الإجمالي',
                                  count: messages.length,
                                  icon: Icons.inbox_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Messages list ────────────────────────────────
                  if (messages.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateCard(
                        icon: Icons.inbox_outlined,
                        title: 'لا توجد رسائل بعد',
                        subtitle:
                            'شكاوي وملاحظات الأهالي ستظهر هنا فور إرسالها.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final msg = messages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildInboxTile(msg),
                            );
                          },
                          childCount: messages.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _statBadge({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTile(CenterMessageModel msg) {
    final dateStr = DateFormat(
      'yyyy-MM-dd hh:mm a',
    ).format(msg.createdAt.toDate());

    return InkWell(
      onTap: () => _showReplyDialog(msg),
      borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'من: ${msg.parentName}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: msg.isReplied ? 'تم الرد' : 'جديد',
                  color: msg.isReplied ? AppColors.success : AppColors.warning,
                  background: msg.isReplied
                      ? AppColors.successSoft
                      : AppColors.warningSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              msg.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                if (!msg.isReplied)
                  const Text(
                    'اضغط للرد',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (msg.isReplied) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ردك: ${msg.reply}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
