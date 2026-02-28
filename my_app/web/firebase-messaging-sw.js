// Firebase Cloud Messaging Service Worker
// This file handles background push notifications for web

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
// IMPORTANT: Replace with your Firebase project configuration
firebase.initializeApp({
  apiKey: "AIzaSyCrtMX2i2TYdAtl0Gb6ZJNgi1b7zVrI-C8",
  authDomain: "theftsense.firebaseapp.com",
  projectId: "theftsense",
  storageBucket: "theftsense.firebasestorage.app",
  messagingSenderId: "93686580855",
  appId: "1:93686580855:web:39f4edcd7f2528bd10e872"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  // Customize notification here
  const notificationTitle = payload.notification?.title || 'Shoplifting Alert';
  const notificationOptions = {
    body: payload.notification?.body || 'Suspicious activity detected',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.tag || 'shoplifting-alert',
    data: payload.data,
    requireInteraction: true,
    actions: [
      {
        action: 'view',
        title: 'View Details'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received:', event);

  event.notification.close();

  // Handle action buttons
  if (event.action === 'view') {
    // Open the app to the history page or specific alert
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        for (const client of clientList) {
          if (client.url.includes('/') && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
    );
  } else if (event.action === 'dismiss') {
    // Just close the notification (already done above)
    return;
  } else {
    // Default action - open the app
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
    );
  }
});
