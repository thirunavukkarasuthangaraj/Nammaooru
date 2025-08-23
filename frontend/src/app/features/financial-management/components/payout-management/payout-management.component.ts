import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import Swal from 'sweetalert2';

export interface PayoutData {
  id: number;
  shopId: number;
  shopName: string;
  shopOwnerName: string;
  shopOwnerEmail: string;
  payoutPeriod: string;
  totalRevenue: number;
  platformCommission: number;
  payoutAmount: number;
  status: 'PENDING' | 'APPROVED' | 'PAID' | 'REJECTED';
  payoutDate?: string;
  bankAccount: string;
  ifscCode: string;
  transactionId?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface PayoutStats {
  totalPayouts: number;
  pendingPayouts: number;
  completedPayouts: number;
  totalPayoutAmount: number;
  pendingAmount: number;
  completedAmount: number;
  averagePayoutAmount: number;
}

@Component({
  selector: 'app-payout-management',
  templateUrl: './payout-management.component.html',
  styleUrls: ['./payout-management.component.scss']
})
export class PayoutManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = [
    'shopName',
    'shopOwnerName',
    'payoutPeriod',
    'totalRevenue',
    'platformCommission',
    'payoutAmount',
    'status',
    'payoutDate',
    'actions'
  ];

  dataSource = new MatTableDataSource<PayoutData>();
  loading = false;
  payoutStats: PayoutStats = {
    totalPayouts: 0,
    pendingPayouts: 0,
    completedPayouts: 0,
    totalPayoutAmount: 0,
    pendingAmount: 0,
    completedAmount: 0,
    averagePayoutAmount: 0
  };

