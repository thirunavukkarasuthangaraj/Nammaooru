import { Component, OnInit, OnDestroy, ViewChild, ElementRef, Input, Output, EventEmitter, forwardRef } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { GoogleMapsService, MapLocation } from '../../../core/services/google-maps.service';

export interface PlaceResult {
  placeId: string;
  formattedAddress: string;
  name: string;
  location: MapLocation;
  types: string[];
}

@Component({
  selector: 'app-places-autocomplete',
  templateUrl: './places-autocomplete.component.html',
  styleUrls: ['./places-autocomplete.component.scss'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => PlacesAutocompleteComponent),
      multi: true
    }
  ]
})
export class PlacesAutocompleteComponent implements OnInit, OnDestroy, ControlValueAccessor {
  @ViewChild('addressInput', { static: true }) addressInput!: ElementRef<HTMLInputElement>;
  
  @Input() placeholder: string = 'Enter address';
  @Input() types: string[] = ['establishment'];
  @Input() componentRestrictions: any = { country: 'in' }; // Restrict to India
  @Input() disabled: boolean = false;
  @Input() required: boolean = false;
  @Input() label: string = 'Address';
  @Input() biasToCurrentLocation: boolean = true;
  @Input() strictBounds: boolean = false;

  @Output() placeSelected = new EventEmitter<PlaceResult>();
  @Output() placeChanged = new EventEmitter<PlaceResult | null>();

  private autocomplete: any;
  private autocompleteListener: any;
  
  value: string = '';
  selectedPlace: PlaceResult | null = null;

  // ControlValueAccessor
  private onChange = (value: any) => {};
  private onTouched = () => {};

  constructor(private googleMapsService: GoogleMapsService) {}

  ngOnInit(): void {
    this.initializeAutocomplete();
  }

  ngOnDestroy(): void {
    if (this.autocompleteListener) {
      google.maps.event.removeListener(this.autocompleteListener);
    }
  }

  private async initializeAutocomplete(): Promise<void> {
    // Wait for Google Maps to load
    this.googleMapsService.loadGoogleMaps().then(() => {
      const options: any = {
        types: this.types,
        componentRestrictions: this.componentRestrictions,
        strictBounds: this.strictBounds,
        fields: ['place_id', 'formatted_address', 'geometry', 'name', 'types']
      };

      // Get current location for biasing if enabled
      if (this.biasToCurrentLocation) {
        try {
          const currentLocation = await this.googleMapsService.getCurrentLocation();
          const circle = new google.maps.Circle({
            center: currentLocation,
            radius: 50000 // 50km radius
          });
          options.bounds = circle.getBounds();
        } catch (error) {
          console.warn('Could not get current location for autocomplete bias:', error);
        }
      }

      this.autocomplete = this.googleMapsService.createAdvancedAutocomplete(
        this.addressInput.nativeElement,
        options
      );

      if (this.autocomplete) {
        this.autocompleteListener = this.autocomplete.addListener('place_changed', () => {
          this.onPlaceChanged();
        });
      }
    }).catch(error => {
      console.error('Failed to initialize autocomplete:', error);
    });
  }

  private onPlaceChanged(): void {
    const place = this.autocomplete.getPlace();
    
    if (!place || !place.geometry) {
      // User entered a custom address that doesn't match a place
      this.selectedPlace = null;
      this.placeChanged.emit(null);
      this.onChange(this.value);
      return;
    }

    const placeResult: PlaceResult = {
      placeId: place.place_id,
      formattedAddress: place.formatted_address,
      name: place.name || place.formatted_address,
      location: {
        lat: place.geometry.location.lat(),
        lng: place.geometry.location.lng()
      },
      types: place.types || []
    };

    this.selectedPlace = placeResult;
    this.value = placeResult.formattedAddress;
    
    this.placeSelected.emit(placeResult);
    this.placeChanged.emit(placeResult);
    this.onChange(placeResult);
  }

  onInputChange(event: any): void {
    this.value = event.target.value;
    this.onTouched();
    
    // If user is typing but hasn't selected a place, clear the selected place
    if (this.selectedPlace && this.value !== this.selectedPlace.formattedAddress) {
      this.selectedPlace = null;
      this.placeChanged.emit(null);
      this.onChange(this.value);
    }
  }

  onInputFocus(): void {
    this.onTouched();
  }

  clearSelection(): void {
    this.value = '';
    this.selectedPlace = null;
    this.addressInput.nativeElement.value = '';
    this.placeChanged.emit(null);
    this.onChange('');
  }

  // Search for places by text
  async searchPlaces(query: string): Promise<PlaceResult[]> {
    try {
      const places = await this.googleMapsService.searchPlacesByText(query);
      return places.map(place => ({
        placeId: place.place_id,
        formattedAddress: place.formatted_address,
        name: place.name,
        location: {
          lat: place.geometry.location.lat(),
          lng: place.geometry.location.lng()
        },
        types: place.types || []
      }));
    } catch (error) {
      console.error('Places search failed:', error);
      return [];
    }
  }

  // Get current location and update input
  async useCurrentLocation(): Promise<void> {
    try {
      const location = await this.googleMapsService.getCurrentLocation();
      const address = await this.googleMapsService.reverseGeocode(location.lat, location.lng);
      
      if (address) {
        this.value = address;
        this.addressInput.nativeElement.value = address;
        
        const placeResult: PlaceResult = {
          placeId: 'current_location',
          formattedAddress: address,
          name: 'Current Location',
          location: location,
          types: ['current_location']
        };
        
        this.selectedPlace = placeResult;
        this.placeSelected.emit(placeResult);
        this.placeChanged.emit(placeResult);
        this.onChange(placeResult);
      }
    } catch (error) {
      console.error('Failed to get current location:', error);
      throw error;
    }
  }

  // ControlValueAccessor Implementation
  writeValue(value: any): void {
    if (value) {
      if (typeof value === 'string') {
        this.value = value;
        this.addressInput.nativeElement.value = value;
      } else if (value.formattedAddress) {
        this.value = value.formattedAddress;
        this.selectedPlace = value;
        this.addressInput.nativeElement.value = value.formattedAddress;
      }
    } else {
      this.value = '';
      this.selectedPlace = null;
      this.addressInput.nativeElement.value = '';
    }
  }

  registerOnChange(fn: any): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  // Utility method for formatting place types
  formatPlaceType(type: string): string {
    return type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
}