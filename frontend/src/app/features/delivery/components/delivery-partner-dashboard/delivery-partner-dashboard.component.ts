import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, takeUntil, interval } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DeliveryPartnerService, DeliveryPartner } from '../../services/delivery-partner.service';
import { OrderAssignmentService, OrderAssignment } from '../../services/order-assignment.service';
import { AuthService } from '../../../../core/services/auth.service';
import { GeolocationService } from '../../../../core/services/geolocation.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ApiResponseHelper } from '../../../../core/models/api-response.model';

@Component({
  selector: 'app-delivery-partner-dashboard',
  templateUrl: './delivery-partner-dashboard.component.html',
  styleUrls: ['./delivery-partner-dashboard.component.scss']
})
export class DeliveryPartnerDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  // Partner Data
  partner: DeliveryPartner | null = null;
  isLoading = true;
  
  // Dashboard Stats
  todayStats = {
    deliveries: 0,
    earnings: 0,
    rating: 0,
    hoursWorked: 0
  };
  
  // Active Orders
  activeOrders: OrderAssignment[] = [];
  availableOrders: OrderAssignment[] = [];
  
  // Status Controls
  isOnline = false;
  isAvailable = false;
  isLocationEnabled = false;
  lastLocationUpdate: Date | null = null;
  
  // UI State
  currentTab = 0;
  showEarningsDetails = false;

  constructor(
    private partnerService: DeliveryPartnerService,
    private assignmentService: OrderAssignmentService,
    private authService: AuthService,
    private geolocationService: GeolocationService,
    private snackBar: MatSnackBar,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadPartnerData();
    this.loadActiveOrders();
    this.loadAvailableOrders();
    this.startLocationTracking();
    this.setupPeriodicUpdates();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadPartnerData(): void {
    const user = this.authService.getCurrentUser();
    if (!user) {
      this.swal.toast('User not found', 'error');
      return;
    }

    this.partnerService.getPartnerByUserId(user.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.partner = response.data;
            this.isOnline = response.data.isOnline;
            this.isAvailable = response.data.isAvailable;
            this.loadTodayStats();
          } else {
            this.swal.toast('Failed to load partner data', 'error');
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading partner data:', error);
          this.swal.toast('Error loading partner data', 'error');
          this.isLoading = false;
        }
      });
  }

  private loadActiveOrders(): void {
    if (!this.partner) return;

    this.assignmentService.getActiveAssignmentsByPartner(this.partner.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.activeOrders = response.data;
          }
        },
        error: (error) => {
          console.error('Error loading active orders:', error);
        }
      });
  }

  private loadAvailableOrders(): void {
    const user = this.authService.getCurrentUser();
    if (!user) return;

    this.assignmentService.getAvailableOrdersForPartner(user.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          if (response.success && response.orders) {
            this.availableOrders = response.orders;
          }
        },
        error: (error: any) => {
          console.error('Error loading available orders:', error);
        }
      });
  }

  private loadTodayStats(): void {
    if (!this.partner) return;

    // TODO: Implement API calls for today's statistics
    this.todayStats = {
      deliveries: 5,
      earnings: 450,
      rating: 4.8,
      hoursWorked: 6.5
    };
  }

  toggleOnlineStatus(): void {
    if (!this.partner) return;

    this.partnerService.updateOnlineStatus(this.partner.id, !this.isOnline)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.isOnline = response.data.isOnline;
            this.isAvailable = response.data.isAvailable;
            
            const message = this.isOnline ? 'You are now online' : 'You are now offline';
            this.swal.toast(message, 'success');
            
            if (this.isOnline) {
              this.requestLocationPermission();
            }
          }
        },
        error: (error) => {
          console.error('Error updating online status:', error);
          this.swal.toast('Failed to update status', 'error');
        }
      });
  }

  toggleAvailability(): void {
    if (!this.partner || !this.isOnline) return;

    this.partnerService.updateAvailability(this.partner.id, !this.isAvailable)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.isAvailable = response.data.isAvailable;
            
            const message = this.isAvailable ? 'You are now available for orders' : 'You are now unavailable';
            this.swal.toast(message, 'success');
          }
        },
        error: (error) => {
          console.error('Error updating availability:', error);
          this.swal.toast('Failed to update availability', 'error');
        }
      });
  }

  private requestLocationPermission(): void {
    this.geolocationService.getCurrentPosition()
      .then((position) => {
        this.isLocationEnabled = true;
        this.updateLocation(position.coords.latitude, position.coords.longitude);
      })
      .catch((error) => {
        console.error('Error getting location:', error);
        this.snackBar.open('Location access required for delivery tracking', 'Enable', {
          duration: 5000
        }).onAction().subscribe(() => {
          this.requestLocationPermission();
        });
      });
  }

  private updateLocation(latitude: number, longitude: number): void {
    if (!this.partner) return;

    this.partnerService.updateLocation(this.partner.id, latitude, longitude)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.lastLocationUpdate = new Date();
          }
        },
        error: (error) => {
          console.error('Error updating location:', error);
        }
      });
  }

  private startLocationTracking(): void {
    // Update location every 30 seconds when online and available
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (this.isOnline && this.isLocationEnabled) {
          this.geolocationService.getCurrentPosition()
            .then((position) => {
              this.updateLocation(position.coords.latitude, position.coords.longitude);
            })
            .catch((error) => {
              console.error('Error getting location for tracking:', error);
            });
        }
      });
  }

  private setupPeriodicUpdates(): void {
    // Refresh data every 2 minutes
    interval(120000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (this.isOnline) {
          this.loadActiveOrders();
          this.loadAvailableOrders();
        }
      });
  }

  acceptOrder(assignmentId: number): void {
    if (!this.partner) return;

    this.assignmentService.acceptAssignment(assignmentId, this.partner.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.swal.toast('Order accepted successfully', 'success');
            this.loadActiveOrders();
            this.loadAvailableOrders();
          }
        },
        error: (error) => {
          console.error('Error accepting order:', error);
          this.swal.toast('Failed to accept order', 'error');
        }
      });
  }

  rejectOrder(assignmentId: number): void {
    if (!this.partner) return;

    // TODO: Show dialog for rejection reason
    const reason = 'Unable to deliver at this time';
    
    this.assignmentService.rejectAssignment(assignmentId, this.partner.id, reason)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.swal.toast('Order rejected', 'success');
            this.loadAvailableOrders();
          }
        },
        error: (error) => {
          console.error('Error rejecting order:', error);
          this.swal.toast('Failed to reject order', 'error');
        }
      });
  }

  markPickedUp(assignmentId: number): void {
    if (!this.partner) return;

    this.assignmentService.markPickedUp(assignmentId, this.partner.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.swal.toast('Order marked as picked up', 'success');
            this.loadActiveOrders();
          }
        },
        error: (error) => {
          console.error('Error marking pickup:', error);
          this.swal.toast('Failed to mark as picked up', 'error');
        }
      });
  }

  startDelivery(assignmentId: number): void {
    if (!this.partner) return;

    this.assignmentService.startDelivery(assignmentId, this.partner.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.swal.toast('Delivery started', 'success');
            this.loadActiveOrders();
          }
        },
        error: (error) => {
          console.error('Error starting delivery:', error);
          this.swal.toast('Failed to start delivery', 'error');
        }
      });
  }

  completeDelivery(assignmentId: number): void {
    if (!this.partner) return;

    // TODO: Show dialog for delivery notes
    const notes = 'Delivered successfully';
    
    this.assignmentService.completeDelivery(assignmentId, this.partner.id, notes)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.swal.toast('Delivery completed successfully!', 'success');
            this.loadActiveOrders();
            this.loadTodayStats();
          }
        },
        error: (error) => {
          console.error('Error completing delivery:', error);
          this.swal.toast('Failed to complete delivery', 'error');
        }
      });
  }

  getStatusColor(status: string): string {
    return this.partnerService.getStatusColor(status);
  }

  getVehicleIcon(vehicleType: string): string {
    return this.partnerService.getVehicleIcon(vehicleType);
  }

  formatDistance(distance?: number): string {
    if (!distance) return 'N/A';
    return `${distance.toFixed(1)} km`;
  }

  formatEarnings(amount: number): string {
    return `₹${amount.toFixed(2)}`;
  }

  formatRating(rating: number): string {
    return rating.toFixed(1);
  }
}