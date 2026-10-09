importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyDgbN-RwGXUgGGHMTlOd3TWYbFC7Ff_eLs",
  appId: "1:1012416922510:web:b9c78e4b2e36dbd6841adf",
  messagingSenderId: "1012416922510",
  projectId: "vmsa-391ad",
  authDomain: "vmsa-391ad.firebaseapp.com",
  storageBucket: "vmsa-391ad.firebasestorage.app"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'إشعار جديد';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
