import { Component, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil, interval } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderService, OrderTrackingInfo } from '../../services/order.service';
import { FirebaseService } from '../../../../core/services/firebase.service';
import { environment } from '../../../../../environments/environment';

declare var google: any;

@Component({
  selector: 'app-order-tracking',
  templateUrl: './order-tracking.component.html',
  styleUrls: ['./order-tracking.component.scss']
})
export class OrderTrackingComponent implements OnInit, OnDestroy, AfterViewInit {
  private destroy$ = new Subject<void>();
  private map: any;
  private deliveryMarker: any;
  private destinationMarker: any;
  
  orderTracking: OrderTrackingInfo | null = null;
  loading = false;
  mapLoaded = false;
  orderNumber: string = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private orderService: OrderService,
    private firebaseService: FirebaseService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.route.params.pipe(takeUntil(this.destroy$)).subscribe(params => {
      this.orderNumber = params['orderNumber'];
      this.loadOrderTracking();
    });

    // Auto-refresh tracking every 30 seconds
    interval(30000).pipe(takeUntil(this.destroy$)).subscribe(() => {
      if (this.orderTracking && this.canAutoRefresh()) {
        this.refreshTracking();
      }
    });

    // Listen to Firebase notifications
    this.firebaseService.receiveMessage().pipe(takeUntil(this.destroy$)).subscribe(
      payload => {
        if (payload && payload.data?.orderNumber === this.orderNumber) {
          this.refreshTracking();
        }
      }
    );
  }

  ngAfterViewInit(): void {
    this.loadGoogleMaps();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadOrderTracking(): void {
    this.loading = true;
    this.orderService.getOrderTracking(this.orderNumber)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (tracking) => {
          const previousStatus = this.orderTracking?.status;
          this.orderTracking = tracking;
          this.loading = false;
          
          // Send notification if status changed
          if (previousStatus && previousStatus !== tracking.status) {
            this.firebaseService.sendOrderNotification(
              tracking.orderNumber,
              tracking.status,
              this.getStatusMessage(tracking.status)
            );
          }
          
          if (this.map) {
            this.updateMapMarkers();
          }
        },
        error: (error) => {
          console.error('Error loading order tracking:', error);
          this.loading = false;
          this.snackBar.open('Failed to load order tracking', 'Close', {
            duration: 3000
          });
        }
      });
  }

  private getStatusMessage(status: string): string {
    switch (status) {
      case 'CONFIRMED':
        return 'Your order has been confirmed by the restaurant';
      case 'PREPARING':
        return 'Your order is being prepared';
      case 'READY_FOR_PICKUP':
        return 'Your order is ready for pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Your delivery partner is on the way';
      case 'DELIVERED':
        return 'Your order has been delivered successfully';
      default:
        return 'Order status updated';
    }
  }

  refreshTracking(): void {
    this.loadOrderTracking();
  }

  private loadGoogleMaps(): void {
    if (typeof google !== 'undefined') {
      this.initializeMap();
    } else {
      // Load Google Maps script
      const script = document.createElement('script');
      script.src = `https://maps.googleapis.com/maps/api/js?key=${environment.googleMapsApiKey}&libraries=geometry`;
      script.onload = () => {
        this.initializeMap();
      };
      script.onerror = () => {
        console.error('Failed to load Google Maps');
        this.mapLoaded = false;
      };
      document.head.appendChild(script);
    }
  }

  private initializeMap(): void {
    const mapElement = document.getElementById('delivery-map');
    if (!mapElement) return;

    // Chennai center coordinates
    const chennaiCenter = { lat: 12.9716, lng: 77.5946 };

    this.map = new google.maps.Map(mapElement, {
      zoom: 13,
      center: chennaiCenter,
      styles: [
        {
          featureType: 'poi',
          elementType: 'labels',
          stylers: [{ visibility: 'off' }]
        }
      ]
    });

    this.mapLoaded = true;
    if (this.orderTracking) {
      this.updateMapMarkers();
    }
  }

  private updateMapMarkers(): void {
    if (!this.map || !this.orderTracking) return;

    // Clear existing markers
    if (this.deliveryMarker) {
      this.deliveryMarker.setMap(null);
    }
    if (this.destinationMarker) {
      this.destinationMarker.setMap(null);
    }

    // Add delivery partner marker
    if (this.orderTracking.currentLocation) {
      this.deliveryMarker = new google.maps.Marker({
        position: this.orderTracking.currentLocation,
        map: this.map,
        title: 'Delivery Partner',
        icon: {
          url: '/assets/icons/delivery-bike.png',
          scaledSize: new google.maps.Size(40, 40)
        }
      });
    }

    // Add destination marker (mock customer location)
    const customerLocation = { lat: 12.9716 + 0.01, lng: 77.5946 + 0.01 };
    this.destinationMarker = new google.maps.Marker({
      position: customerLocation,
      map: this.map,
      title: 'Delivery Address',
      icon: {
        url: '/assets/icons/home-marker.png',
        scaledSize: new google.maps.Size(40, 40)
      }
    });

    // Fit map to show both markers
    const bounds = new google.maps.LatLngBounds();
    if (this.orderTracking.currentLocation) {
      bounds.extend(this.orderTracking.currentLocation);
    }
    bounds.extend(customerLocation);
    this.map.fitBounds(bounds);
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'PLACED':
        return 'bg-secondary';
      case 'CONFIRMED':
        return 'bg-info';
      case 'PREPARING':
        return 'bg-warning';
      case 'READY_FOR_PICKUP':
        return 'bg-primary';
      case 'OUT_FOR_DELIVERY':
        return 'bg-warning';
      case 'DELIVERED':
        return 'bg-success';
      case 'CANCELLED':
        return 'bg-danger';
      default:
        return 'bg-secondary';
    }
  }

  getStatusDisplayText(status: string): string {
    switch (status) {
      case 'PLACED':
        return 'Order Placed';
      case 'CONFIRMED':
        return 'Order Confirmed';
      case 'PREPARING':
        return 'Preparing Order';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  formatTime(timestamp: string): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  }

  canCancelOrder(): boolean {
    if (!this.orderTracking) return false;
    return ['PLACED', 'CONFIRMED', 'PREPARING'].includes(this.orderTracking.status);
  }

  private canAutoRefresh(): boolean {
    if (!this.orderTracking) return false;
    return !['DELIVERED', 'CANCELLED'].includes(this.orderTracking.status);
  }

  cancelOrder(): void {
    if (!this.orderTracking || !this.canCancelOrder()) return;

    const reason = prompt('Please provide a reason for cancellation:');
    if (reason) {
      this.orderService.cancelOrder(this.orderTracking.orderId, reason)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            this.snackBar.open('Order cancelled successfully', 'Close', {
              duration: 3000
            });
            this.refreshTracking();
          },
          error: (error) => {
            console.error('Error cancelling order:', error);
            this.snackBar.open('Failed to cancel order', 'Close', {
              duration: 3000
            });
          }
        });
    }
  }

  contactSupport(): void {
    window.open('tel:+919876543210', '_self');
  }

  goToShops(): void {
    this.router.navigate(['/customer/shops']);
  }
}
