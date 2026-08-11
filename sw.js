// Steeze OS service worker
// Strategy: cache the app shell (HTML/icons/manifest) so the app opens fast
// and works offline, but ALWAYS go to the network for Supabase + Storage so
// the user never sees stale data. Bump CACHE_NAME to force a refresh.

// OneSignal push notification handler. importScripts must run BEFORE any
// other code in the SW that registers fetch/push listeners. We import from
// SAME-ORIGIN (/OneSignalSDKWorker.js) instead of OneSignal's CDN — the CDN
// import was failing silently (likely a CORS issue inside the SW context),
// which left the browser's PushManager with no subscription.
// The OneSignalSDKWorker.js file must be uploaded to the web root.
try { importScripts('/OneSignalSDKWorker.js'); } catch(e) { console.error('OneSignal SW import failed:', e); }

const CACHE_NAME = 'steeze-os-v340';

// Allow the page to ask us to activate a freshly installed version immediately
// (paired with controllerchange + reload in index.html for auto-update).
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting();
});
const APP_SHELL = [
  '/',
  '/index.html',
  '/app.js',
  '/styles.css',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
  '/icon-maskable.png',
  '/apple-touch-icon.png',
  '/favicon.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL).catch(()=>{}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Never cache Supabase API, storage, auth, or any third-party calls.
  // Always go to the network so the app sees fresh data.
  const isSupabase = /\.supabase\.(co|in)$/i.test(url.hostname);
  const isCDN     = /^(cdn|unpkg|cdn\.jsdelivr|cdn\.tailwindcss)/i.test(url.hostname);
  const isSameOrigin = url.origin === self.location.origin;
  if (isSupabase || !isSameOrigin || isCDN) return;

  // App shell — network first, fall back to cache when offline.
  event.respondWith(
    fetch(req)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((c) => c.put(req, copy)).catch(()=>{});
        return res;
      })
      .catch(() => caches.match(req).then((hit) => hit || caches.match('/index.html')))
  );
});
