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
  var url;
  try { url = new URL(req.url); } catch(err) { return; } // malformed — let the browser handle it

  // Supabase — this app connects to a different *.supabase.co project per
  // branch (Jauharabad/HO/Mianwali/etc.), so match by hostname suffix, not
  // one hardcoded project ID. Never cache API responses: a failed call
  // should surface as a real error the app already knows how to handle,
  // not silently return stale invoice/payment/ledger data.
  var isSupabase = /(^|\.)supabase\.co$/.test(url.hostname);

  // Genuine static assets ONLY — a real allowlist by the browser's own
  // resource-loading classification (destination), not an "everything
  // else" catch-all. This is also what structurally excludes Supabase:
  // its REST calls are plain fetch()/XHR requests with destination === ''
  // (empty) — they would never match this list even without isSupabase
  // above. The explicit hostname check is kept anyway as defense-in-depth,
  // not the only guard.
  var isStaticAsset = !isSupabase &&
    ['image', 'font', 'script', 'style'].indexOf(req.destination) !== -1;

  if (isStaticAsset) {
    // Stale-while-revalidate: serve from cache instantly if available,
    // refresh in the background for next time.
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
    return;
  }

  // Everything not on the static-asset allowlist — navigation, manifest.json
  // (its own destination is 'manifest', never in the list above), Supabase/
  // API calls, and any other request type — always network-first, never a
  // stale-cache fallback. A failed API/data call surfaces as a real error;
  // a failed navigation gets an honest offline message instead of old
  // cached HTML.
  var isNavigation = req.mode === 'navigate' || req.destination === 'document';
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
});
