importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyBDUw0xs0xlLCaWts9A1KJenYJyJlb-fGo",
  authDomain: "seva-finance-app.firebaseapp.com",
  projectId: "seva-finance-app",
  storageBucket: "seva-finance-app.firebasestorage.app",
  messagingSenderId: "741018143182",
  appId: "1:741018143182:web:3e9ea6caf2134652e4439f",
  measurementId: "G-PRDFE66X52"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
}); 