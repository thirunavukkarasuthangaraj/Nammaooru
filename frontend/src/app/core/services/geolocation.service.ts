import { Injectable } from '@angular/core';

export interface GeolocationPosition {
  coords: {
    latitude: number;
    longitude: number;
    accuracy: number;
    altitude?: number;
    altitudeAccuracy?: number;
    heading?: number;
    speed?: number;
  };
  timestamp: number;
}

export interface GeolocationOptions {
  enableHighAccuracy?: boolean;
  timeout?: number;
  maximumAge?: number;
}

@Injectable({
  providedIn: 'root'
})
export class GeolocationService {

  constructor() {}

  /**
   * Get current position using browser's geolocation API
   */
  getCurrentPosition(options?: GeolocationOptions): Promise<GeolocationPosition> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by this browser'));
        return;
      }

      const defaultOptions: GeolocationOptions = {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000, // 5 minutes
        ...options
      };

      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            coords: {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude,
              accuracy: position.coords.accuracy,
              altitude: position.coords.altitude || undefined,
              altitudeAccuracy: position.coords.altitudeAccuracy || undefined,
              heading: position.coords.heading || undefined,
              speed: position.coords.speed || undefined
            },
            timestamp: position.timestamp
          });
        },
        (error) => {
          reject(this.getGeolocationError(error));
        },
        defaultOptions
      );
    });
  }

  /**
   * Watch position changes
   */
  watchPosition(
    successCallback: (position: GeolocationPosition) => void,
    errorCallback?: (error: GeolocationPositionError) => void,
    options?: GeolocationOptions
  ): number {
    if (!navigator.geolocation) {
      throw new Error('Geolocation is not supported by this browser');
    }

    const defaultOptions: GeolocationOptions = {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 30000, // 30 seconds
      ...options
    };

    return navigator.geolocation.watchPosition(
      (position) => {
        successCallback({
          coords: {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            altitude: position.coords.altitude || undefined,
            altitudeAccuracy: position.coords.altitudeAccuracy || undefined,
            heading: position.coords.heading || undefined,
            speed: position.coords.speed || undefined
          },
          timestamp: position.timestamp
        });
      },
      errorCallback ? (error) => errorCallback(error) : undefined,
      defaultOptions
    );
  }

  /**
   * Clear position watch
   */
  clearWatch(watchId: number): void {
    navigator.geolocation.clearWatch(watchId);
  }

  /**
   * Check if geolocation is supported
   */
  isSupported(): boolean {
    return !!navigator.geolocation;
  }

  /**
   * Calculate distance between two coordinates using Haversine formula
   */
  calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371; // Radius of the Earth in kilometers
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distance in kilometers
    
    return Math.round(distance * 100) / 100; // Round to 2 decimal places
  }

  /**
   * Convert degrees to radians
   */
  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  /**
   * Convert geolocation error to readable message
   */
  private getGeolocationError(error: GeolocationPositionError): Error {
    switch (error.code) {
      case error.PERMISSION_DENIED:
        return new Error('Location access denied by user');
      case error.POSITION_UNAVAILABLE:
        return new Error('Location information is unavailable');
      case error.TIMEOUT:
        return new Error('Location request timed out');
      default:
        return new Error('An unknown error occurred while retrieving location');
    }
  }

  /**
   * Get human-readable error message
   */
  getErrorMessage(error: GeolocationPositionError): string {
    switch (error.code) {
      case error.PERMISSION_DENIED:
        return 'Please allow location access to enable delivery tracking';
      case error.POSITION_UNAVAILABLE:
        return 'Your location could not be determined. Please check your GPS settings';
      case error.TIMEOUT:
        return 'Location request took too long. Please try again';
      default:
        return 'Unable to get your location. Please try again';
    }
  }

  /**
   * Request permission for location access
   */
  async requestPermission(): Promise<PermissionState> {
    if (!navigator.permissions) {
      throw new Error('Permissions API not supported');
    }

    try {
      const permission = await navigator.permissions.query({ name: 'geolocation' });
      return permission.state;
    } catch (error) {
      throw new Error('Failed to query location permission');
    }
  }

  /**
   * Get heading/bearing between two points
   */
  calculateBearing(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const dLon = this.toRadians(lon2 - lon1);
    const lat1Rad = this.toRadians(lat1);
    const lat2Rad = this.toRadians(lat2);

    const y = Math.sin(dLon) * Math.cos(lat2Rad);
    const x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - 
              Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);

    const bearing = Math.atan2(y, x);
    
    // Convert to degrees and normalize to 0-360
    return (bearing * 180 / Math.PI + 360) % 360;
  }

  /**
   * Format distance for display
   */
  formatDistance(distance: number): string {
    if (distance < 1) {
      return `${Math.round(distance * 1000)}m`;
    } else {
      return `${distance.toFixed(1)}km`;
    }
  }

  /**
   * Check if a position is recent (within specified minutes)
   */
  isPositionRecent(timestamp: number, maxAgeMinutes: number = 5): boolean {
    const now = Date.now();
    const maxAge = maxAgeMinutes * 60 * 1000; // Convert to milliseconds
    return (now - timestamp) <= maxAge;
  }

  /**
   * Get estimated time of arrival based on distance and speed
   */
  calculateETA(distanceKm: number, speedKmh: number = 25): Date {
    const timeHours = distanceKm / speedKmh;
    const timeMilliseconds = timeHours * 60 * 60 * 1000;
    return new Date(Date.now() + timeMilliseconds);
  }
}