// Import the functions you need from the SDKs you need
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBdwffRV7muLR616_cxTpSP4aSmrxxbetc",
  authDomain: "nammaooru-shop-management.firebaseapp.com",
  projectId: "nammaooru-shop-management",
  storageBucket: "nammaooru-shop-management.firebasestorage.app",
  messagingSenderId: "913325898379",
  appId: "1:913325898379:web:9a39a270a6693e9a5b328e"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/assets/icons/notification.png',
    badge: '/assets/icons/badge.png',
    tag: 'order-notification',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});