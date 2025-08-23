import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { AdminDashboardService, AdminShop } from '../../services/admin-dashboard.service';
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
    private snackBar: MatSnackBar,
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
        this.loadMockShops();
        this.isLoading = false;
      }
    });
  }

  private loadMockShops(): void {
    const mockShops: AdminShop[] = [
      {
        id: 1,
        name: 'Annamalai Stores',
        description: 'Fresh vegetables and daily essentials',
        ownerName: 'Annamalai Raman',
        ownerEmail: 'annamalai@stores.com',
        ownerPhone: '+91 98765 43210',
        category: 'Grocery',
        status: 'APPROVED',
        isActive: true,
        addressLine1: '123 T.Nagar Main Road',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600017',
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        approvedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        name: 'Saravana Medical',
        description: 'Medicines and healthcare products',
        ownerName: 'Dr. Saravanan',
        ownerEmail: 'saravana@medical.com',
        ownerPhone: '+91 98765 43211',
        category: 'Pharmacy',
        status: 'PENDING',
        isActive: false,
        addressLine1: '456 Adyar Main Road',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600020',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        name: 'Tamil Books Corner',
        description: 'Tamil literature and educational books',
        ownerName: 'Muthu Kumar',
        ownerEmail: 'muthu@tamilbooks.com',
        ownerPhone: '+91 98765 43212',
        category: 'Books',
        status: 'APPROVED',
        isActive: true,
        addressLine1: '789 Mylapore Street',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600004',
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        approvedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 4,
        name: 'Fresh Fish Market',
        description: 'Daily fresh fish and seafood',
        ownerName: 'Kamal Haasan',
        ownerEmail: 'kamal@fishmarket.com',
        ownerPhone: '+91 98765 43213',
        category: 'Seafood',
        status: 'SUSPENDED',
        isActive: false,
        addressLine1: '321 Marina Beach Road',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600001',
        createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
        approvedAt: new Date(Date.now() - 40 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 5,
        name: 'Digital Electronics Hub',
        description: 'Mobile phones, laptops and accessories',
        ownerName: 'Suresh Kumar',
        ownerEmail: 'suresh@electronics.com',
        ownerPhone: '+91 98765 43214',
        category: 'Electronics',
        status: 'REJECTED',
        isActive: false,
        addressLine1: '555 Anna Salai',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600002',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        rejectedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        rejectionReason: 'Incomplete documentation submitted'
      },
      {
        id: 6,
        name: 'Flower Garden Store',
        description: 'Fresh flowers and decorative items',
        ownerName: 'Lakshmi Devi',
        ownerEmail: 'lakshmi@flowers.com',
        ownerPhone: '+91 98765 43215',
        category: 'Flowers & Gifts',
        status: 'PENDING',
        isActive: false,
        addressLine1: '888 Pondy Bazaar',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600017',
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 7,
        name: 'Textile Paradise',
        description: 'Traditional and modern clothing',
        ownerName: 'Ravi Shankar',
        ownerEmail: 'ravi@textile.com',
        ownerPhone: '+91 98765 43216',
        category: 'Clothing',
        status: 'APPROVED',
        isActive: true,
        addressLine1: '999 Ranganathan Street',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600017',
        createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
        approvedAt: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 8,
        name: 'Sports Zone',
        description: 'Cricket, football and fitness equipment',
        ownerName: 'Vijay Kumar',
        ownerEmail: 'vijay@sportszone.com',
        ownerPhone: '+91 98765 43217',
        category: 'Sports',
        status: 'APPROVED',
        isActive: true,
        addressLine1: '777 Velachery Road',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600042',
        createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
        approvedAt: new Date(Date.now() - 55 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];

    this.shops = mockShops;
    this.filteredShops = [...mockShops];
    this.dataSource.data = this.filteredShops;
    
    // Extract unique categories
    this.categories = [...new Set(mockShops.map(shop => shop.category))];
    
    this.snackBar.open('Loaded mock data - API not available', 'Close', { duration: 3000 });
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
        this.snackBar.open('Shop suspended successfully', 'Close', { duration: 3000 });
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
        this.snackBar.open('Shops exported successfully', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error exporting shops:', error);
        this.snackBar.open('Failed to export shops', 'Close', { duration: 3000 });
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
      this.snackBar.open('No pending shops to approve', 'Close', { duration: 3000 });
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
        this.snackBar.open(`${pendingShops.length} shops approved successfully`, 'Close', { duration: 3000 });
        this.loadShops();
      }
    });
  }
}