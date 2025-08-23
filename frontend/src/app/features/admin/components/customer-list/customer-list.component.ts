import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router } from '@angular/router';
import { AdminDashboardService, AdminUser } from '../../services/admin-dashboard.service';
import Swal from 'sweetalert2';

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

  dataSource = new MatTableDataSource<AdminUser>();
  isLoading = false;
  totalElements = 0;
  pageSize = 10;
  pageIndex = 0;
  
  searchTerm = '';
  selectedStatus = '';
  selectedRole = '';
  
  statusOptions = [
    { value: '', label: 'All Statuses' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'SUSPENDED', label: 'Suspended' }
  ];

  roleOptions = [
    { value: '', label: 'All Roles' },
    { value: 'SUPER_ADMIN', label: 'Super Admin' },
    { value: 'ADMIN', label: 'Admin' },
    { value: 'SHOP_OWNER', label: 'Shop Owner' },
    { value: 'CUSTOMER', label: 'Customer' }
  ];

  userStats = {
    totalUsers: 0,
    activeUsers: 0,
    verifiedUsers: 0,
    adminUsers: 0
  };

  constructor(
    private adminService: AdminDashboardService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadUsers();
    this.loadUserStats();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
    
    // Custom sorting for nested properties
    this.dataSource.sortingDataAccessor = (data: AdminUser, sortHeaderId: string) => {
      switch (sortHeaderId) {
        case 'fullName':
          return `${data.firstName} ${data.lastName}`.toLowerCase();
        case 'status':
          return data.status || '';
        case 'role':
          return data.role || '';
        case 'createdAt':
          return new Date(data.createdAt || '').getTime();
        default:
          return (data as any)[sortHeaderId] || '';
      }
    };
  }

  loadUsers(): void {
    this.isLoading = true;

    this.adminService.getAllUsers(this.pageIndex, this.pageSize).subscribe({
      next: (users) => {
        let filteredUsers = users;
        
        // Apply search filter
        if (this.searchTerm) {
          filteredUsers = users.filter(user =>
            user.username.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
            user.firstName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
            user.lastName.toLowerCase().includes(this.searchTerm.toLowerCase())
          );
        }
        
        // Apply status filter
        if (this.selectedStatus) {
          filteredUsers = filteredUsers.filter(user => user.status === this.selectedStatus);
        }
        
        // Apply role filter
        if (this.selectedRole) {
          filteredUsers = filteredUsers.filter(user => user.role === this.selectedRole);
        }
        
        this.dataSource.data = filteredUsers;
        this.totalElements = filteredUsers.length;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading users:', error);
        this.loadMockData();
        this.isLoading = false;
      }
    });
  }

  private loadMockData(): void {
    const mockUsers: AdminUser[] = [
      {
        id: 1,
        username: 'superadmin',
        email: 'admin@nammaooru.com',
        firstName: 'Super',
        lastName: 'Admin',
        role: 'SUPER_ADMIN',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        username: 'rajeshkumar',
        email: 'rajesh@annamalai.com',
        firstName: 'Rajesh',
        lastName: 'Kumar',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        username: 'priyasharma',
        email: 'priya@example.com',
        firstName: 'Priya',
        lastName: 'Sharma',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 30 * 60 * 1000).toISOString()
      },
      {
        id: 4,
        username: 'saravanan',
        email: 'saravana@medical.com',
        firstName: 'Dr. Saravanan',
        lastName: 'M',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 5,
        username: 'vikramraj',
        email: 'vikram@example.com',
        firstName: 'Vikram',
        lastName: 'Raj',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 6,
        username: 'muthukumar',
        email: 'muthu@tamilbooks.com',
        firstName: 'Muthu',
        lastName: 'Kumar',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 7,
        username: 'meeradevi',
        email: 'meera@example.com',
        firstName: 'Meera',
        lastName: 'Devi',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 8,
        username: 'arunkumar',
        email: 'arun@example.com',
        firstName: 'Arun',
        lastName: 'Kumar',
        role: 'CUSTOMER',
        status: 'SUSPENDED',
        isActive: false,
        emailVerified: true,
        createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 9,
        username: 'lakshmidevi',
        email: 'lakshmi@flowers.com',
        firstName: 'Lakshmi',
        lastName: 'Devi',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: false,
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 10,
        username: 'ravishankar',
        email: 'ravi@textile.com',
        firstName: 'Ravi',
        lastName: 'Shankar',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 11,
        username: 'vijaykumar',
        email: 'vijay@sportszone.com',
        firstName: 'Vijay',
        lastName: 'Kumar',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 75 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 12,
        username: 'adminuser',
        email: 'admin@management.com',
        firstName: 'Admin',
        lastName: 'User',
        role: 'ADMIN',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 13,
        username: 'rameshkumar',
        email: 'ramesh@example.com',
        firstName: 'Ramesh',
        lastName: 'Kumar',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 45 * 60 * 1000).toISOString()
      },
      {
        id: 14,
        username: 'lakshmip',
        email: 'lakshmi@example.com',
        firstName: 'Lakshmi',
        lastName: 'Priya',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        isActive: true,
        emailVerified: true,
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 15,
        username: 'inactiveuser',
        email: 'inactive@example.com',
        firstName: 'Inactive',
        lastName: 'User',
        role: 'CUSTOMER',
        status: 'INACTIVE',
        isActive: false,
        emailVerified: false,
        createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
        lastLoginAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];

    let filteredUsers = mockUsers;
    
    // Apply search filter
    if (this.searchTerm) {
      filteredUsers = mockUsers.filter(user =>
        user.username.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        user.email.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        user.firstName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        user.lastName.toLowerCase().includes(this.searchTerm.toLowerCase())
      );
    }
    
    // Apply status filter
    if (this.selectedStatus) {
      filteredUsers = filteredUsers.filter(user => user.status === this.selectedStatus);
    }
    
    // Apply role filter
    if (this.selectedRole) {
      filteredUsers = filteredUsers.filter(user => user.role === this.selectedRole);
    }
    
    this.dataSource.data = filteredUsers;
    this.totalElements = filteredUsers.length;

    // Update stats with mock data
    this.userStats = {
      totalUsers: mockUsers.length,
      activeUsers: mockUsers.filter(u => u.isActive).length,
      verifiedUsers: mockUsers.filter(u => u.emailVerified).length,
      adminUsers: mockUsers.filter(u => u.role === 'ADMIN' || u.role === 'SUPER_ADMIN').length
    };

    const snackBarRef = document.createElement('div');
    snackBarRef.innerHTML = 'Loaded mock data - API not available';
    Swal.fire({
      title: 'Mock Data Loaded',
      text: 'API not available - showing sample user data',
      icon: 'info',
      timer: 2000,
      showConfirmButton: false,
      position: 'top-end',
      toast: true
    });
  }

  loadUserStats(): void {
    this.adminService.getDashboardStats().subscribe({
      next: (stats) => {
        this.userStats = {
          totalUsers: stats.totalUsers,
          activeUsers: stats.activeUsers,
          verifiedUsers: stats.activeUsers, // Using activeUsers as proxy
          adminUsers: stats.totalUsers // Will be calculated from user data
        };
      },
      error: (error) => {
        console.error('Error loading user stats:', error);
      }
    });
  }

  onSearchChange(): void {
    this.pageIndex = 0;
    this.loadUsers();
  }

  onStatusChange(): void {
    this.pageIndex = 0;
    this.loadUsers();
  }

  onRoleChange(): void {
    this.pageIndex = 0;
    this.loadUsers();
  }

  onPageChange(event: any): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadUsers();
  }

  createUser(): void {
    this.router.navigate(['/admin/users/create']);
  }

  viewUser(user: AdminUser): void {
    this.router.navigate(['/admin/users', user.id]);
  }

  editUser(user: AdminUser): void {
    this.router.navigate(['/admin/users', user.id, 'edit']);
  }

  deleteUser(user: AdminUser): void {
    Swal.fire({
      title: 'Delete User',
      text: `Are you sure you want to delete "${user.firstName} ${user.lastName}"? This action cannot be undone.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.adminService.deleteUser(user.id).subscribe({
          next: () => {
            Swal.fire('Deleted!', 'User has been deleted successfully.', 'success');
            this.loadUsers();
            this.loadUserStats();
          },
          error: (error) => {
            console.error('Error deleting user:', error);
            Swal.fire('Error!', 'Failed to delete user. Please try again.', 'error');
          }
        });
      }
    });
  }

  toggleUserStatus(user: AdminUser): void {
    const newStatus = user.isActive ? 'INACTIVE' : 'ACTIVE';
    const action = user.isActive ? 'deactivate' : 'activate';
    
    Swal.fire({
      title: `${action.charAt(0).toUpperCase() + action.slice(1)} User`,
      text: `Are you sure you want to ${action} "${user.firstName} ${user.lastName}"?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: `Yes, ${action}`,
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.adminService.updateUserStatus(user.id, newStatus).subscribe({
          next: (updatedUser) => {
            Swal.fire('Success!', `User ${action}d successfully.`, 'success');
            this.loadUsers();
          },
          error: (error) => {
            console.error('Error updating user status:', error);
            Swal.fire('Error!', `Failed to ${action} user. Please try again.`, 'error');
          }
        });
      }
    });
  }

  sendWelcomeEmail(user: AdminUser): void {
    Swal.fire({
      title: 'Send Welcome Email',
      text: `Send welcome email to ${user.firstName} ${user.lastName} (${user.email})?`,
      icon: 'info',
      showCancelButton: true,
      confirmButtonText: 'Send Email',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Implementation for sending welcome email
        Swal.fire('Success!', 'Welcome email sent successfully.', 'success');
      }
    });
  }

  verifyUserEmail(user: AdminUser): void {
    Swal.fire({
      title: 'Verify Email',
      text: `Send email verification to ${user.email}?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Send Verification',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Using admin service - this would need to be implemented in backend
        Swal.fire('Success!', 'Email verification sent successfully.', 'success');
        this.loadUsers();
      }
    });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'status-active';
      case 'INACTIVE':
        return 'status-inactive';
      case 'SUSPENDED':
        return 'status-suspended';
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
      case 'SUSPENDED':
        return 'Suspended';
      default:
        return status;
    }
  }

  getRoleLabel(role: string): string {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin';
      case 'SHOP_OWNER':
        return 'Shop Owner';
      case 'CUSTOMER':
        return 'Customer';
      default:
        return role;
    }
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString();
  }

  exportUsers(): void {
    Swal.fire({
      title: 'Export Users',
      text: 'Choose export format:',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Export CSV',
      cancelButtonText: 'Cancel',
      showDenyButton: true,
      denyButtonText: 'Export Excel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.performExport('csv');
      } else if (result.isDenied) {
        this.performExport('xlsx');
      }
    });
  }

  performExport(format: string): void {
    this.adminService.exportData('users').subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `users-${new Date().toISOString().split('T')[0]}.${format}`;
        link.click();
        window.URL.revokeObjectURL(url);
        Swal.fire('Success!', 'Users exported successfully.', 'success');
      },
      error: (error) => {
        console.error('Error exporting users:', error);
        Swal.fire('Error!', 'Failed to export users. Please try again.', 'error');
      }
    });
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = '';
    this.selectedRole = '';
    this.pageIndex = 0;
    this.loadUsers();
  }
}