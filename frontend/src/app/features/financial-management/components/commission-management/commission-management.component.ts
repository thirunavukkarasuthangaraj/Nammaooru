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

export interface CommissionData {
  id: number;
  shopId: number;
  shopName: string;
  shopOwnerName: string;
  commissionType: 'PERCENTAGE' | 'FIXED';
  commissionRate: number;
  commissionAmount: number;
  minimumOrder: number;
  maximumCommission?: number;
  category: string;
  isActive: boolean;
  effectiveDate: string;
  createdAt: string;
  updatedAt: string;
}

@Component({
  selector: 'app-commission-management',
  templateUrl: './commission-management.component.html',
  styleUrls: ['./commission-management.component.scss']
})
export class CommissionManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = [
    'shopName',
    'shopOwnerName',
    'category',
    'commissionType',
    'commissionRate',
    'minimumOrder',
    'maximumCommission',
    'status',
    'effectiveDate',
    'actions'
  ];

  dataSource = new MatTableDataSource<CommissionData>();
  loading = false;
  searchTerm = '';
  statusFilter = '';
  typeFilter = '';

  statusOptions = [
    { value: '', label: 'All Status' },
    { value: 'true', label: 'Active' },
    { value: 'false', label: 'Inactive' }
  ];

  typeOptions = [
    { value: '', label: 'All Types' },
    { value: 'PERCENTAGE', label: 'Percentage' },
    { value: 'FIXED', label: 'Fixed Amount' }
  ];

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadCommissionData();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadCommissionData(): void {
    this.loading = true;
    const apiUrl = `${environment.apiUrl}/financial/commissions`;
    
    this.http.get<{data: CommissionData[]}>(apiUrl).pipe(
      catchError(() => {
        this.loadMockCommissionData();
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
        console.error('Error loading commission data:', error);
        this.loadMockCommissionData();
        this.loading = false;
      }
    });
  }

  private loadMockCommissionData(): void {
    const mockData: CommissionData[] = [
      {
        id: 1,
        shopId: 1,
        shopName: 'Annamalai Stores',
        shopOwnerName: 'Annamalai Raman',
        commissionType: 'PERCENTAGE',
        commissionRate: 10.0,
        commissionAmount: 0,
        minimumOrder: 100,
        maximumCommission: 500,
        category: 'Grocery',
        isActive: true,
        effectiveDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        shopId: 2,
        shopName: 'Saravana Medical',
        shopOwnerName: 'Dr. Saravanan',
        commissionType: 'PERCENTAGE',
        commissionRate: 8.0,
        commissionAmount: 0,
        minimumOrder: 200,
        maximumCommission: 300,
        category: 'Pharmacy',
        isActive: true,
        effectiveDate: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        shopId: 5,
        shopName: 'Digital Electronics Hub',
        shopOwnerName: 'Suresh Kumar',
        commissionType: 'FIXED',
        commissionRate: 0,
        commissionAmount: 50,
        minimumOrder: 1000,
        category: 'Electronics',
        isActive: false,
        effectiveDate: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 75 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 4,
        shopId: 7,
        shopName: 'Textile Paradise',
        shopOwnerName: 'Ravi Shankar',
        commissionType: 'PERCENTAGE',
        commissionRate: 12.0,
        commissionAmount: 0,
        minimumOrder: 500,
        maximumCommission: 800,
        category: 'Clothing',
        isActive: true,
        effectiveDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 5,
        shopId: 8,
        shopName: 'Sports Zone',
        shopOwnerName: 'Vijay Kumar',
        commissionType: 'PERCENTAGE',
        commissionRate: 9.5,
        commissionAmount: 0,
        minimumOrder: 300,
        maximumCommission: 600,
        category: 'Sports',
        isActive: true,
        effectiveDate: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 40 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 6,
        shopId: 6,
        shopName: 'Flower Garden Store',
        shopOwnerName: 'Lakshmi Devi',
        commissionType: 'PERCENTAGE',
        commissionRate: 15.0,
        commissionAmount: 0,
        minimumOrder: 50,
        maximumCommission: 200,
        category: 'Flowers & Gifts',
        isActive: true,
        effectiveDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];

    this.dataSource.data = mockData;
    this.snackBar.open('Loaded mock commission data - API not available', 'Close', { duration: 3000 });
  }

  applyFilter(): void {
    let filteredData = this.dataSource.data;

    if (this.searchTerm) {
      filteredData = filteredData.filter(commission =>
        commission.shopName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        commission.shopOwnerName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        commission.category.toLowerCase().includes(this.searchTerm.toLowerCase())
      );
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(commission => 
        commission.isActive.toString() === this.statusFilter
      );
    }

    if (this.typeFilter) {
      filteredData = filteredData.filter(commission => 
        commission.commissionType === this.typeFilter
      );
    }

    this.dataSource.data = filteredData;
  }

  editCommission(commission: CommissionData): void {
    Swal.fire({
      title: 'Edit Commission',
      html: `
        <div style="text-align: left;">
          <label>Commission Type:</label>
          <select id="commissionType" class="swal2-input">
            <option value="PERCENTAGE" ${commission.commissionType === 'PERCENTAGE' ? 'selected' : ''}>Percentage</option>
            <option value="FIXED" ${commission.commissionType === 'FIXED' ? 'selected' : ''}>Fixed Amount</option>
          </select>
          <input id="commissionRate" class="swal2-input" placeholder="Commission Rate/Amount" value="${commission.commissionType === 'PERCENTAGE' ? commission.commissionRate : commission.commissionAmount}">
          <input id="minimumOrder" class="swal2-input" placeholder="Minimum Order" value="${commission.minimumOrder}">
          <input id="maximumCommission" class="swal2-input" placeholder="Maximum Commission (optional)" value="${commission.maximumCommission || ''}">
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Update',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const type = (document.getElementById('commissionType') as HTMLSelectElement).value;
        const rate = (document.getElementById('commissionRate') as HTMLInputElement).value;
        const minOrder = (document.getElementById('minimumOrder') as HTMLInputElement).value;
        const maxCommission = (document.getElementById('maximumCommission') as HTMLInputElement).value;

        if (!rate || !minOrder) {
          Swal.showValidationMessage('Please fill all required fields');
          return false;
        }

        return { type, rate: parseFloat(rate), minOrder: parseFloat(minOrder), maxCommission: maxCommission ? parseFloat(maxCommission) : undefined };
      }
    }).then((result) => {
      if (result.isConfirmed) {
        // Update locally
        const index = this.dataSource.data.findIndex(c => c.id === commission.id);
        if (index !== -1) {
          const updatedCommission = { ...this.dataSource.data[index] };
          updatedCommission.commissionType = result.value.type;
          if (result.value.type === 'PERCENTAGE') {
            updatedCommission.commissionRate = result.value.rate;
            updatedCommission.commissionAmount = 0;
          } else {
            updatedCommission.commissionAmount = result.value.rate;
            updatedCommission.commissionRate = 0;
          }
          updatedCommission.minimumOrder = result.value.minOrder;
          updatedCommission.maximumCommission = result.value.maxCommission;
          updatedCommission.updatedAt = new Date().toISOString();
          
          this.dataSource.data[index] = updatedCommission;
          this.dataSource._updateChangeSubscription();
        }
        
        Swal.fire('Success!', 'Commission updated successfully', 'success');
      }
    });
  }

  toggleStatus(commission: CommissionData): void {
    const action = commission.isActive ? 'deactivate' : 'activate';
    
    Swal.fire({
      title: `${action.charAt(0).toUpperCase() + action.slice(1)} Commission`,
      text: `Are you sure you want to ${action} commission for ${commission.shopName}?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: `Yes, ${action}`,
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update status locally
        const index = this.dataSource.data.findIndex(c => c.id === commission.id);
        if (index !== -1) {
          this.dataSource.data[index].isActive = !commission.isActive;
          this.dataSource.data[index].updatedAt = new Date().toISOString();
          this.dataSource._updateChangeSubscription();
        }
        
        Swal.fire('Success!', `Commission ${action}d successfully`, 'success');
      }
    });
  }

  viewCommissionDetails(commission: CommissionData): void {
    const commissionDisplay = commission.commissionType === 'PERCENTAGE' 
      ? `${commission.commissionRate}%`
      : `₹${commission.commissionAmount}`;

    Swal.fire({
      title: `Commission Details - ${commission.shopName}`,
      html: `
        <div style="text-align: left; padding: 20px;">
          <p><strong>Shop Owner:</strong> ${commission.shopOwnerName}</p>
          <p><strong>Category:</strong> ${commission.category}</p>
          <p><strong>Commission Type:</strong> ${commission.commissionType}</p>
          <p><strong>Commission:</strong> ${commissionDisplay}</p>
          <p><strong>Minimum Order:</strong> ₹${commission.minimumOrder.toLocaleString()}</p>
          ${commission.maximumCommission ? `<p><strong>Maximum Commission:</strong> ₹${commission.maximumCommission.toLocaleString()}</p>` : ''}
          <p><strong>Status:</strong> <span style="color: ${commission.isActive ? 'green' : 'red'}">${commission.isActive ? 'Active' : 'Inactive'}</span></p>
          <p><strong>Effective Date:</strong> ${new Date(commission.effectiveDate).toLocaleDateString()}</p>
          <p><strong>Last Updated:</strong> ${new Date(commission.updatedAt).toLocaleDateString()}</p>
        </div>
      `,
      width: 600,
      confirmButtonText: 'Close'
    });
  }

  getStatusClass(isActive: boolean): string {
    return isActive ? 'status-active' : 'status-inactive';
  }

  getTypeLabel(type: string): string {
    return type === 'PERCENTAGE' ? 'Percentage' : 'Fixed Amount';
  }

  formatCommission(commission: CommissionData): string {
    return commission.commissionType === 'PERCENTAGE' 
      ? `${commission.commissionRate}%`
      : `₹${commission.commissionAmount}`;
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString();
  }
}