import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { UserService } from '../../../../core/services/user.service';

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
  dataSource = new MatTableDataSource<User>();
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
        this.dataSource.data = response.content;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading users:', error);
        this.snackBar.open('Error loading users', 'Close', { duration: 3000 });
        this.loading = false;
      }
    });
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

  viewUser(user: User): void {
    this.router.navigate(['/users', user.id]);
  }

  editUser(user: User): void {
    this.router.navigate(['/users', user.id, 'edit']);
  }

  toggleUserStatus(user: User): void {
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

  resetPassword(user: User): void {
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

  deleteUser(user: User): void {
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