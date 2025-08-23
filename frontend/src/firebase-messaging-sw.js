// Import the functions you need from the SDKs you need
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyB7MSHYRGCj9V-y3VZWCJvQ9I0LCB_-Oag",
  authDomain: "grocery-5ecc5.firebaseapp.com",
  projectId: "grocery-5ecc5",
  storageBucket: "grocery-5ecc5.firebasestorage.app",
  messagingSenderId: "368788713881",
  appId: "1:368788713881:web:0394fb0fcd43b57c866308",
  measurementId: "G-B38Q6YJ7N0"
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