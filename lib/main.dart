import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app.dart';

import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  print("Notification received in background: ${message.notification?.title}");
}

void main() async {
  // تأكد من تهيئة Flutter قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase لمشروعك
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // إعداد معالج الإشعارات بالخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب صلاحيات الإشعارات
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // جلب وطباعة التوكن (محاط بـ try/catch لحماية الويب من الأخطاء إذا لم يتم إضافة VAPID Key)
  try {
    String? token;
    if (kIsWeb) {
      // للويب: يفضل إضافة vapidKey مستقبلاً هنا
      // token = await messaging.getToken(vapidKey: 'YOUR_VAPID_KEY_HERE');
      token = await messaging.getToken();
    } else {
      token = await messaging.getToken();
    }
    print("FCM TOKEN:");
    print(token);
  } catch (e) {
    print("⚠️ تعذر جلب التوكن (قد تحتاج إلى VAPID Key للويب): \$e");
  }

  // استقبال الإشعارات أثناء فتح التطبيق
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Notification received in foreground:");
    print(message.notification?.title);

    // إظهار تنبيه بصري (Snackbar) أعلى الشاشة أثناء فتح التطبيق
    final title = message.notification?.title ?? 'إشعار جديد';
    final body = message.notification?.body ?? '';

    globalMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1565C0), // اللون الأزرق الرئيسي
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  });

  // تهيئة الإشعارات (تتخطى على الويب لتجنب التعطل)
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('⚠️ تعذر تهيئة الإشعارات: $e');
    }
  }

  // on web, IndexedDB corruption can cause an "Internal error opening backing store"
  // which crashes the app.  disabling persistence prevents the SDK from creating
  // or opening the local store.  (developers should still clear storage if they
  // want offline features later.)

  // the kIsWeb constant comes from flutter/foundation
  // and allows us to only modify settings on browsers.

  // NB: Settings assignment itself won't throw, but enabling persistence does.
  // we simply turn it off entirely here.

  // on web, disable persistence to avoid indexedDB errors
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // تشغيل التطبيق
  runApp(const MyApp());
}
