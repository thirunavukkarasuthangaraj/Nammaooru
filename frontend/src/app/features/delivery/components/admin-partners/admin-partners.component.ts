import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, takeUntil } from 'rxjs';
import { DeliveryPartnerService, DeliveryPartner } from '../../services/delivery-partner.service';
import { ApiResponseHelper } from '../../../../core/models/api-response.model';
import { WebSocketService } from '../../../../core/services/websocket.service';
import { PartnerDetailsDialogComponent } from '../partner-details-dialog/partner-details-dialog.component';
import { DocumentVerificationDialogComponent } from '../document-verification-dialog/document-verification-dialog.component';

@Component({
  selector: 'app-admin-partners',
  templateUrl: './admin-partners.component.html',
  styleUrls: ['./admin-partners.component.scss']
})
export class AdminPartnersComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Table configuration
  displayedColumns: string[] = [
    'partnerId',
    'fullName',
    'phoneNumber',
    'vehicleType',
    'status',
    'verificationStatus',
    'rating',
    'totalDeliveries',
    'isOnline',
    'actions'
  ];
  dataSource: MatTableDataSource<DeliveryPartner>;
  
  // Filter options
  statusFilter = 'ALL';
  verificationFilter = 'ALL';
  searchTerm = '';
  
  // Statistics
  stats = {
    total: 0,
    active: 0,
    pending: 0,
    suspended: 0,
    online: 0,
    verified: 0
  };

  // Loading states
  isLoading = true;
  isProcessing = false;

  // Real-time updates
  onlinePartners = new Set<number>();
  emergencyAlerts: any[] = [];

  constructor(
    private partnerService: DeliveryPartnerService,
    private webSocketService: WebSocketService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.dataSource = new MatTableDataSource<DeliveryPartner>([]);
  }

  ngOnInit(): void {
    this.loadPartners();
    this.loadStatistics();
    this.setupWebSocketSubscriptions();
    this.setupFilters();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadPartners(): void {
    this.isLoading = true;
    this.partnerService.getAllPartners(0, 100)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.dataSource.data = response.data.content;
            this.dataSource.paginator = this.paginator;
            this.dataSource.sort = this.sort;
            this.updateOnlineStatus();
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading partners:', error);
          this.snackBar.open('Failed to load partners', 'Close', { duration: 3000 });
          this.isLoading = false;
        }
      });
  }

  private loadStatistics(): void {
    this.partnerService.getPartnerCounts()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.stats = {
              total: Object.values(response.data).reduce((a: number, b: number) => a + b, 0) as number,
              active: response.data['ACTIVE'] || 0,
              pending: response.data['PENDING'] || 0,
              suspended: response.data['SUSPENDED'] || 0,
              online: this.onlinePartners.size,
              verified: this.dataSource.data.filter(p => p.verificationStatus === 'VERIFIED').length
            };
          }
        },
        error: (error) => {
          console.error('Error loading statistics:', error);
        }
      });
  }

  private setupWebSocketSubscriptions(): void {
    // Subscribe to partner online status updates
    this.webSocketService.subscribe('/topic/delivery/admin/partner-status')
      .pipe(takeUntil(this.destroy$))
      .subscribe((update: any) => {
        if (update.isOnline) {
          this.onlinePartners.add(update.partnerId);
        } else {
          this.onlinePartners.delete(update.partnerId);
        }
        this.updateOnlineStatus();
        this.stats.online = this.onlinePartners.size;
      });

    // Subscribe to emergency alerts
    this.webSocketService.subscribeToEmergencyAlerts()
      .pipe(takeUntil(this.destroy$))
      .subscribe((alert: any) => {
        this.emergencyAlerts.unshift(alert);
        this.showEmergencyAlert(alert);
      });
  }

  private setupFilters(): void {
    this.dataSource.filterPredicate = (data: DeliveryPartner, filter: string) => {
      const searchStr = filter.toLowerCase();
      
      // Apply status filter
      if (this.statusFilter !== 'ALL' && data.status !== this.statusFilter) {
        return false;
      }
      
      // Apply verification filter
      if (this.verificationFilter !== 'ALL' && data.verificationStatus !== this.verificationFilter) {
        return false;
      }
      
      // Apply search filter
      if (searchStr) {
        return data.fullName.toLowerCase().includes(searchStr) ||
               data.partnerId.toLowerCase().includes(searchStr) ||
               data.phoneNumber.includes(searchStr) ||
               data.email.toLowerCase().includes(searchStr);
      }
      
      return true;
    };
  }

  applyFilter(): void {
    this.dataSource.filter = this.searchTerm.trim().toLowerCase();
  }

  onStatusFilterChange(): void {
    this.applyFilter();
  }

  onVerificationFilterChange(): void {
    this.applyFilter();
  }

  viewPartnerDetails(partner: DeliveryPartner): void {
    const dialogRef = this.dialog.open(PartnerDetailsDialogComponent, {
      width: '800px',
      data: partner
    });
  }

  verifyDocuments(partner: DeliveryPartner): void {
    const dialogRef = this.dialog.open(DocumentVerificationDialogComponent, {
      width: '900px',
      data: partner
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadPartners();
      }
    });
  }

  approvePartner(partner: DeliveryPartner): void {
    if (!partner.allDocumentsVerified) {
      this.snackBar.open('Please verify all documents before approval', 'Close', { duration: 3000 });
      return;
    }

    this.isProcessing = true;
    this.partnerService.updatePartnerStatus(partner.id, 'ACTIVE')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.partnerService.updateVerificationStatus(partner.id, 'VERIFIED')
              .subscribe(() => {
                this.snackBar.open('Partner approved successfully', 'Close', { duration: 3000 });
                this.loadPartners();
                this.loadStatistics();
              });
          }
          this.isProcessing = false;
        },
        error: (error) => {
          console.error('Error approving partner:', error);
          this.snackBar.open('Failed to approve partner', 'Close', { duration: 3000 });
          this.isProcessing = false;
        }
      });
  }

  rejectPartner(partner: DeliveryPartner): void {
    // TODO: Show rejection reason dialog
    this.isProcessing = true;
    this.partnerService.updateVerificationStatus(partner.id, 'REJECTED')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.snackBar.open('Partner rejected', 'Close', { duration: 3000 });
            this.loadPartners();
            this.loadStatistics();
          }
          this.isProcessing = false;
        },
        error: (error) => {
          console.error('Error rejecting partner:', error);
          this.snackBar.open('Failed to reject partner', 'Close', { duration: 3000 });
          this.isProcessing = false;
        }
      });
  }

  suspendPartner(partner: DeliveryPartner): void {
    this.isProcessing = true;
    this.partnerService.updatePartnerStatus(partner.id, 'SUSPENDED')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.snackBar.open('Partner suspended', 'Close', { duration: 3000 });
            this.loadPartners();
            this.loadStatistics();
          }
          this.isProcessing = false;
        },
        error: (error) => {
          console.error('Error suspending partner:', error);
          this.snackBar.open('Failed to suspend partner', 'Close', { duration: 3000 });
          this.isProcessing = false;
        }
      });
  }

  activatePartner(partner: DeliveryPartner): void {
    this.isProcessing = true;
    this.partnerService.updatePartnerStatus(partner.id, 'ACTIVE')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.snackBar.open('Partner activated', 'Close', { duration: 3000 });
            this.loadPartners();
            this.loadStatistics();
          }
          this.isProcessing = false;
        },
        error: (error) => {
          console.error('Error activating partner:', error);
          this.snackBar.open('Failed to activate partner', 'Close', { duration: 3000 });
          this.isProcessing = false;
        }
      });
  }

  blockPartner(partner: DeliveryPartner): void {
    if (confirm('Are you sure you want to block this partner? This action cannot be easily reversed.')) {
      this.isProcessing = true;
      this.partnerService.updatePartnerStatus(partner.id, 'BLOCKED')
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response)) {
              this.snackBar.open('Partner blocked', 'Close', { duration: 3000 });
              this.loadPartners();
              this.loadStatistics();
            }
            this.isProcessing = false;
          },
          error: (error) => {
            console.error('Error blocking partner:', error);
            this.snackBar.open('Failed to block partner', 'Close', { duration: 3000 });
            this.isProcessing = false;
          }
        });
    }
  }

  private updateOnlineStatus(): void {
    this.dataSource.data.forEach(partner => {
      partner.isOnline = this.onlinePartners.has(partner.id);
    });
    this.dataSource._updateChangeSubscription();
  }

  private showEmergencyAlert(alert: any): void {
    const message = `EMERGENCY: Partner ${alert.partnerName} - ${alert.type}`;
    this.snackBar.open(message, 'View', {
      duration: 10000,
      panelClass: 'emergency-snackbar'
    }).onAction().subscribe(() => {
      this.viewEmergencyDetails(alert);
    });
  }

  viewEmergencyDetails(alert: any): void {
    // TODO: Show emergency details dialog with map location
    console.log('Emergency details:', alert);
  }

  exportPartnerData(): void {
    // TODO: Implement CSV export
    const csvData = this.convertToCSV(this.dataSource.data);
    this.downloadCSV(csvData, 'partners.csv');
  }

  private convertToCSV(data: DeliveryPartner[]): string {
    const headers = ['Partner ID', 'Name', 'Phone', 'Email', 'Vehicle', 'Status', 'Rating', 'Deliveries'];
    const rows = data.map(p => [
      p.partnerId,
      p.fullName,
      p.phoneNumber,
      p.email,
      p.vehicleType,
      p.status,
      p.rating,
      p.totalDeliveries
    ]);
    
    return [headers, ...rows].map(row => row.join(',')).join('\n');
  }

  private downloadCSV(data: string, filename: string): void {
    const blob = new Blob([data], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
  }

  refreshData(): void {
    this.loadPartners();
    this.loadStatistics();
  }

  getStatusColor(status: string): string {
    return this.partnerService.getStatusColor(status);
  }

  getVerificationIcon(status: string): string {
    switch (status) {
      case 'VERIFIED': return 'verified';
      case 'PENDING': return 'pending';
      case 'REJECTED': return 'cancel';
      default: return 'help';
    }
  }

  getVehicleIcon(vehicleType: string): string {
    return this.partnerService.getVehicleIcon(vehicleType);
  }
}