// Prime CNC Service Worker
// Bump CACHE_NAME whenever APP_VERSION in index.html changes, so the
// activate-time cleanup below actually clears stale caches on each release.
const CACHE_NAME = 'primecnc-v1.4.0';

self.addEventListener('install', function(e) {
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    Promise.all([
      caches.keys().then(function(keys) {
        return Promise.all(keys.filter(function(k){ return k !== CACHE_NAME; }).map(function(k){ return caches.delete(k); }));
      }),
      self.clients.claim()
    ])
  );
});

// Report our own identity on request — lets index.html detect a genuinely
// orphaned old service worker still in control (see the self-healing check
// in index.html's registration code) via a real round-trip, not a guess.
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'GET_CACHE_NAME' && e.ports && e.ports[0]) {
    e.ports[0].postMessage({ cacheName: CACHE_NAME });
  }
});

self.addEventListener('fetch', function(e) {
  var req = e.request;
  var isNavigation = req.mode === 'navigate' || req.destination === 'document';
  // manifest.json has its own history of stale-caching problems this
  // session (fixed via a _headers no-store rule) — never let the SW's own
  // Cache Storage become a second path back into that same bug.
  var isManifest = req.url.indexOf('/manifest.json') !== -1;

  if (isNavigation || isManifest) {
    // Always the real, current version when online. If genuinely offline,
    // show a minimal honest message instead of any old cached HTML.
    e.respondWith(
      fetch(req).catch(function() {
        if (!isNavigation) return new Response('', { status: 503 });
        return new Response(
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Offline</title>' +
          '<meta name="viewport" content="width=device-width, initial-scale=1.0"></head>' +
          '<body style="font-family:sans-serif;text-align:center;padding:60px 20px;color:#334155;">' +
          '<h2>You’re offline</h2>' +
          '<p>Prime CNC Invoice System needs an internet connection to load.<br>Please check your connection and try again.</p>' +
          '</body></html>',
          { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } }
        );
      })
    );
    return;
  }

  // Static assets (icons, fonts, scripts, styles) — stale-while-revalidate:
  // serve from cache instantly if available, refresh in the background.
  e.respondWith(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.match(req).then(function(cached) {
        var networkFetch = fetch(req).then(function(res) {
          if (res && res.status === 200) cache.put(req, res.clone());
          return res;
        }).catch(function() { return cached; });
        return cached || networkFetch;
      });
    })
  );
});
