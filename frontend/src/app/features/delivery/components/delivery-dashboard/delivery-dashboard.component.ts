import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { DeliveryAssignmentService, DeliveryAssignment } from '../../services/delivery-assignment.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-delivery-dashboard',
  templateUrl: './delivery-dashboard.component.html',
  styleUrls: ['./delivery-dashboard.component.scss']
})
export class DeliveryDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  partnerId = 1; // This should come from auth service
  isOnline = false;
  currentAssignment: DeliveryAssignment | null = null;
  availableAssignments: DeliveryAssignment[] = [];
  completedAssignments: DeliveryAssignment[] = [];
  
  // Earnings
  todayEarnings = {
    totalEarnings: 0,
    completedDeliveries: 0,
    pendingEarnings: 0,
    averageRating: 0
  };
  
  // OTP input
  otpInput = '';
  
  // Location tracking
  currentLocation = {
    latitude: 0,
    longitude: 0
  };
  
  selectedTab = 0;
  loading = false;

  constructor(
    private deliveryService: DeliveryAssignmentService
  ) {}

  ngOnInit(): void {
    this.loadPartnerId();
    this.loadCurrentAssignment();
    this.loadAssignments();
    this.loadEarnings();
    this.startLocationTracking();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadPartnerId(): void {
    // Get partner ID from auth service or local storage
    const user = localStorage.getItem('currentUser');
    if (user) {
      const userData = JSON.parse(user);
      this.partnerId = userData.partnerId || userData.id || 1;
    }
  }

  toggleOnlineStatus(): void {
    this.isOnline = !this.isOnline;
    this.deliveryService.toggleOnlineStatus(this.partnerId, this.isOnline)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          if (this.isOnline) {
            this.loadAssignments();
          }
        },
        error: (error) => {
          console.error('Error toggling status:', error);
          this.isOnline = !this.isOnline; // Revert on error
        }
      });
  }

  loadCurrentAssignment(): void {
    this.deliveryService.currentAssignment$
      .pipe(takeUntil(this.destroy$))
      .subscribe(assignment => {
        this.currentAssignment = assignment;
      });
  }

  loadAssignments(): void {
    if (!this.isOnline) return;
    
    this.loading = true;
    
    // Load available assignments
    this.deliveryService.getPartnerAssignments(this.partnerId, 'PENDING')
      .pipe(takeUntil(this.destroy$))
      .subscribe(assignments => {
        this.availableAssignments = assignments;
        this.loading = false;
        
        if (assignments.length > 0) {
          this.playNotificationSound();
          Swal.fire({
            title: 'New Delivery Available!',
            text: `${assignments.length} new delivery request${assignments.length > 1 ? 's' : ''}`,
            icon: 'info',
            toast: true,
            position: 'top-end',
            timer: 5000,
            showConfirmButton: false
          });
        }
      });
    
    // Load completed assignments
    this.deliveryService.getPartnerAssignments(this.partnerId, 'DELIVERED')
      .pipe(takeUntil(this.destroy$))
      .subscribe(assignments => {
        this.completedAssignments = assignments;
      });
  }

  loadEarnings(): void {
    this.deliveryService.getPartnerEarnings(this.partnerId, 'today')
      .pipe(takeUntil(this.destroy$))
      .subscribe(earnings => {
        this.todayEarnings = earnings;
      });
  }

  acceptAssignment(assignment: DeliveryAssignment): void {
    Swal.fire({
      title: 'Accept Delivery?',
      html: `
        <div>
          <p><strong>Order:</strong> #${assignment.orderNumber}</p>
          <p><strong>Distance:</strong> ${assignment.distance} km</p>
          <p><strong>Earnings:</strong> ₹${assignment.earnings}</p>
        </div>
      `,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Accept',
      cancelButtonText: 'Decline'
    }).then((result) => {
      if (result.isConfirmed) {
        this.deliveryService.acceptAssignment(assignment.id)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: (updatedAssignment) => {
              this.currentAssignment = updatedAssignment;
              this.loadAssignments();
            },
            error: (error) => {
              console.error('Error accepting assignment:', error);
            }
          });
      }
    });
  }

  rejectAssignment(assignment: DeliveryAssignment): void {
    Swal.fire({
      title: 'Decline Delivery?',
      input: 'select',
      inputOptions: {
        'Too far': 'Too far',
        'Vehicle issue': 'Vehicle issue',
        'Personal reason': 'Personal reason',
        'Other': 'Other'
      },
      inputPlaceholder: 'Select reason',
      showCancelButton: true,
      confirmButtonText: 'Decline',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.deliveryService.rejectAssignment(assignment.id, result.value)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              this.loadAssignments();
            },
            error: (error) => {
              console.error('Error rejecting assignment:', error);
            }
          });
      }
    });
  }

  startPickup(): void {
    if (!this.currentAssignment) return;
    
    this.deliveryService.startPickup(this.currentAssignment.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (assignment) => {
          this.currentAssignment = assignment;
          this.openNavigation(this.currentAssignment.pickupAddress);
        },
        error: (error) => {
          console.error('Error starting pickup:', error);
        }
      });
  }

  verifyPickupOTP(): void {
    if (!this.currentAssignment || !this.otpInput) {
      Swal.fire('Error', 'Please enter the OTP', 'error');
      return;
    }
    
    this.deliveryService.verifyPickupOTP(this.currentAssignment.id, this.otpInput)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (assignment) => {
          this.currentAssignment = assignment;
          this.otpInput = '';
        },
        error: (error) => {
          console.error('Error verifying OTP:', error);
          Swal.fire('Invalid OTP', 'Please check the OTP and try again', 'error');
        }
      });
  }

  startDelivery(): void {
    if (!this.currentAssignment) return;
    
    this.deliveryService.startDelivery(this.currentAssignment.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (assignment) => {
          this.currentAssignment = assignment;
          this.openNavigation(this.currentAssignment.deliveryAddress);
        },
        error: (error) => {
          console.error('Error starting delivery:', error);
        }
      });
  }

  verifyDeliveryOTP(): void {
    if (!this.currentAssignment || !this.otpInput) {
      Swal.fire('Error', 'Please enter the OTP', 'error');
      return;
    }
    
    // Option to capture proof of delivery
    Swal.fire({
      title: 'Delivery Confirmation',
      text: 'Would you like to capture proof of delivery?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, capture',
      cancelButtonText: 'No, proceed'
    }).then((result) => {
      if (result.isConfirmed) {
        // Capture proof (photo)
        this.captureDeliveryProof();
      } else {
        // Proceed without proof
        this.completeDelivery();
      }
    });
  }

  completeDelivery(proofImage?: File): void {
    if (!this.currentAssignment) return;
    
    this.deliveryService.verifyDeliveryOTP(this.currentAssignment.id, this.otpInput, proofImage)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (assignment) => {
          this.currentAssignment = null;
          this.otpInput = '';
          this.loadAssignments();
          this.loadEarnings();
        },
        error: (error) => {
          console.error('Error completing delivery:', error);
          Swal.fire('Invalid OTP', 'Please check the OTP and try again', 'error');
        }
      });
  }

  captureDeliveryProof(): void {
    // Create file input for image capture
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.capture = 'environment';
    
    input.onchange = (event: any) => {
      const file = event.target.files[0];
      if (file) {
        this.completeDelivery(file);
      }
    };
    
    input.click();
  }

  reportIssue(): void {
    if (!this.currentAssignment) return;
    
    Swal.fire({
      title: 'Report Issue',
      input: 'select',
      inputOptions: {
        'Cannot find address': 'Cannot find address',
        'Customer not available': 'Customer not available',
        'Wrong order': 'Wrong order',
        'Vehicle breakdown': 'Vehicle breakdown',
        'Accident': 'Accident',
        'Other': 'Other'
      },
      inputPlaceholder: 'Select issue type',
      showCancelButton: true,
      confirmButtonText: 'Report',
      preConfirm: (issue) => {
        return Swal.fire({
          title: 'Issue Description',
          input: 'textarea',
          inputPlaceholder: 'Describe the issue...',
          showCancelButton: true
        }).then((result) => {
          if (result.isConfirmed) {
            return { issue, description: result.value };
          }
          return null;
        });
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.deliveryService.reportIssue(
          this.currentAssignment!.id,
          result.value.issue,
          result.value.description
        ).pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              console.log('Issue reported');
            },
            error: (error) => {
              console.error('Error reporting issue:', error);
            }
          });
      }
    });
  }

  callCustomer(): void {
    if (this.currentAssignment) {
      // Implement call functionality
      window.location.href = `tel:${this.currentAssignment.partnerPhone}`;
    }
  }

  openNavigation(address: string): void {
    // Open Google Maps with the address
    const encodedAddress = encodeURIComponent(address);
    window.open(`https://www.google.com/maps/search/?api=1&query=${encodedAddress}`, '_blank');
  }

  startLocationTracking(): void {
    if (!navigator.geolocation) {
      console.error('Geolocation is not supported');
      return;
    }
    
    // Update location every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            this.currentLocation = {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude
            };
            
            // Update location on server if online
            if (this.isOnline) {
              this.deliveryService.updateLocation(
                this.partnerId,
                this.currentLocation.latitude,
                this.currentLocation.longitude
              ).subscribe();
            }
          },
          (error) => {
            console.error('Error getting location:', error);
          }
        );
      });
  }

  playNotificationSound(): void {
    const audio = new Audio('/assets/sounds/notification.mp3');
    audio.play().catch(e => console.error('Error playing sound:', e));
  }

  getStatusColor(status: string): string {
    switch(status) {
      case 'ASSIGNED': return '#ff9800';
      case 'ACCEPTED': return '#2196f3';
      case 'PICKUP_STARTED': return '#9c27b0';
      case 'PICKED_UP': return '#4caf50';
      case 'DELIVERY_STARTED': return '#ff5722';
      case 'DELIVERED': return '#8bc34a';
      default: return '#757575';
    }
  }

  getStatusIcon(status: string): string {
    switch(status) {
      case 'ASSIGNED': return 'assignment';
      case 'ACCEPTED': return 'check_circle';
      case 'PICKUP_STARTED': return 'directions_bike';
      case 'PICKED_UP': return 'inventory';
      case 'DELIVERY_STARTED': return 'delivery_dining';
      case 'DELIVERED': return 'done_all';
      default: return 'help';
    }
  }
}