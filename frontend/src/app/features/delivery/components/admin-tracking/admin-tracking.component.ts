import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { Subject, takeUntil, interval, forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderAssignmentService, OrderAssignment } from '../../services/order-assignment.service';
import { DeliveryTrackingService } from '../../services/delivery-tracking.service';
import { ApiResponseHelper } from '../../../../core/models/api-response.model';

@Component({
  selector: 'app-admin-tracking',
  templateUrl: './admin-tracking.component.html',
  styleUrls: ['./admin-tracking.component.scss']
})
export class AdminTrackingComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  activeAssignments: OrderAssignment[] = [];
  filteredAssignments: OrderAssignment[] = [];
  isLoading = true;
  lastRefresh: Date = new Date();
  selectedStatus = 'ALL';

  stats = {
    totalActive: 0,
    inTransit: 0,
    pickedUp: 0,
    assigned: 0,
    deliveredToday: 0
  };

  statusFilters = [
    { value: 'ALL', label: 'All Active', icon: 'list' },
    { value: 'IN_TRANSIT', label: 'In Transit', icon: 'local_shipping' },
    { value: 'PICKED_UP', label: 'Picked Up', icon: 'shopping_cart' },
    { value: 'ACCEPTED', label: 'Accepted', icon: 'check_circle' },
    { value: 'ASSIGNED', label: 'Assigned', icon: 'assignment' }
  ];

  displayedColumns: string[] = ['status', 'orderNumber', 'partnerName', 'customerName', 'deliveryAddress', 'time', 'actions'];

  constructor(
    private assignmentService: OrderAssignmentService,
    private trackingService: DeliveryTrackingService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadActiveDeliveries();

    // Auto-refresh every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.loadActiveDeliveries());
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadActiveDeliveries(): void {
    const activeStatuses = ['ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'];

    forkJoin(
      activeStatuses.map(status =>
        this.assignmentService.getAssignmentsByStatus(status).pipe(
          catchError(() => of({ statusCode: 'SUCCESS', message: '', data: [], timestamp: '' }))
        )
      )
    ).pipe(takeUntil(this.destroy$)).subscribe({
      next: (responses) => {
        this.activeAssignments = [];
        responses.forEach(response => {
          const data = response?.data || (response as any)?.content || [];
          if (Array.isArray(data)) {
            this.activeAssignments.push(...data);
          }
        });

        // Sort by most recent first
        this.activeAssignments.sort((a, b) =>
          new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
        );

        this.calculateStats();
        this.applyFilter();
        this.lastRefresh = new Date();
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.snackBar.open('Failed to load active deliveries', 'Close', { duration: 3000 });
      }
    });
  }

  private calculateStats(): void {
    this.stats.totalActive = this.activeAssignments.length;
    this.stats.inTransit = this.activeAssignments.filter(a => a.status === 'IN_TRANSIT').length;
    this.stats.pickedUp = this.activeAssignments.filter(a => a.status === 'PICKED_UP').length;
    this.stats.assigned = this.activeAssignments.filter(a => a.status === 'ASSIGNED' || a.status === 'ACCEPTED').length;

    // Count today's delivered (we don't have this data from active query, keep at 0)
    this.stats.deliveredToday = 0;
  }

  applyFilter(): void {
    if (this.selectedStatus === 'ALL') {
      this.filteredAssignments = [...this.activeAssignments];
    } else {
      this.filteredAssignments = this.activeAssignments.filter(a => a.status === this.selectedStatus);
    }
  }

  filterByStatus(status: string): void {
    this.selectedStatus = status;
    this.applyFilter();
  }

  trackDelivery(assignment: OrderAssignment): void {
    this.router.navigate(['/delivery/tracking', assignment.id]);
  }

  refreshData(): void {
    this.isLoading = true;
    this.loadActiveDeliveries();
    this.snackBar.open('Refreshing tracking data...', 'Close', { duration: 1500 });
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ASSIGNED': return '#ff9800';
      case 'ACCEPTED': return '#2196f3';
      case 'PICKED_UP': return '#9c27b0';
      case 'IN_TRANSIT': return '#4caf50';
      case 'DELIVERED': return '#00bcd4';
      default: return '#757575';
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

  formatStatus(status: string): string {
    return status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  formatTimeAgo(date: Date | string): string {
    if (!date) return 'N/A';
    const now = new Date();
    const d = new Date(date);
    const diffMs = now.getTime() - d.getTime();
    const diffMin = Math.floor(diffMs / 60000);

    if (diffMin < 1) return 'Just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    const diffHrs = Math.floor(diffMin / 60);
    if (diffHrs < 24) return `${diffHrs}h ago`;
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
  }

  formatTime(date: Date | string): string {
    if (!date) return '--:--';
    return new Date(date).toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  callPartner(assignment: OrderAssignment, event: Event): void {
    event.stopPropagation();
    if (assignment.partnerPhone) {
      window.open(`tel:${assignment.partnerPhone}`);
    }
  }
}
