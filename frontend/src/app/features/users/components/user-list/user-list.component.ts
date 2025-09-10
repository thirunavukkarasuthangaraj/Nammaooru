import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router, ActivatedRoute } from '@angular/router';
import { UserService, UserResponse } from '../../../../core/services/user.service';

export interface User {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  role: string;
  status: string;
  department: string;
  designation: string;
  isActive: boolean;
  emailVerified: boolean;
  lastLogin: string;
  createdAt: string;
}

@Component({
  selector: 'app-user-list',
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['fullName', 'email', 'role', 'department', 'status', 'lastLogin', 'actions'];
  dataSource = new MatTableDataSource<UserResponse>();
  originalData: UserResponse[] = [];
  loading = false;
  searchText = '';
  roleFilter = '';
  statusFilter = '';
  
  roleOptions = [
    { value: '', label: 'All Roles' },
    { value: 'SUPER_ADMIN', label: 'Super Admin' },
    { value: 'ADMIN', label: 'Admin' },
    { value: 'SHOP_OWNER', label: 'Shop Owner' },
    { value: 'MANAGER', label: 'Manager' },
    { value: 'EMPLOYEE', label: 'Employee' },
    { value: 'CUSTOMER_SERVICE', label: 'Customer Service' },
    { value: 'DELIVERY_AGENT', label: 'Delivery Agent' },
    { value: 'USER', label: 'User' }
  ];

  statusOptions = [
    { value: '', label: 'All Statuses' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'SUSPENDED', label: 'Suspended' },
    { value: 'PENDING_VERIFICATION', label: 'Pending Verification' }
  ];

  constructor(
    private userService: UserService,
    private snackBar: MatSnackBar,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    // Check if there's a role filter from route data
    const routeRole = this.route.snapshot.data['role'];
    if (routeRole) {
      this.roleFilter = routeRole;
    }
    this.loadUsers();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadUsers(): void {
    this.loading = true;
    
    // Use role-specific API if role filter is set
    const apiCall = this.roleFilter ? 
      this.userService.getUsersByRole(this.roleFilter, 0, 100) : 
      this.userService.getAllUsers(0, 100);
    
    apiCall.subscribe({
      next: (response) => {
        console.log('✅ Users API SUCCESS:', response); // Debug log
        console.log('Real API Users data:', response.content); // Debug log
        this.originalData = response.content;
        this.dataSource.data = [...this.originalData];
        this.loading = false;
        
        const roleMessage = this.roleFilter ? `${this.roleFilter} users` : 'all users';
        this.snackBar.open(`✅ Loaded ${roleMessage} successfully!`, 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('❌ Error loading users from API:', error);
        console.log('🔄 Falling back to mock data...');
        this.loadMockData();
        this.loading = false;
      }
    });
  }

  private loadMockData(): void {
    const mockUsers: any[] = [
      {
        id: 1,
        username: 'superadmin',
        email: 'admin@nammaooru.com',
        firstName: 'Super',
        lastName: 'Admin',
        fullName: 'Super Admin',
        role: 'SUPER_ADMIN',
        status: 'ACTIVE',
        department: 'Administration',
        designation: 'System Administrator',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        username: 'adminuser',
        email: 'admin@management.com',
        firstName: 'Admin',
        lastName: 'User',
        fullName: 'Admin User',
        role: 'ADMIN',
        status: 'ACTIVE',
        department: 'Management',
        designation: 'Platform Administrator',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        username: 'rajeshkumar',
        email: 'rajesh@annamalai.com',
        firstName: 'Rajesh',
        lastName: 'Kumar',
        fullName: 'Rajesh Kumar',
        role: 'SHOP_OWNER',
        status: 'ACTIVE',
        department: 'Operations',
        designation: 'Shop Owner',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 4,
        username: 'priyasharma',
        email: 'priya@example.com',
        firstName: 'Priya',
        lastName: 'Sharma',
        fullName: 'Priya Sharma',
        role: 'USER',
        status: 'ACTIVE',
        department: 'Customer',
        designation: 'Customer',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 5,
        username: 'csmanager',
        email: 'support@nammaooru.com',
        firstName: 'Customer',
        lastName: 'Support',
        fullName: 'Customer Support Manager',
        role: 'CUSTOMER_SERVICE',
        status: 'ACTIVE',
        department: 'Customer Service',
        designation: 'Support Manager',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 6,
        username: 'deliveryboy1',
        email: 'delivery1@nammaooru.com',
        firstName: 'Ravi',
        lastName: 'Delivery',
        fullName: 'Ravi Delivery',
        role: 'DELIVERY_AGENT',
        status: 'ACTIVE',
        department: 'Logistics',
        designation: 'Delivery Agent',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 7,
        username: 'opsmanager',
        email: 'ops@nammaooru.com',
        firstName: 'Operations',
        lastName: 'Manager',
        fullName: 'Operations Manager',
        role: 'MANAGER',
        status: 'ACTIVE',
        department: 'Operations',
        designation: 'Operations Manager',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 8,
        username: 'employee1',
        email: 'emp1@nammaooru.com',
        firstName: 'John',
        lastName: 'Employee',
        fullName: 'John Employee',
        role: 'EMPLOYEE',
        status: 'ACTIVE',
        department: 'Operations',
        designation: 'Operations Executive',
        isActive: true,
        emailVerified: true,
        lastLogin: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 9,
        username: 'inactiveuser',
        email: 'inactive@example.com',
        firstName: 'Inactive',
        lastName: 'User',
        fullName: 'Inactive User',
        role: 'USER',
        status: 'INACTIVE',
        department: 'Customer',
        designation: 'Customer',
        isActive: false,
        emailVerified: false,
        lastLogin: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 10,
        username: 'pendinguser',
        email: 'pending@example.com',
        firstName: 'Pending',
        lastName: 'Verification',
        fullName: 'Pending Verification',
        role: 'USER',
        status: 'PENDING_VERIFICATION',
        department: 'Customer',
        designation: 'Customer',
        isActive: false,
        emailVerified: false,
        lastLogin: '',
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];

    this.originalData = mockUsers as any;
    this.dataSource.data = [...this.originalData];
    this.snackBar.open('Loaded mock user data - API not available', 'Close', { duration: 3000 });
  }

  applyFilter(): void {
    let filteredData = [...this.originalData];

    if (this.searchText && this.searchText.trim()) {
      const searchLower = this.searchText.toLowerCase().trim();
      filteredData = filteredData.filter(user =>
        (user.fullName && user.fullName.toLowerCase().includes(searchLower)) ||
        (user.email && user.email.toLowerCase().includes(searchLower)) ||
        (user.username && user.username.toLowerCase().includes(searchLower)) ||
        (user.department && user.department.toLowerCase().includes(searchLower)) ||
        (user.designation && user.designation.toLowerCase().includes(searchLower))
      );
    }

    if (this.roleFilter) {
      filteredData = filteredData.filter(user => user.role === this.roleFilter);
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(user => {
        const actualStatus = user.isActive ? user.status || 'ACTIVE' : 'INACTIVE';
        return actualStatus === this.statusFilter;
      });
    }

    this.dataSource.data = filteredData;
    
    // Reset pagination to first page
    if (this.paginator) {
      this.paginator.firstPage();
    }
  }

  clearFilters(): void {
    this.searchText = '';
    this.roleFilter = '';
    this.statusFilter = '';
    // Reset to original data instead of reloading from API
    this.dataSource.data = [...this.originalData];
    
    // Reset pagination to first page
    if (this.paginator) {
      this.paginator.firstPage();
    }
    
    this.snackBar.open('Filters cleared', 'Close', { duration: 2000 });
  }

  createUser(): void {
    this.router.navigate(['/users/new']);
  }

  viewUser(user: UserResponse): void {
    console.log('Viewing user:', user); // Debug log
    console.log('User ID:', user.id, 'Type:', typeof user.id); // Debug log
    if (user.id) {
      this.router.navigate(['/users', user.id]);
    } else {
      console.error('User ID is missing or invalid:', user);
      this.snackBar.open('Invalid user ID', 'Close', { duration: 3000 });
    }
  }

  editUser(user: UserResponse): void {
    this.router.navigate(['/users', user.id, 'edit']);
  }

  toggleUserStatus(user: UserResponse): void {
    const action = user.isActive ? 'deactivate' : 'activate';
    const confirmMessage = `Are you sure you want to ${action} ${user.fullName}?`;
    
    if (confirm(confirmMessage)) {
      this.userService.toggleUserStatus(user.id).subscribe({
        next: (updatedUser) => {
          // Update the user in both original data and current filtered data
          const originalIndex = this.originalData.findIndex(u => u.id === user.id);
          if (originalIndex !== -1) {
            this.originalData[originalIndex] = updatedUser;
          }
          
          const displayIndex = this.dataSource.data.findIndex(u => u.id === user.id);
          if (displayIndex !== -1) {
            this.dataSource.data[displayIndex] = updatedUser;
            this.dataSource.data = [...this.dataSource.data]; // Trigger change detection
          }
          
          this.snackBar.open(`User ${user.fullName} ${action}d successfully`, 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error toggling user status:', error);
          this.snackBar.open(`Error ${action}ing user`, 'Close', { duration: 3000 });
        }
      });
    }
  }

  resetPassword(user: UserResponse): void {
    if (confirm(`Reset password for ${user.fullName}?`)) {
      this.userService.resetPassword(user.id).subscribe({
        next: () => {
          this.snackBar.open('Password reset email sent successfully', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error resetting password:', error);
          this.snackBar.open('Error resetting password', 'Close', { duration: 3000 });
        }
      });
    }
  }

  deleteUser(user: UserResponse): void {
    if (confirm(`Are you sure you want to delete ${user.fullName}?`)) {
      this.userService.deleteUser(user.id).subscribe({
        next: () => {
          this.snackBar.open('User deleted successfully', 'Close', { duration: 3000 });
          this.loadUsers();
        },
        error: (error) => {
          console.error('Error deleting user:', error);
          this.snackBar.open('Error deleting user', 'Close', { duration: 3000 });
        }
      });
    }
  }

  getRoleColor(role: string): string {
    switch (role) {
      case 'SUPER_ADMIN': return 'warn';
      case 'ADMIN': return 'primary';
      case 'SHOP_OWNER': return 'accent';
      case 'MANAGER': return 'primary';
      default: return '';
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ACTIVE': return 'primary';
      case 'INACTIVE': return 'warn';
      case 'SUSPENDED': return 'warn';
      case 'PENDING_VERIFICATION': return 'accent';
      default: return '';
    }
  }

  getPageTitle(): string {
    if (!this.roleFilter) {
      return 'User Management';
    }
    
    switch (this.roleFilter) {
      case 'ADMIN': return 'Admin Users';
      case 'MANAGER': return 'Manager Users';
      case 'SHOP_OWNER': return 'Shop Owner Users';
      case 'DELIVERY_PARTNER': return 'Delivery Partners';
      case 'USER': return 'Customer Users';
      default: return 'User Management';
    }
  }

  getActualStatus(user: UserResponse): string {
    // If user is not active, always show as INACTIVE regardless of status field
    if (!user.isActive) {
      return 'INACTIVE';
    }
    // If user is active, show the actual status
    return user.status || 'ACTIVE';
  }

  getActualStatusColor(user: UserResponse): string {
    const actualStatus = this.getActualStatus(user);
    switch (actualStatus) {
      case 'ACTIVE': return 'primary';
      case 'INACTIVE': return 'warn';
      case 'SUSPENDED': return 'warn';
      case 'PENDING_VERIFICATION': return 'accent';
      default: return '';
    }
  }

  getStatusIcon(user: UserResponse): string {
    return user.isActive ? 'check_circle' : 'cancel';
  }

  getStatusIconColor(user: UserResponse): string {
    return user.isActive ? 'primary' : 'warn';
  }

  getDisplayStatus(user: UserResponse): string {
    if (!user.isActive) {
      return 'Inactive';
    }
    return user.status === 'ACTIVE' ? 'Active' : (user.status || 'Active').replace('_', ' ');
  }

  getStatusTooltip(user: UserResponse): string {
    if (!user.isActive) {
      return 'User account is deactivated';
    }
    if (user.status === 'SUSPENDED') {
      return 'User account is suspended';
    }
    if (user.status === 'PENDING_VERIFICATION') {
      return 'User account is pending email verification';
    }
    return 'User account is active and operational';
  }

  getRoleDisplayName(role: string): string {
    switch (role) {
      case 'SUPER_ADMIN': return 'Super Admin';
      case 'ADMIN': return 'Admin';
      case 'SHOP_OWNER': return 'Shop Owner';
      case 'MANAGER': return 'Manager';
      case 'EMPLOYEE': return 'Employee';
      case 'CUSTOMER_SERVICE': return 'Customer Service';
      case 'DELIVERY_AGENT': return 'Delivery Agent';
      case 'USER': return 'Customer';
      default: return role.replace('_', ' ');
    }
  }
}