  statusFilter = '';
  searchTerm = '';
  statusOptions = [
    { value: '', label: 'All Status' },
    { value: 'PENDING', label: 'Pending' },
    { value: 'APPROVED', label: 'Approved' },
    { value: 'PAID', label: 'Paid' },
    { value: 'REJECTED', label: 'Rejected' }
  ];

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadPayoutData();
    this.loadPayoutStats();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadPayoutData(): void {
    this.loading = true;
    const apiUrl = `${environment.apiUrl}/financial/payouts`;
    
    this.http.get<{data: PayoutData[]}>(apiUrl).pipe(
      catchError(() => {
        this.loadMockPayoutData();
        return of(null);
      })
    ).subscribe({
      next: (response) => {
        if (response) {
          this.dataSource.data = response.data;
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading payout data:', error);
        this.loadMockPayoutData();
        this.loading = false;
      }
    });
  }

  private loadMockPayoutData(): void {
    const mockData: PayoutData[] = [
      {
        id: 1,
        shopId: 1,
        shopName: 'Annamalai Stores',
        shopOwnerName: 'Annamalai Raman',
        shopOwnerEmail: 'annamalai@stores.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 87500.00,
        platformCommission: 8750.00,
        payoutAmount: 78750.00,
        status: 'PAID',
        payoutDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        bankAccount: '****1234',
        ifscCode: 'SBIN0001234',
        transactionId: 'TXN87654321',
        notes: 'Payout completed successfully',
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        shopId: 2,
        shopName: 'Saravana Medical',
        shopOwnerName: 'Dr. Saravanan',
        shopOwnerEmail: 'saravana@medical.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 45600.00,
        platformCommission: 4560.00,
        payoutAmount: 41040.00,
        status: 'APPROVED',
        bankAccount: '****5678',
        ifscCode: 'ICIC0005678',
        notes: 'Ready for payout processing',
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        shopId: 3,
        shopName: 'Tamil Books Corner',
        shopOwnerName: 'Muthu Kumar',
        shopOwnerEmail: 'muthu@tamilbooks.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 23400.00,
        platformCommission: 2340.00,
        payoutAmount: 21060.00,
        status: 'PENDING',
        bankAccount: '****9012',
        ifscCode: 'HDFC0009012',
        notes: 'Under review',
        createdAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 4,
        shopId: 7,
        shopName: 'Textile Paradise',
        shopOwnerName: 'Ravi Shankar',
        shopOwnerEmail: 'ravi@textile.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 156800.00,
        platformCommission: 15680.00,
        payoutAmount: 141120.00,
        status: 'PAID',
        payoutDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        bankAccount: '****3456',
        ifscCode: 'AXIS0003456',
        transactionId: 'TXN12345678',
        notes: 'Large payout completed',
        createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 5,
        shopId: 8,
        shopName: 'Sports Zone',
        shopOwnerName: 'Vijay Kumar',
        shopOwnerEmail: 'vijay@sportszone.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 98400.00,
        platformCommission: 9840.00,
        payoutAmount: 88560.00,
        status: 'APPROVED',
        bankAccount: '****7890',
        ifscCode: 'KOTAK0007890',
        notes: 'Approved for payment',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 6,
        shopId: 6,
        shopName: 'Flower Garden Store',
        shopOwnerName: 'Lakshmi Devi',
        shopOwnerEmail: 'lakshmi@flowers.com',
        payoutPeriod: 'November 2024',
        totalRevenue: 34200.00,
        platformCommission: 3420.00,
        payoutAmount: 30780.00,
        status: 'REJECTED',
        bankAccount: '****2468',
        ifscCode: 'PNB0002468',
        notes: 'Bank account verification failed',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 7,
        shopId: 1,
        shopName: 'Annamalai Stores',
        shopOwnerName: 'Annamalai Raman',
        shopOwnerEmail: 'annamalai@stores.com',
        payoutPeriod: 'December 2024',
        totalRevenue: 95200.00,
        platformCommission: 9520.00,
        payoutAmount: 85680.00,
        status: 'PENDING',
        bankAccount: '****1234',
        ifscCode: 'SBIN0001234',
        notes: 'Current month payout pending',
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];

    this.dataSource.data = mockData;
    this.snackBar.open('Loaded mock payout data - API not available', 'Close', { duration: 3000 });
  }

  loadPayoutStats(): void {
    const apiUrl = `${environment.apiUrl}/financial/payout-stats`;
    
    this.http.get<{data: PayoutStats}>(apiUrl).pipe(
      catchError(() => {
        this.loadMockPayoutStats();
        return of(null);
      })
    ).subscribe({
      next: (response) => {
        if (response) {
          this.payoutStats = response.data;
        }
      },
      error: (error) => {
        console.error('Error loading payout stats:', error);
        this.loadMockPayoutStats();
      }
    });
  }

  private loadMockPayoutStats(): void {
    this.payoutStats = {
      totalPayouts: 7,
      pendingPayouts: 2,
      completedPayouts: 2,
      totalPayoutAmount: 446970.00,
      pendingAmount: 106740.00,
      completedAmount: 219870.00,
      averagePayoutAmount: 63852.86
    };
  }

  applyFilter(): void {
    let filteredData = this.dataSource.data;

    if (this.searchTerm) {
      filteredData = this.dataSource.data.filter(payout =>
        payout.shopName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        payout.shopOwnerName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        payout.shopOwnerEmail.toLowerCase().includes(this.searchTerm.toLowerCase())
      );
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(payout => payout.status === this.statusFilter);
    }

    this.dataSource.data = filteredData;
  }

  approvePayout(payout: PayoutData): void {
    Swal.fire({
      title: 'Approve Payout',
      text: `Are you sure you want to approve payout of ₹${payout.payoutAmount.toLocaleString()} to ${payout.shopName}?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Approve',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#4caf50'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update status locally
        const index = this.dataSource.data.findIndex(p => p.id === payout.id);
        if (index !== -1) {
          this.dataSource.data[index].status = 'APPROVED';
          this.dataSource.data[index].updatedAt = new Date().toISOString();
          this.dataSource._updateChangeSubscription();
        }
        
        Swal.fire('Approved!', 'Payout has been approved successfully.', 'success');
        this.loadPayoutStats();
      }
    });
  }

  rejectPayout(payout: PayoutData): void {
    Swal.fire({
      title: 'Reject Payout',
      text: `Please provide a reason for rejecting the payout to ${payout.shopName}:`,
      input: 'textarea',
      inputPlaceholder: 'Rejection reason...',
      inputValidator: (value) => {
        if (!value) {
          return 'You need to provide a reason for rejection!';
        }
        return null;
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Reject',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#f44336'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update status locally
        const index = this.dataSource.data.findIndex(p => p.id === payout.id);
        if (index !== -1) {
          this.dataSource.data[index].status = 'REJECTED';
          this.dataSource.data[index].notes = result.value;
          this.dataSource.data[index].updatedAt = new Date().toISOString();
          this.dataSource._updateChangeSubscription();
        }
        
        Swal.fire('Rejected!', 'Payout has been rejected.', 'success');
        this.loadPayoutStats();
      }
    });
  }

  processPayout(payout: PayoutData): void {
    if (payout.status !== 'APPROVED') {
      this.snackBar.open('Payout must be approved before processing', 'Close', { duration: 3000 });
      return;
    }

    Swal.fire({
      title: 'Process Payout',
      text: `Confirm payment of ₹${payout.payoutAmount.toLocaleString()} to ${payout.shopName}?`,
      input: 'text',
      inputPlaceholder: 'Enter transaction ID',
      inputValidator: (value) => {
        if (!value) {
          return 'Transaction ID is required!';
        }
        return null;
      },
      icon: 'info',
      showCancelButton: true,
      confirmButtonText: 'Process Payment',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update status locally
        const index = this.dataSource.data.findIndex(p => p.id === payout.id);
        if (index !== -1) {
          this.dataSource.data[index].status = 'PAID';
          this.dataSource.data[index].payoutDate = new Date().toISOString();
          this.dataSource.data[index].transactionId = result.value;
          this.dataSource.data[index].updatedAt = new Date().toISOString();
          this.dataSource._updateChangeSubscription();
        }
        
        Swal.fire('Success!', 'Payout has been processed successfully.', 'success');
        this.loadPayoutStats();
      }
    });
  }

  viewPayoutDetails(payout: PayoutData): void {
    Swal.fire({
      title: `Payout Details - ${payout.shopName}`,
      html: `
        <div style="text-align: left; padding: 20px;">
          <p><strong>Shop Owner:</strong> ${payout.shopOwnerName}</p>
          <p><strong>Email:</strong> ${payout.shopOwnerEmail}</p>
          <p><strong>Period:</strong> ${payout.payoutPeriod}</p>
          <p><strong>Total Revenue:</strong> ₹${payout.totalRevenue.toLocaleString()}</p>
          <p><strong>Platform Commission:</strong> ₹${payout.platformCommission.toLocaleString()}</p>
          <p><strong>Payout Amount:</strong> ₹${payout.payoutAmount.toLocaleString()}</p>
          <p><strong>Bank Account:</strong> ${payout.bankAccount}</p>
          <p><strong>IFSC Code:</strong> ${payout.ifscCode}</p>
          <p><strong>Status:</strong> <span class="status-${payout.status.toLowerCase()}">${payout.status}</span></p>
          ${payout.transactionId ? `<p><strong>Transaction ID:</strong> ${payout.transactionId}</p>` : ''}
          ${payout.payoutDate ? `<p><strong>Payout Date:</strong> ${new Date(payout.payoutDate).toLocaleDateString()}</p>` : ''}
          ${payout.notes ? `<p><strong>Notes:</strong> ${payout.notes}</p>` : ''}
        </div>
      `,
      width: 600,
      confirmButtonText: 'Close'
    });
  }

  exportPayouts(): void {
    const csvData = this.dataSource.data.map(item => ({
      'Shop Name': item.shopName,
      'Shop Owner': item.shopOwnerName,
      'Email': item.shopOwnerEmail,
      'Period': item.payoutPeriod,
      'Total Revenue': item.totalRevenue,
      'Commission': item.platformCommission,
      'Payout Amount': item.payoutAmount,
      'Status': item.status,
      'Bank Account': item.bankAccount,
      'IFSC Code': item.ifscCode,
      'Transaction ID': item.transactionId || '',
      'Payout Date': item.payoutDate ? new Date(item.payoutDate).toLocaleDateString() : '',
      'Notes': item.notes || ''
    }));

    const csv = this.convertToCSV(csvData);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `payouts-${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    window.URL.revokeObjectURL(url);
    
    this.snackBar.open('Payout data exported successfully', 'Close', { duration: 3000 });
  }

  private convertToCSV(data: any[]): string {
    if (data.length === 0) return '';
    
    const headers = Object.keys(data[0]);
    const csvHeaders = headers.join(',');
    const csvRows = data.map(row => 
      headers.map(header => {
        const value = row[header];
        return typeof value === 'string' && value.includes(',') ? `"${value}"` : value;
      }).join(',')
    );
    
    return [csvHeaders, ...csvRows].join('\n');
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'PENDING': return 'status-pending';
      case 'APPROVED': return 'status-approved';
      case 'PAID': return 'status-paid';
      case 'REJECTED': return 'status-rejected';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    return status.charAt(0) + status.slice(1).toLowerCase();
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  formatDate(dateString?: string): string {
    return dateString ? new Date(dateString).toLocaleDateString() : '-';
  }
}