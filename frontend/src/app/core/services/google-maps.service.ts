import { Injectable, NgZone } from '@angular/core';
import { Observable, BehaviorSubject } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

declare var google: any;

export interface MapLocation {
  lat: number;
  lng: number;
  address?: string;
}

export interface MapMarker {
  id: string;
  position: { lat: number; lng: number };
  title: string;
  icon?: string | any;
  animation?: any;
  info?: string;
}

export interface MapOptions {
  center: { lat: number; lng: number };
  zoom: number;
  styles?: any[];
  mapTypeId?: string;
}

export interface RouteOptions {
  origin: { lat: number; lng: number };
  destination: { lat: number; lng: number };
  waypoints?: { lat: number; lng: number }[];
  travelMode?: string;
  optimizeWaypoints?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class GoogleMapsService {
  private mapLoadedSubject = new BehaviorSubject<boolean>(false);
  public mapLoaded$ = this.mapLoadedSubject.asObservable();
  
  private map: any;
  private directionsService: any;
  private directionsRenderer: any;
  private markers: Map<string, any> = new Map();
  private infoWindows: Map<string, any> = new Map();

  constructor(private ngZone: NgZone) {
    this.loadGoogleMaps();
  }

  private loadGoogleMaps(): void {
    // Check if Google Maps is already loaded
    if (typeof google !== 'undefined' && google.maps) {
      this.mapLoadedSubject.next(true);
      return;
    }

    // Wait for Google Maps to be loaded via script in index.html
    const checkGoogleMaps = () => {
      if (typeof google !== 'undefined' && google.maps) {
        this.ngZone.run(() => {
          this.mapLoadedSubject.next(true);
        });
      } else {
        setTimeout(checkGoogleMaps, 100);
      }
    };
    
    checkGoogleMaps();
  }

  initializeMap(mapElement: HTMLElement, options: MapOptions): Observable<any> {
    return new Observable(observer => {
      this.mapLoaded$.subscribe(loaded => {
        if (loaded) {
          this.map = new google.maps.Map(mapElement, {
            center: options.center,
            zoom: options.zoom,
            styles: options.styles || this.getDefaultMapStyles(),
            mapTypeId: options.mapTypeId || google.maps.MapTypeId.ROADMAP,
            zoomControl: true,
            mapTypeControl: false,
            scaleControl: true,
            streetViewControl: false,
            rotateControl: false,
            fullscreenControl: true
          });

          // Initialize directions service
          this.directionsService = new google.maps.DirectionsService();
          this.directionsRenderer = new google.maps.DirectionsRenderer({
            suppressMarkers: false,
            polylineOptions: {
              strokeColor: '#4285f4',
              strokeWeight: 4,
              strokeOpacity: 0.8
            }
          });
          this.directionsRenderer.setMap(this.map);

          observer.next(this.map);
          observer.complete();
        }
      });
    });
  }

  addMarker(marker: MapMarker): any {
    if (!this.map) return null;

    const googleMarker = new google.maps.Marker({
      position: marker.position,
      map: this.map,
      title: marker.title,
      icon: marker.icon || this.getDefaultMarkerIcon('red'),
      animation: marker.animation || null
    });

    // Add info window if info is provided
    if (marker.info) {
      const infoWindow = new google.maps.InfoWindow({
        content: marker.info
      });

      googleMarker.addListener('click', () => {
        // Close all other info windows
        this.infoWindows.forEach(window => window.close());
        infoWindow.open(this.map, googleMarker);
      });

      this.infoWindows.set(marker.id, infoWindow);
    }

    this.markers.set(marker.id, googleMarker);
    return googleMarker;
  }

  updateMarkerPosition(markerId: string, position: { lat: number; lng: number }): void {
    const marker = this.markers.get(markerId);
    if (marker) {
      marker.setPosition(position);
    }
  }

  removeMarker(markerId: string): void {
    const marker = this.markers.get(markerId);
    if (marker) {
      marker.setMap(null);
      this.markers.delete(markerId);
    }

    const infoWindow = this.infoWindows.get(markerId);
    if (infoWindow) {
      infoWindow.close();
      this.infoWindows.delete(markerId);
    }
  }

  clearMarkers(): void {
    this.markers.forEach(marker => marker.setMap(null));
    this.markers.clear();
    this.infoWindows.forEach(window => window.close());
    this.infoWindows.clear();
  }

  calculateRoute(options: RouteOptions): Observable<any> {
    return new Observable(observer => {
      if (!this.directionsService) {
        observer.error('Directions service not initialized');
        return;
      }

      const request = {
        origin: options.origin,
        destination: options.destination,
        waypoints: options.waypoints?.map(point => ({
          location: point,
          stopover: true
        })) || [],
        optimizeWaypoints: options.optimizeWaypoints || false,
        travelMode: google.maps.TravelMode[options.travelMode || 'DRIVING']
      };

      this.directionsService.route(request, (result: any, status: any) => {
        if (status === 'OK') {
          this.directionsRenderer.setDirections(result);
          observer.next(result);
          observer.complete();
        } else {
          observer.error(`Directions request failed: ${status}`);
        }
      });
    });
  }

  clearRoute(): void {
    if (this.directionsRenderer) {
      this.directionsRenderer.setDirections({ routes: [] });
    }
  }

  fitBounds(positions: { lat: number; lng: number }[]): void {
    if (!this.map || positions.length === 0) return;

    const bounds = new google.maps.LatLngBounds();
    positions.forEach(position => {
      bounds.extend(new google.maps.LatLng(position.lat, position.lng));
    });

    this.map.fitBounds(bounds);
  }

  setCenter(position: { lat: number; lng: number }, zoom?: number): void {
    if (!this.map) return;

    this.map.setCenter(position);
    if (zoom) {
      this.map.setZoom(zoom);
    }
  }

  calculateDistance(from: MapLocation, to: MapLocation): number {
    if (typeof google !== 'undefined' && google.maps?.geometry) {
      const fromLatLng = new google.maps.LatLng(from.lat, from.lng);
      const toLatLng = new google.maps.LatLng(to.lat, to.lng);
      return google.maps.geometry.spherical.computeDistanceBetween(fromLatLng, toLatLng) / 1000;
    }

    // Fallback to Haversine formula
    const R = 6371;
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

      // Check for permissions first
      if ('permissions' in navigator) {
        navigator.permissions.query({name: 'geolocation'}).then((result) => {
          if (result.state === 'denied') {
            reject('Geolocation permission denied. Please enable location access in your browser.');
            return;
          }
          
          this.requestLocation(resolve, reject);
        }).catch(() => {
          // Fallback if permissions API not supported
          this.requestLocation(resolve, reject);
        });
      } else {
        this.requestLocation(resolve, reject);
      }
    });
  }

  private requestLocation(resolve: Function, reject: Function): void {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      },
      (error) => {
        let errorMessage = 'Location access failed: ';
        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMessage += 'Permission denied. Please enable location access.';
            break;
          case error.POSITION_UNAVAILABLE:
            errorMessage += 'Location information unavailable.';
            break;
          case error.TIMEOUT:
            errorMessage += 'Location request timed out.';
            break;
          default:
            errorMessage += error.message;
            break;
        }
        reject(errorMessage);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 60000
      }
    );
  }

  watchPosition(callback: (location: MapLocation) => void, errorCallback?: (error: string) => void): number {
    if (!navigator.geolocation) {
      if (errorCallback) errorCallback('Geolocation is not supported');
      return -1;
    }

    return navigator.geolocation.watchPosition(
      (position) => {
        callback({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      },
      (error) => {
        if (errorCallback) {
          errorCallback(`Location tracking error: ${error.message}`);
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 30000
      }
    );
  }

  stopWatchingPosition(watchId: number): void {
    if (watchId >= 0) {
      navigator.geolocation.clearWatch(watchId);
    }
  }

  async geocodeAddress(address: string): Promise<MapLocation | null> {
    if (!google?.maps?.Geocoder) {
      console.log('Geocoding not available:', address);
      return null;
    }

    return new Promise((resolve) => {
      const geocoder = new google.maps.Geocoder();
      geocoder.geocode({ address }, (results: any[], status: string) => {
        if (status === 'OK' && results.length > 0) {
          const location = results[0].geometry.location;
          resolve({
            lat: location.lat(),
            lng: location.lng(),
            address: results[0].formatted_address
          });
        } else {
          resolve(null);
        }
      });
    });
  }

  async reverseGeocode(lat: number, lng: number): Promise<string | null> {
    if (!google?.maps?.Geocoder) {
      return `${lat}, ${lng}`;
    }

    return new Promise((resolve) => {
      const geocoder = new google.maps.Geocoder();
      const latlng = { lat, lng };
      
      geocoder.geocode({ location: latlng }, (results: any[], status: string) => {
        if (status === 'OK' && results.length > 0) {
          resolve(results[0].formatted_address);
        } else {
          resolve(`${lat}, ${lng}`);
        }
      });
    });
  }

  // Marker Icon Helpers
  getDefaultMarkerIcon(color: string): any {
    if (!google?.maps) return null;
    
    return {
      url: `https://maps.google.com/mapfiles/ms/icons/${color}-dot.png`,
      scaledSize: new google.maps.Size(32, 32),
      origin: new google.maps.Point(0, 0),
      anchor: new google.maps.Point(16, 32)
    };
  }

  getDeliveryPartnerIcon(): any {
    return {
      url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
          <circle cx="16" cy="16" r="12" fill="#4285f4" stroke="#ffffff" stroke-width="2"/>
          <path d="M12 16l4-4 4 4" stroke="#ffffff" stroke-width="2" fill="none"/>
        </svg>
      `),
      scaledSize: new google.maps.Size(32, 32),
      anchor: new google.maps.Point(16, 16)
    };
  }

  getCustomerIcon(): any {
    return {
      url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
          <circle cx="16" cy="26" r="4" fill="#34a853"/>
          <path d="M16 2 L22 14 L10 14 Z" fill="#ea4335" stroke="#ffffff" stroke-width="1"/>
          <circle cx="16" cy="8" r="3" fill="#ffffff"/>
        </svg>
      `),
      scaledSize: new google.maps.Size(32, 32),
      anchor: new google.maps.Point(16, 30)
    };
  }

  getShopIcon(): any {
    return {
      url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
          <rect x="8" y="12" width="16" height="16" fill="#ff9800" stroke="#ffffff" stroke-width="2"/>
          <path d="M6 12 L16 4 L26 12" fill="#ff9800" stroke="#ffffff" stroke-width="2"/>
          <rect x="14" y="20" width="4" height="8" fill="#ffffff"/>
        </svg>
      `),
      scaledSize: new google.maps.Size(32, 32),
      anchor: new google.maps.Point(16, 28)
    };
  }

  // Map Styles
  private getDefaultMapStyles(): any[] {
    return [
      {
        featureType: 'poi',
        elementType: 'labels',
        stylers: [{ visibility: 'off' }]
      },
      {
        featureType: 'transit.station',
        elementType: 'labels',
        stylers: [{ visibility: 'off' }]
      }
    ];
  }

  // Enhanced Directions API Integration
  calculateDetailedRoute(options: RouteOptions & { 
    avoidTolls?: boolean; 
    avoidHighways?: boolean; 
    provideRouteAlternatives?: boolean 
  }): Observable<any> {
    return new Observable(observer => {
      if (!this.directionsService) {
        observer.error('Directions service not initialized');
        return;
      }

      const request = {
        origin: options.origin,
        destination: options.destination,
        waypoints: options.waypoints?.map(point => ({
          location: point,
          stopover: true
        })) || [],
        optimizeWaypoints: options.optimizeWaypoints || false,
        travelMode: google.maps.TravelMode[options.travelMode || 'DRIVING'],
        avoidTolls: options.avoidTolls || false,
        avoidHighways: options.avoidHighways || false,
        provideRouteAlternatives: options.provideRouteAlternatives || false,
        unitSystem: google.maps.UnitSystem.METRIC
      };

      this.directionsService.route(request, (result: any, status: any) => {
        if (status === 'OK') {
          this.directionsRenderer.setDirections(result);
          
          // Extract detailed route information
          const route = result.routes[0];
          const leg = route.legs[0];
          
          const routeInfo = {
            distance: leg.distance,
            duration: leg.duration,
            steps: leg.steps,
            overview_path: route.overview_path,
            bounds: route.bounds,
            warnings: route.warnings,
            waypoint_order: route.waypoint_order
          };
          
          observer.next(routeInfo);
          observer.complete();
        } else {
          observer.error(`Directions request failed: ${status}`);
        }
      });
    });
  }

  getStepByStepDirections(from: MapLocation, to: MapLocation): Observable<any[]> {
    return this.calculateDetailedRoute({
      origin: from,
      destination: to,
      travelMode: 'DRIVING'
    }).pipe(
      switchMap((route: any) => {
        const steps = route.steps.map((step: any, index: number) => ({
          stepNumber: index + 1,
          instruction: step.instructions.replace(/<[^>]*>/g, ''), // Remove HTML tags
          distance: step.distance.text,
          duration: step.duration.text,
          maneuver: step.maneuver || '',
          startLocation: {
            lat: step.start_location.lat(),
            lng: step.start_location.lng()
          },
          endLocation: {
            lat: step.end_location.lat(),
            lng: step.end_location.lng()
          }
        }));
        return [steps];
      })
    );
  }

  // Enhanced Places API Integration
  searchNearbyPlaces(location: MapLocation, radius: number, type: string): Promise<any[]> {
    return new Promise((resolve, reject) => {
      if (!google?.maps?.places?.PlacesService) {
        reject('Places service not available');
        return;
      }

      const service = new google.maps.places.PlacesService(this.map);
      const request = {
        location: new google.maps.LatLng(location.lat, location.lng),
        radius: radius,
        type: type
      };

      service.nearbySearch(request, (results: any[], status: any) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          resolve(results);
        } else {
          reject(`Places search failed: ${status}`);
        }
      });
    });
  }

  searchPlacesByText(query: string, location?: MapLocation): Promise<any[]> {
    return new Promise((resolve, reject) => {
      if (!google?.maps?.places?.PlacesService) {
        reject('Places service not available');
        return;
      }

      const service = new google.maps.places.PlacesService(this.map);
      const request: any = {
        query: query
      };

      if (location) {
        request.location = new google.maps.LatLng(location.lat, location.lng);
        request.radius = 50000; // 50km radius
      }

      service.textSearch(request, (results: any[], status: any) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          resolve(results);
        } else {
          reject(`Places text search failed: ${status}`);
        }
      });
    });
  }

  getPlaceDetails(placeId: string): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!google?.maps?.places?.PlacesService) {
        reject('Places service not available');
        return;
      }

      const service = new google.maps.places.PlacesService(this.map);
      const request = {
        placeId: placeId,
        fields: ['name', 'formatted_address', 'geometry', 'place_id', 'photos', 'rating', 'reviews', 'formatted_phone_number', 'website']
      };

      service.getDetails(request, (place: any, status: any) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          resolve(place);
        } else {
          reject(`Place details request failed: ${status}`);
        }
      });
    });
  }

  // Location Permission Management
  async requestLocationPermission(): Promise<boolean> {
    if (!('geolocation' in navigator)) {
      throw new Error('Geolocation not supported');
    }

    if ('permissions' in navigator) {
      try {
        const permission = await navigator.permissions.query({name: 'geolocation'});
        
        if (permission.state === 'granted') {
          return true;
        } else if (permission.state === 'prompt') {
          // Try to get location to trigger permission prompt
          try {
            await this.getCurrentLocation();
            return true;
          } catch (error) {
            return false;
          }
        } else {
          return false;
        }
      } catch (error) {
        // Fallback for browsers that don't support permissions API
        try {
          await this.getCurrentLocation();
          return true;
        } catch (error) {
          return false;
        }
      }
    } else {
      // Fallback for older browsers
      try {
        await this.getCurrentLocation();
        return true;
      } catch (error) {
        return false;
      }
    }
  }

  // Enhanced Autocomplete
  createAdvancedAutocomplete(input: HTMLInputElement, options?: {
    types?: string[];
    componentRestrictions?: any;
    bounds?: any;
    strictBounds?: boolean;
  }): any {
    if (!google?.maps?.places?.Autocomplete) {
      console.log('Autocomplete not available');
      return null;
    }

    const autocompleteOptions: any = {
      fields: ['place_id', 'formatted_address', 'geometry', 'name'],
      ...options
    };

    const autocomplete = new google.maps.places.Autocomplete(input, autocompleteOptions);

    // Bias results to current map bounds if available
    if (this.map) {
      autocomplete.bindTo('bounds', this.map);
    }

    return autocomplete;
  }

  // Real-time Navigation
  startNavigation(from: MapLocation, to: MapLocation, callback: (step: any) => void): Observable<any> {
    return new Observable(observer => {
      this.getStepByStepDirections(from, to).subscribe({
        next: (steps) => {
          let currentStepIndex = 0;
          
          // Watch position and trigger step updates
          const watchId = this.watchPosition(
            (currentLocation) => {
              // Check if user has reached the next step
              if (currentStepIndex < steps.length) {
                const currentStep = steps[currentStepIndex];
                const distanceToStep = this.calculateDistance(
                  currentLocation,
                  currentStep.endLocation
                );

                // If within 50 meters of step end, move to next step
                if (distanceToStep < 0.05) { // 50 meters
                  currentStepIndex++;
                  if (currentStepIndex < steps.length) {
                    callback(steps[currentStepIndex]);
                  } else {
                    // Navigation complete
                    this.stopWatchingPosition(watchId);
                    observer.complete();
                  }
                }
              }

              observer.next({
                currentLocation,
                currentStep: steps[currentStepIndex],
                progress: currentStepIndex / steps.length,
                remainingSteps: steps.length - currentStepIndex
              });
            },
            (error) => observer.error(error)
          );

          // Start with first step
          if (steps.length > 0) {
            callback(steps[0]);
          }
        },
        error: (error) => observer.error(error)
      });
    });
  }

  // Legacy methods for compatibility
  loadMaps(): Observable<boolean> {
    return this.mapLoaded$;
  }

  createMap(element: HTMLElement, options: any): any {
    const mapOptions: MapOptions = {
      center: options.center || environment.defaultMapCenter,
      zoom: options.zoom || environment.defaultMapZoom,
      styles: options.styles
    };
    
    this.initializeMap(element, mapOptions).subscribe();
    return this.map;
  }

  createMarker(options: any): any {
    const marker: MapMarker = {
      id: options.id || 'marker_' + Date.now(),
      position: options.position,
      title: options.title || '',
      icon: options.icon,
      info: options.info
    };
    
    return this.addMarker(marker);
  }

  createInfoWindow(options?: any): any {
    return new google.maps.InfoWindow(options);
  }

  createAutocomplete(input: HTMLInputElement, options?: any): any {
    if (!google?.maps?.places?.Autocomplete) {
      console.log('Autocomplete not available');
      return null;
    }
    
    return new google.maps.places.Autocomplete(input, options);
  }

  isLoaded$(): Observable<boolean> {
    return this.mapLoaded$;
  }

}