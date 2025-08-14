import { Component, Input, OnInit, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
import { Shop } from '../../../../core/models/shop.model';
import { GoogleMapsService } from '../../../../core/services/google-maps.service';

@Component({
  selector: 'app-shop-map',
  template: `
    <div class="map-container">
      <div class="map-header" *ngIf="shops.length > 0">
        <h3>Shop Locations ({{shops.length}} shops)</h3>
        <div class="map-controls">
          <button mat-icon-button (click)="fitBounds()" matTooltip="Fit all shops">
            <mat-icon>zoom_out_map</mat-icon>
          </button>
          <button mat-icon-button (click)="toggleMapType()" matTooltip="Toggle map type">
            <mat-icon>layers</mat-icon>
          </button>
        </div>
      </div>
      
      <div #mapContainer class="map" [style.height]="mapHeight"></div>
      
      <div class="map-legend" *ngIf="shops.length > 0">
        <div class="legend-item">
          <div class="legend-marker grocery"></div>
          <span>Grocery</span>
        </div>
        <div class="legend-item">
          <div class="legend-marker pharmacy"></div>
          <span>Pharmacy</span>
        </div>
        <div class="legend-item">
          <div class="legend-marker restaurant"></div>
          <span>Restaurant</span>
        </div>
        <div class="legend-item">
          <div class="legend-marker general"></div>
          <span>General</span>
        </div>
      </div>

      <div class="no-locations" *ngIf="shops.length === 0">
        <mat-icon>location_off</mat-icon>
        <p>No shop locations to display</p>
      </div>
    </div>
  `,
  styles: [`
    .map-container {
      width: 100%;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .map-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px 20px;
      background-color: #f5f5f5;
      border-bottom: 1px solid #ddd;
    }

    .map-header h3 {
      margin: 0;
      color: #333;
    }

    .map-controls {
      display: flex;
      gap: 5px;
    }

    .map {
      width: 100%;
      min-height: 400px;
    }

    .map-legend {
      display: flex;
      justify-content: center;
      gap: 20px;
      padding: 15px;
      background-color: #f9f9f9;
      border-top: 1px solid #ddd;
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
    }

    .legend-marker {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid white;
      box-shadow: 0 1px 3px rgba(0,0,0,0.3);
    }

    .legend-marker.grocery { background-color: #4CAF50; }
    .legend-marker.pharmacy { background-color: #2196F3; }
    .legend-marker.restaurant { background-color: #FF9800; }
    .legend-marker.general { background-color: #9C27B0; }

    .no-locations {
      text-align: center;
      padding: 60px 20px;
      color: #666;
    }

    .no-locations mat-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      color: #ccc;
      margin-bottom: 10px;
    }
  `]
})
export class ShopMapComponent implements OnInit, AfterViewInit {
  @Input() shops: Shop[] = [];
  @Input() mapHeight = '400px';
  @ViewChild('mapContainer', { static: false }) mapContainer!: ElementRef;

  private map: google.maps.Map | null = null;
  private markers: google.maps.Marker[] = [];
  private mapType: google.maps.MapTypeId = google.maps.MapTypeId.ROADMAP;

  constructor(private mapsService: GoogleMapsService) {}

  ngOnInit() {
    this.mapsService.loadGoogleMaps().then(() => {
      // Maps API loaded
    }).catch(error => {
      console.error('Error loading Google Maps:', error);
    });
  }

  ngAfterViewInit() {
    setTimeout(() => {
      this.initializeMap();
    }, 100);
  }

  private initializeMap() {
    if (!this.mapContainer) return;

    const defaultCenter = { lat: 20.5937, lng: 78.9629 }; // Center of India
    
    this.map = this.mapsService.createMap(this.mapContainer.nativeElement, {
      center: defaultCenter,
      zoom: 5,
      mapTypeId: this.mapType
    });

    this.addMarkersToMap();
  }

  private addMarkersToMap() {
    if (!this.map) return;

    // Clear existing markers
    this.clearMarkers();

    const bounds = new google.maps.LatLngBounds();
    let hasValidLocations = false;

    this.shops.forEach(shop => {
      if (shop.latitude && shop.longitude) {
        const marker = this.createShopMarker(shop);
        this.markers.push(marker);
        bounds.extend(new google.maps.LatLng(shop.latitude, shop.longitude));
        hasValidLocations = true;
      }
    });

    if (hasValidLocations && this.markers.length > 1) {
      this.map.fitBounds(bounds);
    } else if (hasValidLocations && this.markers.length === 1) {
      this.map.setCenter(bounds.getCenter());
      this.map.setZoom(15);
    }
  }

  private createShopMarker(shop: Shop): google.maps.Marker {
    const position = { lat: shop.latitude!, lng: shop.longitude! };
    
    const marker = this.mapsService.createMarker({
      position,
      map: this.map!,
      title: shop.name,
      icon: this.getMarkerIcon(shop.businessType)
    });

    const infoWindow = this.mapsService.createInfoWindow({
      content: this.createInfoWindowContent(shop)
    });

    marker.addListener('click', () => {
      infoWindow.open(this.map!, marker);
    });

    return marker;
  }

  private getMarkerIcon(businessType: string): google.maps.Icon {
    const colors = {
      'GROCERY': '#4CAF50',
      'PHARMACY': '#2196F3', 
      'RESTAURANT': '#FF9800',
      'GENERAL': '#9C27B0'
    };

    const color = colors[businessType] || colors['GENERAL'];
    
    return {
      path: google.maps.SymbolPath.CIRCLE,
      scale: 8,
      fillColor: color,
      fillOpacity: 1,
      strokeColor: '#ffffff',
      strokeWeight: 2
    } as google.maps.Icon;
  }

  private createInfoWindowContent(shop: Shop): string {
    return `
      <div style="max-width: 250px; padding: 10px;">
        <h4 style="margin: 0 0 10px 0; color: #333;">${shop.name}</h4>
        <p style="margin: 5px 0; color: #666; font-size: 14px;">
          <strong>Type:</strong> ${shop.businessType}
        </p>
        <p style="margin: 5px 0; color: #666; font-size: 14px;">
          <strong>Address:</strong> ${shop.addressLine1}, ${shop.city}
        </p>
        <p style="margin: 5px 0; color: #666; font-size: 14px;">
          <strong>Phone:</strong> ${shop.ownerPhone}
        </p>
        <p style="margin: 5px 0; color: #666; font-size: 14px;">
          <strong>Rating:</strong> ⭐ ${shop.rating}/5 (${shop.totalOrders} orders)
        </p>
        <div style="margin-top: 10px;">
          <button onclick="window.open('https://maps.google.com/maps?daddr=${shop.latitude},${shop.longitude}', '_blank')" 
                  style="padding: 5px 10px; background: #1976d2; color: white; border: none; border-radius: 4px; cursor: pointer;">
            Get Directions
          </button>
        </div>
      </div>
    `;
  }

  private clearMarkers() {
    this.markers.forEach(marker => marker.setMap(null));
    this.markers = [];
  }

  fitBounds() {
    if (!this.map || this.markers.length === 0) return;

    const bounds = new google.maps.LatLngBounds();
    this.markers.forEach(marker => {
      bounds.extend(marker.getPosition()!);
    });

    this.map.fitBounds(bounds);
  }

  toggleMapType() {
    if (!this.map) return;

    this.mapType = this.mapType === google.maps.MapTypeId.ROADMAP 
      ? google.maps.MapTypeId.SATELLITE 
      : google.maps.MapTypeId.ROADMAP;
      
    this.map.setMapTypeId(this.mapType);
  }

  // Called when shops input changes
  ngOnChanges() {
    if (this.map) {
      this.addMarkersToMap();
    }
  }
}