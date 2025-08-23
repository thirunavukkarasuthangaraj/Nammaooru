import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
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
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadUsers();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadUsers(): void {
    this.loading = true;
    this.userService.getAllUsers(0, 100).subscribe({
      next: (response) => {
        console.log('Users API response:', response); // Debug log
        console.log('Users data:', response.content); // Debug log
        this.dataSource.data = response.content;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading users:', error);
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

    this.dataSource.data = mockUsers as any;
    this.snackBar.open('Loaded mock user data - API not available', 'Close', { duration: 3000 });
  }

  applyFilter(): void {
    let filteredData = this.dataSource.data;

    if (this.searchText) {
      filteredData = filteredData.filter(user =>
        user.fullName.toLowerCase().includes(this.searchText.toLowerCase()) ||
        user.email.toLowerCase().includes(this.searchText.toLowerCase()) ||
        user.username.toLowerCase().includes(this.searchText.toLowerCase()) ||
        (user.department && user.department.toLowerCase().includes(this.searchText.toLowerCase()))
      );
    }

    if (this.roleFilter) {
      filteredData = filteredData.filter(user => user.role === this.roleFilter);
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(user => user.status === this.statusFilter);
    }

    this.dataSource.data = filteredData;
  }

  clearFilters(): void {
    this.searchText = '';
    this.roleFilter = '';
    this.statusFilter = '';
    this.loadUsers();
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
    this.userService.toggleUserStatus(user.id).subscribe({
      next: () => {
        this.snackBar.open(`User ${user.isActive ? 'deactivated' : 'activated'} successfully`, 'Close', { duration: 3000 });
        this.loadUsers();
      },
      error: (error) => {
        console.error('Error toggling user status:', error);
        this.snackBar.open('Error updating user status', 'Close', { duration: 3000 });
      }
    });
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
}