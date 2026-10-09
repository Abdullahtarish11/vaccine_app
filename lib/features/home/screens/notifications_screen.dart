import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../utils/app_ui.dart';
import 'package:intl/intl.dart';
import '../../center/screens/center_inbox_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.userNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.notifications_off_outlined,
              title: 'لا توجد إشعارات',
              subtitle: 'ستظهر الإشعارات والتنبيهات المهمة هنا فور وصولها.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final date = notification.createdAt.toDate();
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final timeStr = DateFormat('hh:mm a').format(date);

              return _NotificationTile(
                notification: notification,
                dateStr: dateStr,
                timeStr: timeStr,
                onTap: () {
                  if (!notification.isRead) {
                    notificationService.markAsRead(notification.id);
                  }
                  if (notification.type == 'message') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CenterInboxScreen(
                          userId: userId,
                          initialMessageId: notification.referenceId,
                        ),
                      ),
                    );
                  } else {
                    _showNotificationDetails(context, notification);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String dateStr;
  final String timeStr;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.dateStr,
    required this.timeStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primarySoft.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.isRead ? AppColors.surfaceAlt : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type == 'message'
                    ? (notification.isRead ? Icons.mail_outline_rounded : Icons.mail_rounded)
                    : (notification.isRead ? Icons.notifications_outlined : Icons.notifications_active),
                color: notification.isRead ? AppColors.textSecondary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.7)),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
