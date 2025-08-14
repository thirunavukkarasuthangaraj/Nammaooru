import { 
  Component, 
  OnInit, 
  OnDestroy, 
  Input, 
  Output, 
  EventEmitter, 
  ElementRef, 
  ViewChild, 
  AfterViewInit 
} from '@angular/core';
import { GoogleMapsService, MapLocation } from '@core/services/google-maps.service';

@Component({
  selector: 'app-location-picker',
  template: `
    <div class="location-picker">
      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Search Location</mat-label>
        <input 
          matInput 
          #searchInput 
          placeholder="Enter address or place name"
          [value]="searchValue"
          (input)="onSearchInput($event)">
        <mat-icon matSuffix>search</mat-icon>
      </mat-form-field>

      <div class="map-container" [style.height.px]="height">
        <div #mapElement class="map-element"></div>
        
        <div class="map-loading" *ngIf="isLoading">
          <mat-spinner diameter="40"></mat-spinner>
          <p>Loading map...</p>
        </div>
      </div>

      <div class="location-info" *ngIf="selectedLocation">
        <mat-card>
          <mat-card-content>
            <h4>Selected Location</h4>
            <p><strong>Coordinates:</strong> {{selectedLocation.lat | number:'1.6-6'}}, {{selectedLocation.lng | number:'1.6-6'}}</p>
            <p *ngIf="selectedLocation.address"><strong>Address:</strong> {{selectedLocation.address}}</p>
            
            <div class="location-actions">
              <button mat-button color="primary" (click)="getCurrentLocation()">
                <mat-icon>my_location</mat-icon>
                Use Current Location
              </button>
              <button mat-button color="warn" (click)="clearSelection()">
                <mat-icon>clear</mat-icon>
                Clear
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .location-picker {
      width: 100%;
    }

    .map-container {
      position: relative;
      width: 100%;
      border-radius: 8px;
      overflow: hidden;
      margin: 16px 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .map-element {
      width: 100%;
      height: 100%;
    }

    .map-loading {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      background: rgba(255, 255, 255, 0.9);
      z-index: 10;
    }

    .map-loading p {
      margin-top: 16px;
      color: #666;
    }

    .location-info {
      margin-top: 16px;
    }

    .location-info h4 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .location-info p {
      margin: 4px 0;
      font-size: 14px;
      color: #666;
    }

    .location-actions {
      margin-top: 16px;
      display: flex;
      gap: 8px;
    }

    .location-actions button {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    @media (max-width: 768px) {
      .location-actions {
        flex-direction: column;
      }

      .location-actions button {
        width: 100%;
        justify-content: center;
      }
    }
  `]
})
export class LocationPickerComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('mapElement') mapElement!: ElementRef;
  @ViewChild('searchInput') searchInput!: ElementRef<HTMLInputElement>;
  
  @Input() height = 400;
  @Input() initialLocation?: MapLocation;
  @Input() zoom = 13;
  @Input() searchValue = '';
  
  @Output() locationSelected = new EventEmitter<MapLocation>();
  @Output() locationCleared = new EventEmitter<void>();

  map?: google.maps.Map;
  marker?: google.maps.Marker;
  autocomplete?: google.maps.places.Autocomplete;
  selectedLocation?: MapLocation;
  isLoading = true;

  private readonly defaultLocation: MapLocation = {
    lat: 13.0827, // Chennai
    lng: 80.2707
  };

  constructor(private googleMapsService: GoogleMapsService) {}

  ngOnInit(): void {
    this.selectedLocation = this.initialLocation;
  }

  ngAfterViewInit(): void {
    this.initializeMap();
  }

  ngOnDestroy(): void {
    if (this.marker) {
      this.marker.setMap(null);
    }
  }

  private async initializeMap(): Promise<void> {
    try {
      await this.googleMapsService.loadMaps().toPromise();
      
      const center = this.initialLocation || this.defaultLocation;
      
      this.map = this.googleMapsService.createMap(this.mapElement.nativeElement, {
        center: { lat: center.lat, lng: center.lng },
        zoom: this.zoom,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        streetViewControl: false,
        mapTypeControl: true,
        fullscreenControl: true
      });

      // Add click listener to map
      this.map.addListener('click', (event: google.maps.MapMouseEvent) => {
        if (event.latLng) {
          this.selectLocation({
            lat: event.latLng.lat(),
            lng: event.latLng.lng()
          });
        }
      });

      // Initialize autocomplete
      if (this.searchInput) {
        this.initializeAutocomplete();
      }

      // Set initial marker if location provided
      if (this.initialLocation) {
        this.addMarker(this.initialLocation);
      }

      this.isLoading = false;
    } catch (error) {
      console.error('Failed to initialize map:', error);
      this.isLoading = false;
    }
  }

  private initializeAutocomplete(): void {
    if (!this.searchInput?.nativeElement) return;

    this.autocomplete = this.googleMapsService.createAutocomplete(
      this.searchInput.nativeElement,
      { types: ['establishment', 'geocode'] }
    );

    this.autocomplete.addListener('place_changed', () => {
      const place = this.autocomplete?.getPlace();
      if (place?.geometry?.location) {
        const location: MapLocation = {
          lat: place.geometry.location.lat(),
          lng: place.geometry.location.lng(),
          address: place.formatted_address || place.name
        };
        
        this.selectLocation(location);
        this.map?.setCenter(location);
        this.map?.setZoom(15);
      }
    });
  }

  private async selectLocation(location: MapLocation): Promise<void> {
    try {
      // Get address if not provided
      if (!location.address) {
        location.address = await this.googleMapsService.reverseGeocode(location.lat, location.lng) || undefined;
      }

      this.selectedLocation = location;
      this.addMarker(location);
      this.locationSelected.emit(location);
    } catch (error) {
      console.error('Error selecting location:', error);
      this.selectedLocation = location;
      this.addMarker(location);
      this.locationSelected.emit(location);
    }
  }

  private addMarker(location: MapLocation): void {
    if (this.marker) {
      this.marker.setMap(null);
    }

    this.marker = this.googleMapsService.createMarker({
      position: { lat: location.lat, lng: location.lng },
      map: this.map,
      draggable: true,
      title: location.address || 'Selected Location'
    });

    // Add drag listener to marker
    this.marker.addListener('dragend', () => {
      if (this.marker) {
        const position = this.marker.getPosition();
        if (position) {
          this.selectLocation({
            lat: position.lat(),
            lng: position.lng()
          });
        }
      }
    });

    // Create info window
    const infoWindow = this.googleMapsService.createInfoWindow({
      content: location.address || `Lat: ${location.lat}, Lng: ${location.lng}`
    });

    this.marker.addListener('click', () => {
      infoWindow.open(this.map, this.marker);
    });
  }

  async getCurrentLocation(): Promise<void> {
    try {
      this.isLoading = true;
      const location = await this.googleMapsService.getCurrentLocation();
      
      this.selectLocation(location);
      this.map?.setCenter(location);
      this.map?.setZoom(15);
      
      this.isLoading = false;
    } catch (error) {
      console.error('Error getting current location:', error);
      this.isLoading = false;
    }
  }

  clearSelection(): void {
    this.selectedLocation = undefined;
    this.searchValue = '';
    
    if (this.marker) {
      this.marker.setMap(null);
      this.marker = undefined;
    }

    if (this.searchInput?.nativeElement) {
      this.searchInput.nativeElement.value = '';
    }

    this.locationCleared.emit();
  }

  onSearchInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.searchValue = target.value;
  }
}