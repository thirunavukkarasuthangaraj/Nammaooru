// Service Worker for Delivery Partner PWA
const CACHE_NAME = 'delivery-app-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/styles.css',
  '/main.js',
  '/polyfills.js',
  '/runtime.js',
  '/assets/icons/icon-192x192.png',
  '/assets/icons/icon-512x512.png'
];

// Install Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

// Activate Service Worker
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch Strategy: Network First, falling back to Cache
self.addEventListener('fetch', event => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  // Handle API requests differently
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          // Clone the response before caching
          const responseToCache = response.clone();
          
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, responseToCache);
          });
          
          return response;
        })
        .catch(() => {
          // If network fails, try cache
          return caches.match(event.request);
        })
    );
  } else {
    // For non-API requests, use Cache First strategy
    event.respondWith(
      caches.match(event.request)
        .then(response => {
          if (response) {
            return response;
          }
          return fetch(event.request).then(response => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            const responseToCache = response.clone();
            
            caches.open(CACHE_NAME).then(cache => {
              cache.put(event.request, responseToCache);
            });
            
            return response;
          });
        })
    );
  }
});

// Background Sync for offline actions
self.addEventListener('sync', event => {
  if (event.tag === 'sync-orders') {
    event.waitUntil(syncOrders());
  } else if (event.tag === 'sync-location') {
    event.waitUntil(syncLocation());
  }
});

// Push Notifications
self.addEventListener('push', event => {
  const options = {
    body: event.data ? event.data.text() : 'New order available!',
    icon: '/assets/icons/icon-192x192.png',
    badge: '/assets/icons/badge-72x72.png',
    vibrate: [200, 100, 200],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'accept',
        title: 'Accept',
        icon: '/assets/icons/check.png'
      },
      {
        action: 'reject',
        title: 'Reject',
        icon: '/assets/icons/close.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('New Delivery Order', options)
  );
});

// Notification Click Handler
self.addEventListener('notificationclick', event => {
  event.notification.close();

  if (event.action === 'accept') {
    // Handle accept action
    clients.openWindow('/delivery/partner/orders?action=accept');
  } else if (event.action === 'reject') {
    // Handle reject action
    clients.openWindow('/delivery/partner/orders?action=reject');
  } else {
    // Just open the app
    clients.openWindow('/delivery/partner/dashboard');
  }
});

// Helper Functions
async function syncOrders() {
  try {
    const cache = await caches.open(CACHE_NAME);
    const requests = await cache.keys();
    
    // Filter for order-related requests
    const orderRequests = requests.filter(req => 
      req.url.includes('/api/delivery/assignments')
    );
    
    // Retry failed requests
    for (const request of orderRequests) {
      try {
        const response = await fetch(request);
        await cache.put(request, response);
      } catch (error) {
        console.error('Failed to sync order:', error);
      }
    }
  } catch (error) {
    console.error('Sync orders failed:', error);
  }
}

async function syncLocation() {
  try {
    // Get stored location updates from IndexedDB
    const db = await openDB();
    const tx = db.transaction('locations', 'readonly');
    const store = tx.objectStore('locations');
    const locations = await store.getAll();
    
    // Send each location update to server
    for (const location of locations) {
      try {
        await fetch('/api/delivery/tracking/update-location', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(location)
        });
        
        // Remove successfully synced location
        const deleteTx = db.transaction('locations', 'readwrite');
        await deleteTx.objectStore('locations').delete(location.id);
      } catch (error) {
        console.error('Failed to sync location:', error);
      }
    }
  } catch (error) {
    console.error('Sync location failed:', error);
  }
}

// IndexedDB Helper
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DeliveryAppDB', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = event => {
      const db = event.target.result;
      
      if (!db.objectStoreNames.contains('locations')) {
        db.createObjectStore('locations', { keyPath: 'id', autoIncrement: true });
      }
      
      if (!db.objectStoreNames.contains('orders')) {
        db.createObjectStore('orders', { keyPath: 'id' });
      }
    };
  });
}