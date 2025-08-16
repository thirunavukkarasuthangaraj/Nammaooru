import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router } from '@angular/router';
import { CustomerService, Customer, CustomerSearchParams } from '../../../../core/services/customer.service';

@Component({
  selector: 'app-customer-list',
  templateUrl: './customer-list.component.html',
  styleUrls: ['./customer-list.component.scss']
})
export class CustomerListComponent implements OnInit, AfterViewInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = [
    'fullName',
    'email',
    'mobileNumber',
    'city',
    'status',
    'totalOrders',
    'totalSpent',
    'createdAt',
    'actions'
  ];

  dataSource = new MatTableDataSource<Customer>();
  isLoading = false;
  totalElements = 0;
  pageSize = 10;
  pageIndex = 0;
  
  searchTerm = '';
  selectedStatus = '';
  selectedCity = '';
  
  statusOptions = [
    { value: '', label: 'All Statuses' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'BLOCKED', label: 'Blocked' },
    { value: 'PENDING_VERIFICATION', label: 'Pending Verification' }
  ];

  cities: string[] = [];
  customerStats = {
    totalCustomers: 0,
    activeCustomers: 0,
    verifiedCustomers: 0,
    totalSpending: 0
  };

  constructor(
    private customerService: CustomerService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCustomers();
    this.loadCustomerStats();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
    
    // Custom sorting for nested properties
    this.dataSource.sortingDataAccessor = (data: Customer, sortHeaderId: string) => {
      switch (sortHeaderId) {
        case 'fullName':
          return `${data.firstName} ${data.lastName}`.toLowerCase();
        case 'status':
          return data.status || '';
        case 'totalSpent':
          return data.totalSpent || 0;
        case 'totalOrders':
          return data.totalOrders || 0;
        case 'createdAt':
          return new Date(data.createdAt || '').getTime();
        default:
          return (data as any)[sortHeaderId] || '';
      }
    };
  }

  loadCustomers(): void {
    this.isLoading = true;
    
    const params: CustomerSearchParams = {
      page: this.pageIndex,
      size: this.pageSize,
      searchTerm: this.searchTerm || undefined,
      status: this.selectedStatus || undefined
    };

    this.customerService.getAllCustomers(params).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.totalElements = response.totalElements;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading customers:', error);
        this.isLoading = false;
      }
    });
  }

  loadCustomerStats(): void {
    this.customerService.getCustomerStats().subscribe({
      next: (stats) => {
        this.customerStats = stats;
      },
      error: (error) => {
        console.error('Error loading customer stats:', error);
      }
    });
  }

  onSearchChange(): void {
    this.pageIndex = 0;
    this.loadCustomers();
  }

  onStatusChange(): void {
    this.pageIndex = 0;
    this.loadCustomers();
  }

  onCityChange(): void {
    this.pageIndex = 0;
    this.loadCustomers();
  }

  onPageChange(event: any): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadCustomers();
  }

  createCustomer(): void {
    this.router.navigate(['/admin/customers/create']);
  }

  viewCustomer(customer: Customer): void {
    this.router.navigate(['/admin/customers', customer.id]);
  }

  editCustomer(customer: Customer): void {
    this.router.navigate(['/admin/customers', customer.id, 'edit']);
  }

  deleteCustomer(customer: Customer): void {
    if (confirm(`Are you sure you want to delete customer "${customer.firstName} ${customer.lastName}"?`)) {
      this.customerService.deleteCustomer(customer.id!).subscribe({
        next: () => {
          console.log('Customer deleted successfully');
          this.loadCustomers();
          this.loadCustomerStats();
        },
        error: (error) => {
          console.error('Error deleting customer:', error);
        }
      });
    }
  }

  toggleCustomerStatus(customer: Customer): void {
    const newStatus = customer.isActive ? false : true;
    this.customerService.updateCustomer(customer.id!, { ...customer, isActive: newStatus }).subscribe({
      next: (updatedCustomer) => {
        console.log('Customer status updated:', updatedCustomer);
        this.loadCustomers();
      },
      error: (error) => {
        console.error('Error updating customer status:', error);
      }
    });
  }

  sendWelcomeEmail(customer: Customer): void {
    // Implementation for sending welcome email
    console.log('Sending welcome email to:', customer.email);
  }

  verifyCustomerEmail(customer: Customer): void {
    this.customerService.verifyEmail(customer.id!).subscribe({
      next: (result) => {
        console.log('Email verification sent:', result);
        this.loadCustomers();
      },
      error: (error) => {
        console.error('Error sending email verification:', error);
      }
    });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'status-active';
      case 'INACTIVE':
        return 'status-inactive';
      case 'BLOCKED':
        return 'status-blocked';
      case 'PENDING_VERIFICATION':
        return 'status-pending';
      default:
        return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'BLOCKED':
        return 'Blocked';
      case 'PENDING_VERIFICATION':
        return 'Pending';
      default:
        return status;
    }
  }

  formatCurrency(amount: number): string {
    return this.customerService.formatCurrency(amount || 0);
  }

  formatDate(dateString: string): string {
    return this.customerService.formatDate(dateString);
  }

  exportCustomers(): void {
    this.customerService.exportCustomers('csv').subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `customers-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
      },
      error: (error) => {
        console.error('Error exporting customers:', error);
      }
    });
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = '';
    this.selectedCity = '';
    this.pageIndex = 0;
    this.loadCustomers();
  }
}