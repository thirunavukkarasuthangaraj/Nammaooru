import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, takeUntil, interval } from 'rxjs';
import { DeliveryPartnerService, DeliveryPartner } from '../../services/delivery-partner.service';
import { OrderAssignmentService } from '../../services/order-assignment.service';

export interface OrderAssignment {
  partnerId: string;
  partnerName: string;
  phone: string;
  vehicle: string;
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED' | 'BLOCKED';
  verification: 'VERIFIED' | 'PENDING' | 'REJECTED';
  rating: number;
  deliveries: number;
  isOnline: boolean;
  currentOrderId?: string;
  lastActiveTime?: Date;
  earnings?: number;
}

@Component({
  selector: 'app-order-assignments',
  templateUrl: './order-assignments.component.html',
  styleUrls: ['./order-assignments.component.scss']
})
export class OrderAssignmentsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Table configuration
  displayedColumns: string[] = [
    'partnerId',
    'name',
    'phone',
    'vehicle',
    'status',
    'verification',
    'rating',
    'deliveries',
    'online',
    'actions'
  ];

  dataSource: MatTableDataSource<OrderAssignment>;

  // Filter options
  statusFilter = 'All Status';
  verificationFilter = 'All Verification';
  searchTerm = '';

  // Loading states
  isLoading = true;
  isProcessing = false;

  // Statistics
  totalPartners = 0;
  onlinePartners = 0;
  activeAssignments = 0;

  constructor(
    private partnerService: DeliveryPartnerService,
    private assignmentService: OrderAssignmentService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.dataSource = new MatTableDataSource<OrderAssignment>([]);
  }

  ngOnInit(): void {
    this.loadAssignmentData();
    this.setupAutoRefresh();
    this.setupFilters();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadAssignmentData(): void {
    this.isLoading = true;

    // Mock data based on your screenshot
    const mockAssignments: OrderAssignment[] = [
      {
        partnerId: 'DP001',
        partnerName: 'John Smith',
        phone: '+91 9876543210',
        vehicle: 'BIKE',
        status: 'ACTIVE',
        verification: 'VERIFIED',
        rating: 4.5,
        deliveries: 156,
        isOnline: true,
        currentOrderId: 'ORD-2025-001',
        lastActiveTime: new Date(),
        earnings: 12500
      },
      {
        partnerId: 'DP002',
        partnerName: 'Sarah Wilson',
        phone: '+91 9876543211',
        vehicle: 'SCOOTER',
        status: 'ACTIVE',
        verification: 'VERIFIED',
        rating: 4.8,
        deliveries: 289,
        isOnline: true,
        currentOrderId: 'ORD-2025-002',
        lastActiveTime: new Date(),
        earnings: 18750
      },
      {
        partnerId: 'DP003',
        partnerName: 'Mike Johnson',
        phone: '+91 9876543212',
        vehicle: 'CAR',
        status: 'PENDING',
        verification: 'PENDING',
        rating: 0.0,
        deliveries: 0,
        isOnline: false,
        lastActiveTime: new Date(Date.now() - 30000), // 30 seconds ago
        earnings: 0
      }
    ];

    setTimeout(() => {
      this.dataSource.data = mockAssignments;
      this.totalPartners = mockAssignments.length;
      this.onlinePartners = mockAssignments.filter(p => p.isOnline).length;
      this.activeAssignments = mockAssignments.filter(p => p.currentOrderId).length;
      this.isLoading = false;
    }, 1000);
  }

  private setupAutoRefresh(): void {
    // Auto-refresh every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.refreshData();
      });
  }

  private setupFilters(): void {
    this.dataSource.filterPredicate = (data: OrderAssignment, filter: string) => {
      const searchTerm = this.searchTerm.toLowerCase();
      const statusMatch = this.statusFilter === 'All Status' || data.status === this.statusFilter;
      const verificationMatch = this.verificationFilter === 'All Verification' || data.verification === this.verificationFilter;

      const textMatch = !searchTerm ||
        data.partnerId.toLowerCase().includes(searchTerm) ||
        data.partnerName.toLowerCase().includes(searchTerm) ||
        data.phone.includes(searchTerm);

      return statusMatch && verificationMatch && textMatch;
    };
  }

  onStatusFilterChange(): void {
    this.applyFilter();
  }

  onVerificationFilterChange(): void {
    this.applyFilter();
  }

  applyFilter(): void {
    this.dataSource.filter = Math.random().toString(); // Trigger filter
  }

  refreshData(): void {
    this.loadAssignmentData();
  }

  getStatusClass(status: string): string {
    return `status-${status.toLowerCase()}`;
  }

  getVerificationClass(verification: string): string {
    return `verification-${verification.toLowerCase()}`;
  }

  getVehicleIcon(vehicleType: string): string {
    switch (vehicleType) {
      case 'BIKE': return 'two_wheeler';
      case 'SCOOTER': return 'scooter';
      case 'CAR': return 'directions_car';
      default: return 'delivery_dining';
    }
  }

  // Action methods
  viewPartnerDetails(partner: OrderAssignment): void {
    this.snackBar.open(`Viewing details for ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  assignOrder(partner: OrderAssignment): void {
    this.snackBar.open(`Assigning order to ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  callPartner(phone: string): void {
    window.open(`tel:${phone}`, '_blank');
  }

  messagePartner(partner: OrderAssignment): void {
    this.snackBar.open(`Opening message for ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  trackPartner(partner: OrderAssignment): void {
    this.snackBar.open(`Tracking ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  togglePartnerStatus(partner: OrderAssignment): void {
    this.isProcessing = true;

    setTimeout(() => {
      const newStatus = partner.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
      partner.status = newStatus;
      this.snackBar.open(`Partner ${newStatus.toLowerCase()}`, 'Close', { duration: 2000 });
      this.isProcessing = false;
    }, 1000);
  }

  exportData(): void {
    this.snackBar.open('Exporting assignment data...', 'Close', { duration: 2000 });
  }
}