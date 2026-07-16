// Minimal Firebase Messaging service worker.
// Place this file at web/firebase-messaging-sw.js so the Flutter dev server
// (or your production host) serves it with the correct `application/javascript` MIME type.
// If you rely on Firebase background notifications, replace this with the
// official firebase-messaging-sw.js that initializes Firebase with your
// project's config. See below for a sample snippet.

self.addEventListener('push', function(event) {
  console.log('[firebase-messaging-sw.js] Push received:', event);
  // Optionally show a notification here if payload lacks automatic handling.
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
