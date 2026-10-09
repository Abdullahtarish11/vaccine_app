const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.createCenterAccount = functions.https.onCall(async (data, context) => {
  // 1. التحقق من تسجيل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'يجب تسجيل الدخول لإجراء هذه العملية.'
    );
  }

  const callerUid = context.auth.uid;

  // 2. التحقق من أن المستخدم الحالي هو مدير (admin)
  const callerDoc = await db.collection('users').doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'ليس لديك صلاحية لإنشاء حسابات مراكز صحية.'
    );
  }

  // 3. استخراج البيانات المرسلة
  const { email, password, centerName, centerId, governorate, district, address, phone } = data;

  if (!email || !password || !centerName || !centerId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'البيانات الأساسية (البريد، كلمة المرور، الاسم، رقم المركز) مطلوبة.'
    );
  }

  try {
    // 4. إنشاء الحساب في Firebase Auth باستخدام Admin SDK (هذا لن يخرج المدير من حسابه)
    const userRecord = await admin.auth().createUser({
      email: email.trim(),
      password: password,
      displayName: centerName.trim(),
    });

    const newUid = userRecord.uid;

    // 5. حفظ بيانات المركز في مجموعة users
    const centerData = {
      uid: newUid,
      email: email.trim(),
      fullName: centerName.trim(), 
      centerName: centerName.trim(),
      centerId: centerId.trim(),
      governorate: (governorate || '').trim(),
      district: (district || '').trim(),
      address: (address || '').trim(),
      phone: (phone || '').trim(),
      role: 'center',
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(newUid).set(centerData);

    return {
      success: true,
      message: 'تم إنشاء حساب المركز بنجاح.',
      uid: newUid,
    };
  } catch (error) {
    console.error('Error creating center account:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'حدث خطأ غير متوقع أثناء إنشاء الحساب.'
    );
  }
});

exports.deleteCenterAccount = functions.https.onCall(async (data, context) => {
  // 1. التحقق من تسجيل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'يجب تسجيل الدخول لإجراء هذه العملية.'
    );
  }

  const callerUid = context.auth.uid;

  // 2. التحقق من الصلاحيات
  const callerDoc = await db.collection('users').doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'ليس لديك صلاحية لحذف حسابات مراكز صحية.'
    );
  }

  const { uid } = data;
  if (!uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'معرف الحساب (uid) مطلوب.'
    );
  }

  try {
    // 3. حذف الحساب من Firebase Auth
    await admin.auth().deleteUser(uid);

    // 4. حذف بيانات الحساب من Firestore
    await db.collection('users').doc(uid).delete();

    return {
      success: true,
      message: 'تم حذف الحساب بنجاح.',
    };
  } catch (error) {
    console.error('Error deleting center account:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'حدث خطأ أثناء حذف الحساب.'
    );
  }
});

exports.seedAdmin = functions.https.onRequest(async (req, res) => {
  try {
    const email = 'admin@example.com';
    const password = 'password123';
    
    // Check if user already exists
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await admin.auth().createUser({
          email: email,
          password: password,
          displayName: 'مدير النظام',
        });
      } else {
        throw e;
      }
    }

    const uid = userRecord.uid;

    await db.collection('users').doc(uid).set({
      uid: uid,
      email: email,
      fullName: 'مدير النظام',
      role: 'admin',
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    res.status(200).send(`Admin seeded successfully! Email: ${email}, Password: ${password}`);
  } catch (error) {
    res.status(500).send('Error seeding admin: ' + error.message);
  }
});
