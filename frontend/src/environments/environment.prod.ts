import packageInfo from '../../package.json';

export const environment = {
  production: true,
  apiUrl: 'https://api.nammaoorudelivary.in/api',
  imageBaseUrl: 'https://api.nammaoorudelivary.in', // Images served from API server
  appUrl: 'https://nammaoorudelivary.in',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'wss://api.nammaoorudelivary.in/ws',
  version: packageInfo.version,
  buildDate: new Date().toISOString(), // Dynamic build date
  timezone: 'Asia/Kolkata', // Indian Standard Time
  defaultMapCenter: {
    lat: 12.9716, // Bangalore coordinates
    lng: 77.5946
  },
  defaultMapZoom: 13,
  trackingUpdateInterval: 40000, // 40 seconds
  locationAccuracy: {
    enableHighAccuracy: true,
    timeout: 10000,
    maximumAge: 60000
  },
  firebase: {
    apiKey: "AIzaSyBdwffRV7muLR616_cxTpSP4aSmrxxbetc",
    authDomain: "nammaooru-shop-management.firebaseapp.com",
    projectId: "nammaooru-shop-management",
    storageBucket: "nammaooru-shop-management.firebasestorage.app",
    messagingSenderId: "913325898379",
    appId: "1:913325898379:web:9a39a270a6693e9a5b328e"
  }
};