import { Component, OnInit, OnDestroy, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Subject, takeUntil, interval } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DeliveryTrackingService, DeliveryTracking } from '../../services/delivery-tracking.service';
import { OrderAssignmentService, OrderAssignment } from '../../services/order-assignment.service';
import { LiveTrackingService, PartnerLocation } from '../../../../core/services/live-tracking.service';
import { GoogleMapsService, MapOptions, MapMarker, MapLocation } from '../../../../core/services/google-maps.service';
import { ApiResponseHelper } from '../../../../core/models/api-response.model';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-order-tracking',
  templateUrl: './order-tracking.component.html',
  styleUrls: ['./order-tracking.component.scss']
})
export class OrderTrackingComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild('mapContainer', { static: false }) mapContainer!: ElementRef;
  private destroy$ = new Subject<void>();
  private trackingInterval?: any;

  assignmentId: number = 0;
  assignment: OrderAssignment | null = null;
  tracking: DeliveryTracking | null = null;
  trackingHistory: any[] = [];
  
  isLoading = true;
  isTrackingActive = false;
  lastUpdateTime: Date | null = null;
  
  // Map and tracking data
  mapCenter = { lat: 12.9716, lng: 77.5946 }; // Default to Bangalore
  mapZoom = 13;
  partnerLocation: { lat: number; lng: number } | null = null;
  deliveryLocation: { lat: number; lng: number } | null = null;
  currentPartnerLocation: PartnerLocation | null = null;
  map: any = null;
  isMapLoaded = false;
  userLocation: MapLocation | null = null;
  isLocationPermissionGranted = false;
  locationWatchId: number = -1;
  showDirections = false;
  
  // Status tracking
  statusSteps = [
    { key: 'ASSIGNED', label: 'Order Assigned', icon: 'assignment', completed: false },
    { key: 'ACCEPTED', label: 'Accepted by Partner', icon: 'check_circle', completed: false },
    { key: 'PICKED_UP', label: 'Picked Up', icon: 'shopping_cart', completed: false },
    { key: 'IN_TRANSIT', label: 'On the Way', icon: 'local_shipping', completed: false },
    { key: 'DELIVERED', label: 'Delivered', icon: 'check_circle_outline', completed: false }
  ];

  constructor(
    private route: ActivatedRoute,
    private trackingService: DeliveryTrackingService,
    private assignmentService: OrderAssignmentService,
    private liveTrackingService: LiveTrackingService,
    public googleMapsService: GoogleMapsService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.route.params.pipe(takeUntil(this.destroy$)).subscribe(params => {
      this.assignmentId = +params['assignmentId'];
      if (this.assignmentId) {
        this.loadAssignmentData();
      }
    });
  }

  ngAfterViewInit(): void {
    this.initializeMap();
    this.requestLocationPermission();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.stopRealTimeTracking();
    if (this.assignment?.partnerId) {
      this.liveTrackingService.stopTracking(this.assignmentId.toString());
    }
    if (this.locationWatchId >= 0) {
      this.googleMapsService.stopWatchingPosition(this.locationWatchId);
    }
  }

  loadAssignmentData(): void {
    this.assignmentService.getAssignmentById(this.assignmentId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.assignment = response.data;
            this.updateStatusSteps();
            this.loadTrackingData();
            
            // Set delivery location
            if (this.assignment.deliveryLatitude && this.assignment.deliveryLongitude) {
              this.deliveryLocation = {
                lat: this.assignment.deliveryLatitude,
                lng: this.assignment.deliveryLongitude
              };
              this.mapCenter = this.deliveryLocation;
              this.addDeliveryLocationMarker();
            }
            
            // Start live tracking for delivery partner
            if (this.assignment.partnerId && this.isDeliveryInProgress()) {
              this.startLiveTracking();
            }
          } else {
            this.snackBar.open('Assignment not found', 'Close', { duration: 3000 });
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading assignment:', error);
          this.snackBar.open('Error loading tracking information', 'Close', { duration: 3000 });
          this.isLoading = false;
        }
      });
  }

  private loadTrackingData(): void {
    if (!this.assignmentId) return;

    // Load latest tracking data
    this.trackingService.getLatestTracking(this.assignmentId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.tracking = response.data;
            this.lastUpdateTime = new Date();
            
            // Update partner location
            if (this.tracking.latitude && this.tracking.longitude) {
              this.partnerLocation = {
                lat: this.tracking.latitude,
                lng: this.tracking.longitude
              };
            }
            
            // Check if tracking is active
            this.isTrackingActive = this.isTrackingRecent();
          }
        },
        error: (error) => {
          console.error('Error loading tracking data:', error);
        }
      });

    // Load tracking history
    this.trackingService.getTrackingHistory(this.assignmentId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.trackingHistory = response.data;
          }
        },
        error: (error) => {
          console.error('Error loading tracking history:', error);
        }
      });
  }

  private updateStatusSteps(): void {
    if (!this.assignment) return;

    const status = this.assignment.status;
    const statusOrder = ['ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];
    const currentIndex = statusOrder.indexOf(status);

    this.statusSteps.forEach((step, index) => {
      step.completed = index <= currentIndex;
    });
  }

  private startRealTimeTracking(): void {
    // Fallback polling - reduced frequency since we have live tracking
    this.trackingInterval = interval(120000) // Every 2 minutes as backup
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (this.assignment && this.isDeliveryInProgress()) {
          this.loadTrackingData();
        }
      });
  }

  private stopRealTimeTracking(): void {
    if (this.trackingInterval) {
      clearInterval(this.trackingInterval);
    }
  }

  private isDeliveryInProgress(): boolean {
    if (!this.assignment) return false;
    return ['ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'].includes(this.assignment.status);
  }

  private isTrackingRecent(): boolean {
    if (!this.tracking || !this.tracking.trackedAt) return false;
    const now = new Date();
    const tracked = new Date(this.tracking.trackedAt);
    const diffMinutes = (now.getTime() - tracked.getTime()) / (1000 * 60);
    return diffMinutes <= 5; // Consider recent if within 5 minutes
  }

  refreshTracking(): void {
    this.loadTrackingData();
    this.snackBar.open('Tracking data refreshed', 'Close', { duration: 2000 });
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ASSIGNED': return 'primary';
      case 'ACCEPTED': return 'accent';
      case 'PICKED_UP': return 'primary';
      case 'IN_TRANSIT': return 'accent';
      case 'DELIVERED': return 'primary';
      default: return 'basic';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'ASSIGNED': return 'assignment';
      case 'ACCEPTED': return 'check_circle';
      case 'PICKED_UP': return 'shopping_cart';
      case 'IN_TRANSIT': return 'local_shipping';
      case 'DELIVERED': return 'check_circle_outline';
      default: return 'help';
    }
  }

  formatTime(date: Date | string | null | undefined): string {
    if (!date) return 'N/A';
    return new Date(date).toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  formatDistance(distance?: number): string {
    if (!distance) return 'N/A';
    if (distance < 1) {
      return `${Math.round(distance * 1000)}m`;
    }
    return `${distance.toFixed(1)}km`;
  }

  formatSpeed(speed?: number): string {
    if (!speed) return 'N/A';
    return `${Math.round(speed)}km/h`;
  }

  formatEarnings(amount: number): string {
    return `₹${amount.toFixed(2)}`;
  }

  getVehicleIcon(vehicleType?: string): string {
    switch (vehicleType?.toUpperCase()) {
      case 'BIKE': return 'motorcycle';
      case 'SCOOTER': return 'electric_scooter';
      case 'BICYCLE': return 'pedal_bike';
      case 'CAR': return 'directions_car';
      case 'AUTO': return 'local_taxi';
      default: return 'directions';
    }
  }

  getBatteryIcon(level?: number): string {
    if (!level) return 'battery_unknown';
    if (level > 80) return 'battery_full';
    if (level > 60) return 'battery_6_bar';
    if (level > 40) return 'battery_4_bar';
    if (level > 20) return 'battery_2_bar';
    return 'battery_alert';
  }

  getBatteryColor(level?: number): string {
    if (!level) return 'gray';
    if (level > 20) return 'green';
    return 'red';
  }

  callPartner(): void {
    if (this.assignment?.partnerPhone) {
      window.open(`tel:${this.assignment.partnerPhone}`);
    }
  }

  shareLocation(): void {
    if (navigator.share && this.assignmentId) {
      navigator.share({
        title: 'Order Tracking',
        text: `Track my order #${this.assignment?.orderNumber}`,
        url: window.location.href
      }).catch(console.error);
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(window.location.href).then(() => {
        this.snackBar.open('Tracking link copied to clipboard', 'Close', { duration: 3000 });
      });
    }
  }

  // Google Maps Integration Methods
  private initializeMap(): void {
    if (!this.mapContainer) return;

    const mapOptions: MapOptions = {
      center: this.mapCenter,
      zoom: this.mapZoom
    };

    this.googleMapsService.initializeMap(this.mapContainer.nativeElement, mapOptions)
      .subscribe({
        next: (map) => {
          this.map = map;
          this.isMapLoaded = true;
          this.addInitialMarkers();
        },
        error: (error) => {
          console.error('Error initializing map:', error);
          this.snackBar.open('Error loading map', 'Close', { duration: 3000 });
        }
      });
  }

  private addInitialMarkers(): void {
    if (!this.isMapLoaded) return;

    // Add delivery location marker
    this.addDeliveryLocationMarker();

    // Add partner location if available
    if (this.partnerLocation) {
      this.addPartnerLocationMarker();
    }
  }

  private addDeliveryLocationMarker(): void {
    if (!this.isMapLoaded || !this.deliveryLocation) return;

    const deliveryMarker: MapMarker = {
      id: 'delivery-location',
      position: this.deliveryLocation,
      title: 'Delivery Location',
      icon: this.googleMapsService.getCustomerIcon(),
      info: `
        <div style="padding: 10px;">
          <h3 style="margin: 0 0 10px 0;">Delivery Address</h3>
          <p style="margin: 0;">${this.assignment?.deliveryAddress || 'Delivery Location'}</p>
        </div>
      `
    };

    this.googleMapsService.addMarker(deliveryMarker);
  }

  private addPartnerLocationMarker(): void {
    if (!this.isMapLoaded || !this.partnerLocation) return;

    const partnerMarker: MapMarker = {
      id: 'partner-location',
      position: this.partnerLocation,
      title: 'Delivery Partner',
      icon: this.googleMapsService.getDeliveryPartnerIcon(),
      info: `
        <div style="padding: 10px;">
          <h3 style="margin: 0 0 10px 0;">${this.assignment?.partnerName || 'Delivery Partner'}</h3>
          <p style="margin: 5px 0;"><strong>Phone:</strong> ${this.assignment?.partnerPhone || 'N/A'}</p>
          <p style="margin: 5px 0;"><strong>Vehicle:</strong> N/A</p>
        </div>
      `
    };

    this.googleMapsService.addMarker(partnerMarker);
  }

  private startLiveTracking(): void {
    if (!this.assignment?.partnerId) return;

    this.liveTrackingService.startTracking(this.assignmentId.toString(), this.assignment.partnerId.toString())
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (location: PartnerLocation) => {
          this.currentPartnerLocation = location;
          this.updatePartnerLocationOnMap(location);
          this.updateTrackingInfo(location);
        },
        error: (error) => {
          console.error('Live tracking error:', error);
          // Fallback to regular polling
          this.startRealTimeTracking();
        }
      });
  }

  private updatePartnerLocationOnMap(location: PartnerLocation): void {
    if (!this.isMapLoaded) return;

    this.partnerLocation = { lat: location.lat, lng: location.lng };

    // Update map center to show both locations
    if (this.deliveryLocation) {
      this.googleMapsService.fitBounds([
        this.partnerLocation,
        this.deliveryLocation
      ]);
    } else {
      this.googleMapsService.setCenter(this.partnerLocation, 15);
    }

    // Calculate and show route if both locations are available
    if (this.deliveryLocation) {
      this.googleMapsService.calculateRoute({
        origin: this.partnerLocation,
        destination: this.deliveryLocation,
        travelMode: 'DRIVING'
      }).subscribe({
        next: (route) => {
          // Route is automatically displayed by the service
        },
        error: (error) => {
          console.error('Error calculating route:', error);
        }
      });
    }
  }

  private updateTrackingInfo(location: PartnerLocation): void {
    this.lastUpdateTime = new Date(location.timestamp);
    this.isTrackingActive = true;

    // Update tracking object with live data
    if (this.tracking) {
      this.tracking.latitude = location.lat;
      this.tracking.longitude = location.lng;
      this.tracking.trackedAt = location.timestamp;
      this.tracking.speed = location.speed;
    }
  }

  // Enhanced tracking status methods
  getTrackingStatusText(): string {
    if (!this.isTrackingActive) return 'Tracking Offline';
    if (!this.currentPartnerLocation) return 'Waiting for Location';
    
    const timeDiff = Date.now() - new Date(this.currentPartnerLocation.timestamp).getTime();
    const minutesAgo = Math.floor(timeDiff / (1000 * 60));
    
    if (minutesAgo < 1) return 'Live Tracking';
    if (minutesAgo < 5) return `Updated ${minutesAgo}m ago`;
    return 'Location Outdated';
  }

  getTrackingStatusColor(): string {
    if (!this.isTrackingActive) return 'warn';
    if (!this.currentPartnerLocation) return 'basic';
    
    const timeDiff = Date.now() - new Date(this.currentPartnerLocation.timestamp).getTime();
    const minutesAgo = Math.floor(timeDiff / (1000 * 60));
    
    if (minutesAgo < 2) return 'primary';
    if (minutesAgo < 5) return 'accent';
    return 'warn';
  }

  getCurrentSpeed(): string {
    if (this.currentPartnerLocation?.speed) {
      return `${Math.round(this.currentPartnerLocation.speed)} km/h`;
    }
    return this.formatSpeed(this.tracking?.speed);
  }

  getEstimatedArrival(): string {
    if (!this.currentPartnerLocation || !this.deliveryLocation) return 'Calculating...';
    
    const distance = this.googleMapsService.calculateDistance(
      { lat: this.currentPartnerLocation.lat, lng: this.currentPartnerLocation.lng },
      this.deliveryLocation
    );
    
    const avgSpeed = this.currentPartnerLocation.speed || 30; // Default 30 km/h
    const timeHours = distance / avgSpeed;
    const timeMinutes = Math.round(timeHours * 60);
    
    if (timeMinutes < 1) return 'Arriving now';
    if (timeMinutes < 60) return `${timeMinutes} minutes`;
    return `${Math.floor(timeMinutes / 60)}h ${timeMinutes % 60}m`;
  }

  // Location Permission and User Location Tracking
  private async requestLocationPermission(): Promise<void> {
    try {
      this.isLocationPermissionGranted = await this.googleMapsService.requestLocationPermission();
      if (this.isLocationPermissionGranted) {
        this.startLocationTracking();
      }
    } catch (error) {
      console.warn('Location permission not granted:', error);
      this.snackBar.open('Location access not available', 'Close', { duration: 3000 });
    }
  }

  private startLocationTracking(): void {
    if (!this.isLocationPermissionGranted) return;

    this.locationWatchId = this.googleMapsService.watchPosition(
      (location: MapLocation) => {
        this.userLocation = location;
        this.updateUserLocationOnMap();
      },
      (error: string) => {
        console.error('Location tracking error:', error);
      }
    );
  }

  private updateUserLocationOnMap(): void {
    if (!this.isMapLoaded || !this.userLocation) return;

    // Add or update user location marker
    const userMarker: MapMarker = {
      id: 'user-location',
      position: this.userLocation,
      title: 'Your Location',
      icon: {
        url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
          <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
            <circle cx="16" cy="16" r="8" fill="#4285f4" stroke="#ffffff" stroke-width="4"/>
            <circle cx="16" cy="16" r="3" fill="#ffffff"/>
          </svg>
        `),
        scaledSize: { width: 32, height: 32 },
        anchor: { x: 16, y: 16 }
      },
      info: `
        <div style="padding: 10px;">
          <h3 style="margin: 0 0 10px 0;">Your Location</h3>
          <p style="margin: 0;">Current position</p>
        </div>
      `
    };

    this.googleMapsService.addMarker(userMarker);

    // Update map bounds to include user location if needed
    if (this.deliveryLocation || this.partnerLocation) {
      const locations = [this.userLocation];
      if (this.deliveryLocation) locations.push(this.deliveryLocation);
      if (this.partnerLocation) locations.push(this.partnerLocation);
      this.googleMapsService.fitBounds(locations);
    }
  }

  // Enhanced Navigation Features
  toggleDirections(): void {
    this.showDirections = !this.showDirections;
    
    if (this.showDirections && this.userLocation && this.deliveryLocation) {
      this.getDirectionsToDelivery();
    } else {
      this.googleMapsService.clearRoute();
    }
  }

  private getDirectionsToDelivery(): void {
    if (!this.userLocation || !this.deliveryLocation) return;

    this.googleMapsService.calculateDetailedRoute({
      origin: this.userLocation,
      destination: this.deliveryLocation,
      travelMode: 'DRIVING'
    }).subscribe({
      next: (route) => {
        this.snackBar.open(
          `Route calculated: ${route.distance.text}, ${route.duration.text}`, 
          'Close', 
          { duration: 5000 }
        );
      },
      error: (error) => {
        console.error('Failed to calculate route:', error);
        this.snackBar.open('Failed to calculate directions', 'Close', { duration: 3000 });
      }
    });
  }

  getDirectionsToLocation(): void {
    if (!this.userLocation || !this.deliveryLocation) {
      this.snackBar.open('Location not available for directions', 'Close', { duration: 3000 });
      return;
    }

    // Open Google Maps with directions
    const directionsUrl = `https://www.google.com/maps/dir/${this.userLocation.lat},${this.userLocation.lng}/${this.deliveryLocation.lat},${this.deliveryLocation.lng}`;
    window.open(directionsUrl, '_blank');
  }

  centerMapOnUser(): void {
    if (this.userLocation && this.isMapLoaded) {
      this.googleMapsService.setCenter(this.userLocation, 16);
    } else {
      this.snackBar.open('Your location is not available', 'Close', { duration: 3000 });
    }
  }

  // Places Integration
  async searchNearbyPlaces(type: string): Promise<void> {
    if (!this.deliveryLocation) {
      this.snackBar.open('Delivery location not available', 'Close', { duration: 3000 });
      return;
    }

    try {
      const places = await this.googleMapsService.searchNearbyPlaces(this.deliveryLocation, 1000, type);
      
      // Add markers for nearby places
      places.slice(0, 5).forEach((place, index) => {
        const marker: MapMarker = {
          id: `nearby-${type}-${index}`,
          position: {
            lat: place.geometry.location.lat(),
            lng: place.geometry.location.lng()
          },
          title: place.name,
          icon: this.getPlaceTypeIcon(type),
          info: `
            <div style="padding: 10px;">
              <h3 style="margin: 0 0 10px 0;">${place.name}</h3>
              <p style="margin: 0 0 5px 0;">${place.vicinity}</p>
              <p style="margin: 0; font-size: 12px; color: #666;">
                Rating: ${place.rating || 'N/A'} ⭐
              </p>
            </div>
          `
        };
        this.googleMapsService.addMarker(marker);
      });

      this.snackBar.open(`Found ${places.length} nearby ${type}s`, 'Close', { duration: 3000 });
    } catch (error) {
      console.error('Failed to search nearby places:', error);
      this.snackBar.open(`Failed to find nearby ${type}s`, 'Close', { duration: 3000 });
    }
  }

  private getPlaceTypeIcon(type: string): any {
    const iconColors: { [key: string]: string } = {
      restaurant: '#ff5722',
      hospital: '#f44336',
      gas_station: '#ffeb3b',
      atm: '#4caf50',
      pharmacy: '#2196f3'
    };

    const color = iconColors[type] || '#9e9e9e';
    
    return {
      url: `https://maps.google.com/mapfiles/ms/icons/${type === 'restaurant' ? 'restaurant' : 'blue'}-dot.png`,
      scaledSize: { width: 32, height: 32 },
      origin: { x: 0, y: 0 },
      anchor: { x: 16, y: 32 }
    };
  }

  // Distance calculations with user location
  getDistanceToDelivery(): string {
    if (!this.userLocation || !this.deliveryLocation) return 'N/A';
    
    const distance = this.googleMapsService.calculateDistance(this.userLocation, this.deliveryLocation);
    return this.formatDistance(distance);
  }

  getDistanceToPartner(): string {
    if (!this.userLocation || !this.partnerLocation) return 'N/A';
    
    const distance = this.googleMapsService.calculateDistance(this.userLocation, this.partnerLocation);
    return this.formatDistance(distance);
  }

  // Location status methods
  getLocationStatusText(): string {
    if (!this.isLocationPermissionGranted) return 'Location access denied';
    if (!this.userLocation) return 'Getting your location...';
    return 'Location active';
  }

  getLocationStatusColor(): string {
    if (!this.isLocationPermissionGranted) return 'warn';
    if (!this.userLocation) return 'accent';
    return 'primary';
  }

  // Computed properties to avoid complex template expressions
  get remainingDistance(): string {
    if (!this.partnerLocation || !this.deliveryLocation) return 'N/A';
    const distance = this.googleMapsService.calculateDistance(this.partnerLocation, this.deliveryLocation);
    return this.formatDistance(distance);
  }

  get distanceToDelivery(): string {
    return this.getDistanceToDelivery();
  }

  get distanceToPartner(): string {
    return this.getDistanceToPartner();
  }

  get currentSpeed(): string {
    return this.getCurrentSpeed();
  }

  get estimatedArrival(): string {
    return this.getEstimatedArrival();
  }

  get trackingStatusText(): string {
    return this.getTrackingStatusText();
  }

  get trackingStatusColor(): string {
    return this.getTrackingStatusColor();
  }

  get locationStatusText(): string {
    return this.getLocationStatusText();
  }

  get locationStatusColor(): string {
    return this.getLocationStatusColor();
  }
}