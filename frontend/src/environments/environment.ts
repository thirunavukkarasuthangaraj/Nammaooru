import packageInfo from '../../package.json';

export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  appUrl: 'http://localhost:4200',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'ws://localhost:8080/ws',
  version: packageInfo.version,
  buildDate: new Date().toISOString(),
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
    apiKey: "AIzaSyB7MSHYRGCj9V-y3VZWCJvQ9I0LCB_-Oag",
    authDomain: "grocery-5ecc5.firebaseapp.com",
    projectId: "grocery-5ecc5",
    storageBucket: "grocery-5ecc5.firebasestorage.app",
    messagingSenderId: "368788713881",
    appId: "1:368788713881:web:0394fb0fcd43b57c866308",
    measurementId: "G-B38Q6YJ7N0"
  }
};