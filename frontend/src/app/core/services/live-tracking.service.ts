import { Injectable, NgZone } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, interval, Subscription } from 'rxjs';
import { switchMap, catchError, takeWhile } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { GoogleMapsService, MapLocation, MapMarker } from './google-maps.service';
import { WebSocketService } from './websocket.service';

export interface PartnerLocation {
  partnerId: string;
  partnerName: string;
  lat: number;
  lng: number;
  heading?: number;
  speed?: number;
  accuracy?: number;
  timestamp: Date;
  orderId?: string;
  status: 'ONLINE' | 'BUSY' | 'OFFLINE';
}

export interface TrackingSession {
  orderId: string;
  partnerId: string;
  customerLocation?: MapLocation;
  pickupLocation?: MapLocation;
  deliveryLocation?: MapLocation;
  isActive: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class LiveTrackingService {
  private trackingSubject = new BehaviorSubject<PartnerLocation[]>([]);
  public partnerLocations$ = this.trackingSubject.asObservable();

  private trackingSubscription?: Subscription;
  private activeSessions: Map<string, TrackingSession> = new Map();
  private partnerMarkers: Map<string, any> = new Map();
  private animationFrames: Map<string, number> = new Map();

  constructor(
    private http: HttpClient,
    private ngZone: NgZone,
    private mapsService: GoogleMapsService,
    private webSocketService: WebSocketService
  ) {
    this.initializeWebSocketUpdates();
  }

  startTracking(orderId: string, partnerId: string): Observable<PartnerLocation> {
    const session: TrackingSession = {
      orderId,
      partnerId,
      isActive: true
    };
    
    this.activeSessions.set(orderId, session);

    // Start periodic API polling every 40 seconds
    this.trackingSubscription = interval(environment.trackingUpdateInterval)
      .pipe(
        switchMap(() => this.fetchPartnerLocation(partnerId)),
        takeWhile(() => session.isActive),
        catchError(error => {
          console.error('Tracking error:', error);
          return [];
        })
      )
      .subscribe(location => {
        if (location) {
          this.updatePartnerLocation(location);
          this.animateMarkerMovement(location);
        }
      });

    // Get initial location immediately
    this.fetchPartnerLocation(partnerId).subscribe(location => {
      if (location) {
        this.updatePartnerLocation(location);
        this.createOrUpdateMarker(location);
      }
    });

    return this.partnerLocations$.pipe(
      switchMap(locations => locations.filter(loc => loc.partnerId === partnerId))
    );
  }

  stopTracking(orderId: string): void {
    const session = this.activeSessions.get(orderId);
    if (session) {
      session.isActive = false;
      this.activeSessions.delete(orderId);
      
      // Remove marker
      const marker = this.partnerMarkers.get(session.partnerId);
      if (marker) {
        this.mapsService.removeMarker(session.partnerId);
        this.partnerMarkers.delete(session.partnerId);
      }

      // Cancel animation
      const animationId = this.animationFrames.get(session.partnerId);
      if (animationId) {
        cancelAnimationFrame(animationId);
        this.animationFrames.delete(session.partnerId);
      }
    }

    if (this.trackingSubscription) {
      this.trackingSubscription.unsubscribe();
    }
  }

  private fetchPartnerLocation(partnerId: string): Observable<PartnerLocation | null> {
    // Mock data for testing - simulate moving partner
    const baseLocation = {
      partnerId: partnerId,
      partnerName: 'Raj Kumar',
      lat: 12.9700 + (Math.random() - 0.5) * 0.001, // Small random movement
      lng: 77.5930 + (Math.random() - 0.5) * 0.001,
      heading: Math.random() * 360,
      speed: 20 + Math.random() * 10, // Speed between 20-30 km/h
      accuracy: 5,
      timestamp: new Date(),
      orderId: '1',
      status: 'BUSY' as const
    };

    return new Observable<PartnerLocation | null>(observer => {
      setTimeout(() => {
        observer.next(baseLocation);
        observer.complete();
      }, 200);
    });
  }

  private updatePartnerLocation(location: PartnerLocation): void {
    const currentLocations = this.trackingSubject.value;
    const index = currentLocations.findIndex(loc => loc.partnerId === location.partnerId);
    
    if (index >= 0) {
      currentLocations[index] = location;
    } else {
      currentLocations.push(location);
    }
    
    this.trackingSubject.next([...currentLocations]);
  }

  private createOrUpdateMarker(location: PartnerLocation): void {
    const markerId = location.partnerId;
    const existingMarker = this.partnerMarkers.get(markerId);

    if (existingMarker) {
      // Update existing marker position with animation
      this.animateMarkerMovement(location);
    } else {
      // Create new marker
      const marker: MapMarker = {
        id: markerId,
        position: { lat: location.lat, lng: location.lng },
        title: `${location.partnerName} - ${location.status}`,
        icon: this.getPartnerIcon(location.status),
        info: this.createInfoWindowContent(location)
      };

      const googleMarker = this.mapsService.addMarker(marker);
      this.partnerMarkers.set(markerId, googleMarker);
    }
  }

  private animateMarkerMovement(newLocation: PartnerLocation): void {
    const markerId = newLocation.partnerId;
    const marker = this.partnerMarkers.get(markerId);
    
    if (!marker) return;

    const currentPosition = marker.getPosition();
    if (!currentPosition) return;

    const startLat = currentPosition.lat();
    const startLng = currentPosition.lng();
    const endLat = newLocation.lat;
    const endLng = newLocation.lng;

    // Cancel previous animation
    const previousAnimation = this.animationFrames.get(markerId);
    if (previousAnimation) {
      cancelAnimationFrame(previousAnimation);
    }

    // Calculate animation duration based on distance
    const distance = this.calculateDistance(startLat, startLng, endLat, endLng);
    const duration = Math.min(Math.max(distance * 1000, 2000), 8000); // 2-8 seconds

    let startTime: number;
    
    const animate = (currentTime: number) => {
      if (!startTime) startTime = currentTime;
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // Easing function for smooth animation
      const easeProgress = this.easeInOutCubic(progress);

      const currentLat = startLat + (endLat - startLat) * easeProgress;
      const currentLng = startLng + (endLng - startLng) * easeProgress;

      this.ngZone.runOutsideAngular(() => {
        marker.setPosition({ lat: currentLat, lng: currentLng });
      });

      if (progress < 1) {
        const animationId = requestAnimationFrame(animate);
        this.animationFrames.set(markerId, animationId);
      } else {
        this.animationFrames.delete(markerId);
        // Update marker info
        this.updateMarkerInfo(markerId, newLocation);
      }
    };

    const animationId = requestAnimationFrame(animate);
    this.animationFrames.set(markerId, animationId);
  }

  private easeInOutCubic(t: number): number {
    return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
  }

  private updateMarkerInfo(markerId: string, location: PartnerLocation): void {
    const marker = this.partnerMarkers.get(markerId);
    if (marker) {
      marker.setTitle(`${location.partnerName} - ${location.status}`);
      // Update info window content if it exists
    }
  }

  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLng/2) * Math.sin(dLng/2);
    return 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)) * R;
  }

  private getPartnerIcon(status: string): any {
    switch (status) {
      case 'ONLINE':
        return this.mapsService.getDeliveryPartnerIcon();
      case 'BUSY':
        return {
          ...this.mapsService.getDeliveryPartnerIcon(),
          url: this.mapsService.getDeliveryPartnerIcon().url.replace('#4285f4', '#ff9800')
        };
      case 'OFFLINE':
        return {
          ...this.mapsService.getDeliveryPartnerIcon(),
          url: this.mapsService.getDeliveryPartnerIcon().url.replace('#4285f4', '#9e9e9e')
        };
      default:
        return this.mapsService.getDeliveryPartnerIcon();
    }
  }

  private createInfoWindowContent(location: PartnerLocation): string {
    const lastUpdate = new Date(location.timestamp).toLocaleTimeString();
    const speed = location.speed ? `${Math.round(location.speed)} km/h` : 'Unknown';
    
    return `
      <div style="padding: 10px; min-width: 200px;">
        <h3 style="margin: 0 0 10px 0; color: #333;">${location.partnerName}</h3>
        <div style="margin: 5px 0;">
          <strong>Status:</strong> 
          <span style="color: ${this.getStatusColor(location.status)};">${location.status}</span>
        </div>
        <div style="margin: 5px 0;"><strong>Speed:</strong> ${speed}</div>
        <div style="margin: 5px 0;"><strong>Last Update:</strong> ${lastUpdate}</div>
        ${location.orderId ? `<div style="margin: 5px 0;"><strong>Order:</strong> #${location.orderId}</div>` : ''}
      </div>
    `;
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'ONLINE': return '#4caf50';
      case 'BUSY': return '#ff9800';
      case 'OFFLINE': return '#9e9e9e';
      default: return '#333';
    }
  }

  private initializeWebSocketUpdates(): void {
    // Subscribe to real-time location updates via WebSocket
    this.webSocketService.subscribe('/topic/delivery/location/updates').subscribe((message: any) => {
      const location: PartnerLocation = JSON.parse(message.body);
      this.updatePartnerLocation(location);
      this.animateMarkerMovement(location);
    });
  }

  // Public methods for external use
  getCurrentPartnerLocation(partnerId: string): PartnerLocation | null {
    const locations = this.trackingSubject.value;
    return locations.find(loc => loc.partnerId === partnerId) || null;
  }

  getAllActivePartners(): PartnerLocation[] {
    return this.trackingSubject.value.filter(loc => loc.status !== 'OFFLINE');
  }

  setTrackingSession(orderId: string, session: Partial<TrackingSession>): void {
    const existingSession = this.activeSessions.get(orderId);
    if (existingSession) {
      Object.assign(existingSession, session);
    }
  }

  getTrackingSession(orderId: string): TrackingSession | undefined {
    return this.activeSessions.get(orderId);
  }

  // Cleanup method
  destroy(): void {
    if (this.trackingSubscription) {
      this.trackingSubscription.unsubscribe();
    }
    
    this.animationFrames.forEach(id => cancelAnimationFrame(id));
    this.animationFrames.clear();
    this.partnerMarkers.clear();
    this.activeSessions.clear();
  }
}