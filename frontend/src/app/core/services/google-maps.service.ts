import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface MapLocation {
  lat: number;
  lng: number;
  address?: string;
}

@Injectable({
  providedIn: 'root'
})
export class GoogleMapsService {
  private isLoaded = new BehaviorSubject<boolean>(false);

  constructor() {
    // Simplified service without Google Maps dependency
    this.isLoaded.next(true);
  }

  loadGoogleMaps(): Promise<boolean> {
    return Promise.resolve(true);
  }

  loadMaps(): Observable<boolean> {
    return this.isLoaded.asObservable();
  }

  createMap(element: HTMLElement, options: any): any {
    console.log('Google Maps not available - using placeholder');
    element.innerHTML = '<div style="display: flex; align-items: center; justify-content: center; height: 100%; background: #f0f0f0; color: #666;">Map placeholder - Google Maps not configured</div>';
    return null;
  }

  createMarker(options: any): any {
    return null;
  }

  createInfoWindow(options?: any): any {
    return null;
  }

  async geocodeAddress(address: string): Promise<MapLocation | null> {
    console.log('Geocoding not available:', address);
    return null;
  }

  async reverseGeocode(lat: number, lng: number): Promise<string | null> {
    return `${lat}, ${lng}`;
  }

  calculateDistance(from: MapLocation, to: MapLocation): number {
    // Simple Haversine formula
    const R = 6371; // Radius of the Earth in kilometers
    const dLat = (to.lat - from.lat) * Math.PI / 180;
    const dLng = (to.lng - from.lng) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(from.lat * Math.PI / 180) * Math.cos(to.lat * Math.PI / 180) * 
      Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  getCurrentLocation(): Promise<MapLocation> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject('Geolocation is not supported by this browser');
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            lat: position.coords.latitude,
            lng: position.coords.longitude
          });
        },
        (error) => {
          reject(`Geolocation error: ${error.message}`);
        }
      );
    });
  }

  createAutocomplete(input: HTMLInputElement, options?: any): any {
    console.log('Autocomplete not available');
    return null;
  }

  isLoaded$(): Observable<boolean> {
    return this.isLoaded.asObservable();
  }
}