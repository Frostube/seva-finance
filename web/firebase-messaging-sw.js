importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBDUw0xs0xlLCaWts9A1KJenYJyJlb-fGo",
  authDomain: "seva-finance-app.firebaseapp.com",
  projectId: "seva-finance-app",
  storageBucket: "seva-finance-app.firebasestorage.app",
  messagingSenderId: "741018143182",
  appId: "1:741018143182:web:3e9ea6caf2134652e4439f",
  measurementId: "G-PRDFE66X52"
});

const messaging = firebase.messaging();

// Optional: Add background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
}); 