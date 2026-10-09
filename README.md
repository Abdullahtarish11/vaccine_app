# vaccine_aapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Project Setup & Running

The following steps can be used by team members who clone this repository
from GitHub. Adjust versions as necessary and make sure you have the
Flutter SDK, Android SDK, and any required emulators installed.

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-org>/vaccine_aapp.git
   cd vaccine_aapp
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Android tooling**
   - Open `android/local.properties` and ensure `flutter.sdk` points to your
     local Flutter installation (this file is usually generated automatically
     when you open the project in Android Studio).
   - Make sure the Android SDK and a compatible emulator or device are
     available. Use `flutter doctor` to verify the environment.

4. **Update Kotlin/AGP if needed**
   - The project uses Kotlin `2.1.0` and AGP `8.6.1`. If Flutter prints
     warnings about newer versions, update the versions in
     `android/settings.gradle.kts` accordingly.

5. **Run the app**
   ```bash
   flutter run -d <device_id>
   ```
   Replace `<device_id>` with the target (e.g. `emulator-5554` or a
   connected physical device). For a quick start you can run
   `flutter devices` to list available targets.

6. **Cleaning & rebuilding**
   If you run into build problems, try:
   ```bash
   cd android && ./gradlew clean && cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

> ⚠️ **تنبيه حول Package/Application ID**
>
> تأكّد أن `applicationId` في `android/app/build.gradle.kts` متوافق مع
> الباكيج الموجود في الملفات المصدرية (مثل
> `MainActivity.kt`). إذا غيرت المعرف إلى شيء مثل
> `saleh2026.com` فأسفل المسار يجب أن يكون لديك
> `android/app/src/main/kotlin/saleh2026/com/MainActivity.kt` مع
> `package saleh2026.com` بداخل الملف. عدم المطابقة يؤدي إلى
> `ClassNotFoundException` كما حدث سابقاً.


7. **Firebase configuration**
   - This app uses Firebase. Ensure your teammate adds the correct
     `google-services.json` (Android) and/or `GoogleService-Info.plist`
     (iOS) files into the appropriate `android/app` and `ios/Runner`
     directories. These files are ***not*** checked in.

## أوامر الطرفية المفيدة

فيما يلي بعض الأوامر التي ستحتاج إليها كثيراً أثناء تطوير المشروع، مع
شرح مختصر بالعربية:

```bash
# الحصول على التبعيات (لا تقم بتجاهله بعد استنساخ المشروع)
flutter pub get

# تنظيف ملفات البناء المؤقتة من فلاتر وGradle
flutter clean           # تنظيف إعدادات فلاتر
cd android && ./gradlew clean && cd ..  # تنظيف بناء أندرويد

# تشغيل التطبيق على جهاز أو محاكي محدد
flutter run -d <device_id>  # استبدل device_id بمعرف الجهاز (emulator-5554 مثلاً)

# عرض الأجهزة المتاحة
flutter devices

# تشغيل التحليل الساكن للكود
flutter analyze

# تشغيل الاختبارات (حاليًا يوجد اختبار واجهة واحد في المشروع)
flutter test

# بناء نسخة APK للـ Android
flutter build apk

# تحديث الحزم ومعرفة المتاحة للتحديث
flutter pub outdated

# فتح المشروع في Android Studio من الترمنال
cd android && studio .

# عرض حالة الأدوات وفحص البيئة
flutter doctor
```

كل أمر مدرج أعلاه سيساعدك في إجراءات مثل تثبيت الحزم، إصلاح الأخطاء، أو
إعداد بيئة التطوير. أضف أو احذف أو عدّل الأوامر حسب حاجتك الخاصة.
