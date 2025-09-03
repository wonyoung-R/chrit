// Service Worker - Temporarily Disabled
// This file intentionally does nothing to prevent caching issues
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', () => {
  self.clients.claim();
});

// No fetch event handler - let all requests go through normally