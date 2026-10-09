import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

// دالة لمعالجة الإشعارات عندما يكون التطبيق في الخلفية أو مغلقاً
// يجب أن تكون خارج الكلاس (Top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // تطبيق نمط Singleton لضمان وجود نسخة واحدة من الخدمة
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // 1. طلب الإذن للإشعارات
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');

      // 2. تهيئة الإشعارات المحلية (لإظهار الإشعار عندما يكون التطبيق مفتوحاً)
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings,
          );

      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // هنا يمكنك إضافة كود لتحويل المستخدم إلى شاشة معينة عند النقر على الإشعار
          if (kDebugMode) {
            print("Notification clicked: ${response.payload}");
          }
        },
      );

      // إنشاء قناة (Channel) ضرورية للأندرويد 8 وما فوق
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // 3. الاستماع للإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 4. الاستماع للإشعارات أثناء فتح التطبيق (Foreground) وإظهارها كإشعار منبثق
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received message: ${message.notification?.title}');
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          _localNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription:
                    'This channel is used for important notifications.',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // استخراج الـ Token لتتمكن من إرسال إشعارات لهذا الجهاز
      String? token = await _fcm.getToken();
      if (kDebugMode) print("Device Token: $token");

      // البدء في مراقبة الإشعارات اليدوية من Firestore
      startListeningToManualNotifications();
    }
  }

  // دالة لمحاكاة نصوص الحالة
  static String getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return "تم إرسال طلب الموعد بنجاح";
      case 'approved':
        return "تم قبول موعد التطعيم";
      case 'completed':
        return "تم تسجيل التطعيم بنجاح";
      default:
        return "تحديث جديد في الحالة";
    }
  }

  /// إرسال إشعار يدوي وحفظه في Firestore
  Future<void> sendManualNotification({
    required String title,
    required String body,
    String? targetUserId, // إذا كان null يعني إرسال للكل
    required String senderId,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('notifications').add({
      'title': title.trim(),
      'body': body.trim(),
      'targetUserId': targetUserId, // null for 'all'
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'manual',
      'isRead': false,
    });

    if (kDebugMode) {
      print("Manual notification saved to Firestore: $title");
    }
  }

  /// الاستماع للإشعارات اليدوية من Firestore وإظهارها فوراً
  void startListeningToManualNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1) // نراقب آخر إشعار فقط
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            final createdAt = data['createdAt'] as Timestamp?;
            final targetUserId = data['targetUserId'] as String?;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            // Show local notification only if public or targeted to the current user
            if (targetUserId != null && targetUserId != currentUserId) {
              return;
            }

            // التأكد من أن الإشعار جديد (تم إنشاؤه في آخر 30 ثانية لتجنب تكرار الإشعارات القديمة)
            if (createdAt != null) {
              final difference = DateTime.now()
                  .difference(createdAt.toDate())
                  .inSeconds;
              if (difference.abs() < 30) {
                _showLocalNotification(
                  title: data['title'] ?? 'إشعار جديد',
                  body: data['body'] ?? '',
                );
              }
            }
          }
        });
  }

  /// دالة مساعدة لإظهار إشعار محلي
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'manual_notifications_channel',
          'إشعارات يدوية',
          channelDescription: 'تستخدم لإرسال التنبيهات اليدوية من الإدارة',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  /// جلب الإشعارات الخاصة بمستخدم معين
  Stream<List<NotificationModel>> userNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          Filter.or(
            Filter('targetUserId', isNull: true),
            Filter('targetUserId', isEqualTo: userId),
          ),
        ) // جلب الإشعارات العامة والخاصة بالمستخدم
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NotificationModel.fromDocument(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// جلب عدد الإشعارات غير المقروءة
  Stream<int> unreadCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          Filter.or(
            Filter('targetUserId', isNull: true),
            Filter('targetUserId', isEqualTo: userId),
          ),
        )
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// تحديد الإشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
