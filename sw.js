const CACHE = 'ecopoint-v6';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './icon.png',
  './style.css',
  './app.js',
  './ecopoint-iot-module.js',
  './ecopoint-marketplace-module.js',
  './ecopoint-analytics-module.js',
  './ecopoint-native-feel.js',
  './ecopoint-security-module.js',
  './ecopoint-pro-module.js'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
