import packageInfo from '../../package.json';

export const environment = {
  production: true,
  apiUrl: 'https://api.nammaoorudelivary.in/api',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'wss://api.nammaoorudelivary.in/ws',
  version: packageInfo.version,
  buildDate: '2025-08-20T19:00:00Z', // Updated for deployment verification
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
  }
};