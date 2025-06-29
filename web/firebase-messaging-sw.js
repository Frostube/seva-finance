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
  
  const notificationTitle = payload.notification?.title || 'SevaFinance';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'default',
    data: {
      click_action: payload.data?.click_action || '/',
      type: payload.data?.type,
      relatedId: payload.data?.relatedId
    },
    actions: [
      {
        action: 'view',
        title: 'View',
        icon: '/icons/Icon-192.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ],
    requireInteraction: payload.data?.priority === 'high',
    silent: false,
    renotify: true,
    timestamp: Date.now()
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Get the click action URL from the notification data
  const clickAction = event.notification.data?.click_action || '/';
  
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(function(clientList) {
      // Try to focus existing window first
      for (const client of clientList) {
        if (client.url.includes('seva-finance-app') && 'focus' in client) {
          client.focus();
          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            clickAction: clickAction,
            notificationData: event.notification.data
          });
          return;
        }
      }
      
      // Open new window if no existing window found
      if (clients.openWindow) {
        const baseUrl = self.registration.scope;
        const targetUrl = new URL(clickAction, baseUrl).href;
        return clients.openWindow(targetUrl);
      }
    })
  );
}); 