import packageInfo from '../../package.json';

export const environment = {
  production: true,
  apiUrl: 'https://api.nammaoorudelivary.in/api',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'wss://api.nammaoorudelivary.in/ws',
  version: '1.0.7-deploy-20250821',
  buildDate: new Date().toISOString(), // Dynamic build date
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