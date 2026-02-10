import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { Subject, takeUntil, interval } from 'rxjs';
import { DeliveryPartnerService } from '../../services/delivery-partner.service';
import { OrderAssignmentService } from '../../services/order-assignment.service';
import { environment } from '../../../../../environments/environment';

export interface PartnerRow {
  partnerId: number;
  partnerName: string;
  phone: string;
  email: string;
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED' | 'BLOCKED';
  isOnline: boolean;
  isAvailable: boolean;
  rideStatus: string;
  rating: number;
  totalDeliveries: number;
  totalEarnings: number;
  lastActivity?: string;
  lastLogin?: string;
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

  displayedColumns: string[] = [
    'partnerId',
    'name',
    'phone',
    'status',
    'rating',
    'deliveries',
    'online',
    'actions'
  ];

  dataSource: MatTableDataSource<PartnerRow>;

  // Filter options
  statusFilter = 'All Status';
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
    private http: HttpClient,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.dataSource = new MatTableDataSource<PartnerRow>([]);
  }

  ngOnInit(): void {
    this.loadAssignmentData();
    this.setupAutoRefresh();
    this.setupFilters();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadAssignmentData(): void {
    this.isLoading = true;

    this.http.get<any>(`${environment.apiUrl}/mobile/delivery-partner/admin/partners`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && response.partners) {
            const partners: PartnerRow[] = response.partners.map((p: any) => ({
              partnerId: p.partnerId,
              partnerName: p.name || 'Unknown',
              phone: p.phone || '-',
              email: p.email || '-',
              status: p.isActive ? 'ACTIVE' : 'PENDING',
              isOnline: p.isOnline || false,
              isAvailable: p.isAvailable || false,
              rideStatus: p.rideStatus || 'OFFLINE',
              rating: p.rating || 0,
              totalDeliveries: p.totalDeliveries || 0,
              totalEarnings: p.totalEarnings || 0,
              lastActivity: p.lastActivity,
              lastLogin: p.lastLogin
            }));

            this.dataSource.data = partners;

            // Use statistics from API
            if (response.statistics) {
              this.totalPartners = response.statistics.total || partners.length;
              this.onlinePartners = response.statistics.online || 0;
              this.activeAssignments = response.statistics.available || 0;
            } else {
              this.totalPartners = partners.length;
              this.onlinePartners = partners.filter(p => p.isOnline).length;
              this.activeAssignments = partners.filter(p => p.isAvailable).length;
            }
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading delivery partners:', error);
          this.snackBar.open('Failed to load delivery partners', 'Close', { duration: 3000 });
          this.dataSource.data = [];
          this.isLoading = false;
        }
      });
  }

  private setupAutoRefresh(): void {
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.refreshData();
      });
  }

  private setupFilters(): void {
    this.dataSource.filterPredicate = (data: PartnerRow, filter: string) => {
      const searchTerm = this.searchTerm.toLowerCase();
      const statusMatch = this.statusFilter === 'All Status' ||
        (this.statusFilter === 'ACTIVE' && data.status === 'ACTIVE') ||
        (this.statusFilter === 'PENDING' && data.status === 'PENDING') ||
        (this.statusFilter === 'ONLINE' && data.isOnline);

      const textMatch = !searchTerm ||
        data.partnerId.toString().includes(searchTerm) ||
        data.partnerName.toLowerCase().includes(searchTerm) ||
        data.phone.includes(searchTerm);

      return statusMatch && textMatch;
    };
  }

  onStatusFilterChange(): void {
    this.applyFilter();
  }

  applyFilter(): void {
    this.dataSource.filter = Math.random().toString();
  }

  refreshData(): void {
    this.loadAssignmentData();
  }

  getStatusClass(status: string): string {
    return `status-${status.toLowerCase()}`;
  }

  // Action methods
  viewPartnerDetails(partner: PartnerRow): void {
    this.snackBar.open(`Viewing details for ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  assignOrder(partner: PartnerRow): void {
    this.snackBar.open(`Assigning order to ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  callPartner(phone: string): void {
    window.open(`tel:${phone}`, '_blank');
  }

  messagePartner(partner: PartnerRow): void {
    this.snackBar.open(`Opening message for ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  trackPartner(partner: PartnerRow): void {
    this.snackBar.open(`Tracking ${partner.partnerName}`, 'Close', { duration: 2000 });
  }

  togglePartnerStatus(partner: PartnerRow): void {
    this.isProcessing = true;
    const newStatus = partner.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

    this.partnerService.updatePartnerStatus(partner.partnerId, newStatus)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.snackBar.open(`Partner ${newStatus.toLowerCase()}`, 'Close', { duration: 2000 });
          this.loadAssignmentData();
          this.isProcessing = false;
        },
        error: (error) => {
          console.error('Error updating partner status:', error);
          this.snackBar.open('Failed to update status', 'Close', { duration: 2000 });
          this.isProcessing = false;
        }
      });
  }

  exportData(): void {
    this.snackBar.open('Exporting assignment data...', 'Close', { duration: 2000 });
  }
}
