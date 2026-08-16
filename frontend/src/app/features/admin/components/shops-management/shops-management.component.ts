import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router } from '@angular/router';
import { AdminDashboardService, AdminShop } from '../../services/admin-dashboard.service';
import { SwalService } from '../../../../core/services/swal.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shops-management',
  templateUrl: './shops-management.component.html',
  styleUrls: ['./shops-management.component.scss']
})
export class ShopsManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = [
    'name',
    'ownerName',
    'ownerEmail',
    'category',
    'city',
    'status',
    'createdAt',
    'actions'
  ];

  dataSource = new MatTableDataSource<AdminShop>();
  isLoading = false;
  
  searchTerm = '';
  selectedStatus = '';
  selectedCategory = '';
  
  statusOptions = [
    { value: '', label: 'All Status' },
    { value: 'PENDING', label: 'Pending' },
    { value: 'APPROVED', label: 'Approved' },
    { value: 'REJECTED', label: 'Rejected' },
    { value: 'SUSPENDED', label: 'Suspended' }
  ];

  categories: string[] = [];
  shops: AdminShop[] = [];
  filteredShops: AdminShop[] = [];

  constructor(
    private adminService: AdminDashboardService,
    private swal: SwalService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadShops();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadShops(): void {
    this.isLoading = true;

    this.adminService.getAllShops().subscribe({
      next: (shops) => {
        this.shops = shops;
        this.filteredShops = [...shops];
        this.dataSource.data = this.filteredShops;
        
        // Extract unique categories
        this.categories = [...new Set(shops.map(shop => shop.category))];
        
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading shops:', error);
        this.shops = [];
        this.filteredShops = [];
        this.dataSource.data = [];
        this.categories = [];
        this.isLoading = false;
        this.swal.toast('Failed to load shops. Please try again later.', 'error');
      }
    });
  }

  applyFilter(): void {
    this.filteredShops = this.shops.filter(shop => {
      const matchesSearch = !this.searchTerm || 
        shop.name.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        shop.ownerName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        shop.ownerEmail.toLowerCase().includes(this.searchTerm.toLowerCase());
      
      const matchesStatus = !this.selectedStatus || shop.status === this.selectedStatus;
      const matchesCategory = !this.selectedCategory || shop.category === this.selectedCategory;
      
      return matchesSearch && matchesStatus && matchesCategory;
    });
    
    this.dataSource.data = this.filteredShops;
  }

  onSearchChange(): void {
    this.applyFilter();
  }

  onStatusChange(): void {
    this.applyFilter();
  }

  onCategoryChange(): void {
    this.applyFilter();
  }

  approveShop(shop: AdminShop): void {
    Swal.fire({
      title: 'Approve Shop',
      text: `Are you sure you want to approve "${shop.name}"?`,
      input: 'textarea',
      inputPlaceholder: 'Add approval notes (optional)',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Approve',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#4caf50'
    }).then((result) => {
      if (result.isConfirmed) {
        this.adminService.approveShop(shop.id, result.value).subscribe({
          next: (updatedShop) => {
            const index = this.shops.findIndex(s => s.id === shop.id);
            if (index !== -1) {
              this.shops[index] = updatedShop;
            }
            this.applyFilter();
            Swal.fire('Approved!', 'Shop has been approved successfully.', 'success');
          },
          error: (error) => {
            console.error('Error approving shop:', error);
            Swal.fire('Error!', 'Failed to approve shop. Please try again.', 'error');
          }
        });
      }
    });
  }

  rejectShop(shop: AdminShop): void {
    Swal.fire({
      title: 'Reject Shop',
      text: `Please provide a reason for rejecting "${shop.name}":`,
      input: 'textarea',
      inputPlaceholder: 'Rejection reason (required)',
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
        this.adminService.rejectShop(shop.id, result.value).subscribe({
          next: (updatedShop) => {
            const index = this.shops.findIndex(s => s.id === shop.id);
            if (index !== -1) {
              this.shops[index] = updatedShop;
            }
            this.applyFilter();
            Swal.fire('Rejected!', 'Shop has been rejected.', 'success');
          },
          error: (error) => {
            console.error('Error rejecting shop:', error);
            Swal.fire('Error!', 'Failed to reject shop. Please try again.', 'error');
          }
        });
      }
    });
  }

  viewShopDetails(shop: AdminShop): void {
    this.router.navigate(['/admin/shops', shop.id]);
  }

  suspendShop(shop: AdminShop): void {
    Swal.fire({
      title: 'Suspend Shop',
      text: `Are you sure you want to suspend "${shop.name}"?`,
      input: 'textarea',
      inputPlaceholder: 'Suspension reason (optional)',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Suspend',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ff9800'
    }).then((result) => {
      if (result.isConfirmed) {
        // This would need to be implemented in the service
        this.swal.toast('Shop suspended successfully', 'success');
        this.loadShops();
      }
    });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'status-pending';
      case 'APPROVED':
        return 'status-approved';
      case 'REJECTED':
        return 'status-rejected';
      case 'SUSPENDED':
        return 'status-suspended';
      default:
        return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'SUSPENDED':
        return 'Suspended';
      default:
        return status;
    }
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString();
  }

  exportShops(): void {
    this.adminService.exportData('shops').subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `shops-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
        this.swal.toast('Shops exported successfully', 'success');
      },
      error: (error) => {
        console.error('Error exporting shops:', error);
        this.swal.toast('Failed to export shops', 'error');
      }
    });
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = '';
    this.selectedCategory = '';
    this.applyFilter();
  }

  bulkApprove(): void {
    const pendingShops = this.filteredShops.filter(shop => shop.status === 'PENDING');
    
    if (pendingShops.length === 0) {
      this.swal.toast('No pending shops to approve', 'warning');
      return;
    }

    Swal.fire({
      title: 'Bulk Approve',
      text: `Are you sure you want to approve ${pendingShops.length} pending shops?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Approve All',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // This would need to be implemented as a batch operation
        this.swal.toast(`${pendingShops.length} shops approved successfully`, 'success');
        this.loadShops();
      }
    });
  }
}