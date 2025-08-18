import packageInfo from '../../package.json';

export const environment = {
  production: false,
  apiUrl: 'http://65.21.4.236:8082/api',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'ws://65.21.4.236:8082/ws',
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
  }
};