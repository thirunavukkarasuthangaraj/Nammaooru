import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { Router, ActivatedRoute } from '@angular/router';
import { Observable, of } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { UserService, UserResponse } from '../../../../core/services/user.service';
import { SwalService } from '../../../../core/services/swal.service';
import { DeliveryPartnerService } from '../../../delivery/services/delivery-partner.service';
import { DeliveryPartnerDocumentViewerComponent } from '../../../delivery/components/delivery-partner-document-viewer/delivery-partner-document-viewer.component';

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

  // Delivery Partner Status Tracking Fields
  isOnline?: boolean;
  isAvailable?: boolean;
  rideStatus?: 'AVAILABLE' | 'ON_RIDE' | 'BUSY' | 'ON_BREAK' | 'OFFLINE';
  currentLatitude?: number;
  currentLongitude?: number;
  lastLocationUpdate?: string;
  lastActivity?: string;
}

@Component({
  selector: 'app-user-list',
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['fullName', 'email', 'role', 'department', 'status', 'createdAt', 'lastLogin', 'actions'];
  dataSource = new MatTableDataSource<UserResponse>();
  originalData: UserResponse[] = [];
  loading = false;
  searchText = '';
  roleFilter = '';
  statusFilter = '';
  documentStatus: Map<number, boolean> = new Map(); // Track if delivery partner has documents

  /** Backend page size used while loading every user (newest first). */
  private static readonly FETCH_PAGE_SIZE = 200;
  /** Users created within this many days get a "New" badge. */
  private static readonly NEW_USER_DAYS = 7;
  
  roleOptions = [
    { value: '', label: 'All Roles' },
    { value: 'SUPER_ADMIN', label: 'Super Admin' },
    { value: 'ADMIN', label: 'Admin' },
    { value: 'SHOP_OWNER', label: 'Shop Owner' },
    { value: 'MANAGER', label: 'Manager' },
    { value: 'EMPLOYEE', label: 'Employee' },
    { value: 'CUSTOMER_SERVICE', label: 'Customer Service' },
    { value: 'DELIVERY_PARTNER', label: 'Delivery Partner' },
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
    private router: Router,
    private route: ActivatedRoute,
    private dialog: MatDialog,
    private deliveryPartnerService: DeliveryPartnerService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    // Check if there's a role filter from route data
    const routeRole = this.route.snapshot.data['role'];
    if (routeRole) {
      this.roleFilter = routeRole;
    }
    // Customers have no department; their phone number is what admins look up.
    if (this.roleFilter === 'USER') {
      this.displayedColumns = ['fullName', 'email', 'mobileNumber', 'status', 'createdAt', 'lastLogin', 'actions'];
    }
    this.loadUsers();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadUsers(): void {
    this.loading = true;

    this.fetchAllUsers(0, []).subscribe({
      next: (users) => {
        this.originalData = users;
        this.dataSource.data = [...this.originalData];

        // Check document status for delivery partners
        this.checkDocumentStatusForDeliveryPartners();

        this.loading = false;

        const roleMessage = this.roleFilter ? `${this.roleFilter} users` : 'all users';
        this.swal.toast(`✅ Loaded ${roleMessage} successfully!`, 'success');
      },
      error: (error) => {
        console.error('❌ Error loading users from API:', error);
        this.originalData = [];
        this.dataSource.data = [];
        this.loading = false;
        this.swal.toast('Could not load users. Please refresh and try again.', 'error');
      }
    });
  }

  /**
   * Loads every page from the backend, newest users first, so recently
   * onboarded users are never cut off by a single-page limit.
   */
  private fetchAllUsers(page: number, acc: UserResponse[]): Observable<UserResponse[]> {
    const size = UserListComponent.FETCH_PAGE_SIZE;
    const apiCall = this.roleFilter
      ? this.userService.getUsersByRole(this.roleFilter, page, size, 'createdAt', 'desc')
      : this.userService.getAllUsers(page, size, 'createdAt', 'desc');

    return apiCall.pipe(
      switchMap(response => {
        const all = [...acc, ...response.content];
        const hasMore = response.content.length > 0 && page + 1 < response.totalPages;
        return hasMore ? this.fetchAllUsers(page + 1, all) : of(all);
      })
    );
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
    
    this.swal.toast('Filters cleared', 'success');
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
      this.swal.toast('Invalid user ID', 'error');
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
          
          this.swal.toast(`User ${user.fullName} ${action}d successfully`, 'success');
        },
        error: (error) => {
          console.error('Error toggling user status:', error);
          this.swal.toast(`Error ${action}ing user`, 'error');
        }
      });
    }
  }

  resetPassword(user: UserResponse): void {
    if (confirm(`Reset password for ${user.fullName}?`)) {
      this.userService.resetPassword(user.id).subscribe({
        next: () => {
          this.swal.toast('Password reset email sent successfully', 'success');
        },
        error: (error) => {
          console.error('Error resetting password:', error);
          this.swal.toast('Error resetting password', 'error');
        }
      });
    }
  }

  deleteUser(user: UserResponse): void {
    if (confirm(`Are you sure you want to delete ${user.fullName}?`)) {
      this.userService.deleteUser(user.id).subscribe({
        next: () => {
          this.swal.toast('User deleted successfully', 'success');
          this.loadUsers();
        },
        error: (error) => {
          console.error('Error deleting user:', error);
          this.swal.toast('Error deleting user', 'error');
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

  /** True when the user registered within the last few days. */
  isNewUser(user: UserResponse): boolean {
    if (!user.createdAt) {
      return false;
    }
    const created = new Date(user.createdAt).getTime();
    if (isNaN(created)) {
      return false;
    }
    const ageMs = Date.now() - created;
    return ageMs >= 0 && ageMs < UserListComponent.NEW_USER_DAYS * 24 * 60 * 60 * 1000;
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
      case 'DELIVERY_PARTNER': return 'Delivery Partner';
      case 'USER': return 'Customer';
      default: return role.replace('_', ' ');
    }
  }

  // Delivery Partner Status Methods
  getOnlineStatusTooltip(user: any): string {
    const lastActivity = user.lastActivity ? new Date(user.lastActivity).toLocaleString() : 'Never';
    if (user.isOnline) {
      return `Partner is online. Last activity: ${lastActivity}`;
    } else {
      return `Partner is offline. Last activity: ${lastActivity}`;
    }
  }

  getRideStatusClass(rideStatus: string | undefined): string {
    switch (rideStatus) {
      case 'AVAILABLE': return 'available';
      case 'ON_RIDE': return 'on-ride';
      case 'BUSY': return 'busy';
      case 'ON_BREAK': return 'on-break';
      case 'OFFLINE': return 'offline';
      default: return 'unknown';
    }
  }

  getRideStatusIcon(rideStatus: string | undefined): string {
    switch (rideStatus) {
      case 'AVAILABLE': return 'check_circle';
      case 'ON_RIDE': return 'directions_bike';
      case 'BUSY': return 'hourglass_empty';
      case 'ON_BREAK': return 'coffee';
      case 'OFFLINE': return 'offline_pin';
      default: return 'help_outline';
    }
  }

  getRideStatusDisplay(rideStatus: string | undefined): string {
    switch (rideStatus) {
      case 'AVAILABLE': return 'Available';
      case 'ON_RIDE': return 'On Ride';
      case 'BUSY': return 'Busy';
      case 'ON_BREAK': return 'On Break';
      case 'OFFLINE': return 'Offline';
      default: return 'Unknown';
    }
  }

  getRideStatusTooltip(rideStatus: string | undefined): string {
    switch (rideStatus) {
      case 'AVAILABLE': return 'Partner is available for new deliveries';
      case 'ON_RIDE': return 'Partner is currently on a delivery';
      case 'BUSY': return 'Partner is busy and cannot take new orders';
      case 'ON_BREAK': return 'Partner is on a break';
      case 'OFFLINE': return 'Partner is offline';
      default: return 'Status unknown';
    }
  }

  // Delivery Partner Document Management Methods
  viewDocuments(user: UserResponse): void {
    if (user.role !== 'DELIVERY_PARTNER') {
      this.swal.toast('Document viewing is only available for delivery partners', 'warning');
      return;
    }

    // Navigate to simple document viewer page
    this.router.navigate(['/delivery/documents/view', user.id, user.fullName]);
  }

  manageDocuments(user: UserResponse): void {
    if (user.role !== 'DELIVERY_PARTNER') {
      this.swal.toast('Document management is only available for delivery partners', 'warning');
      return;
    }

    // Navigate to document management page
    this.router.navigate(['/users', user.id, 'documents']);
  }

  // Check document status for delivery partners
  private checkDocumentStatusForDeliveryPartners(): void {
    const deliveryPartners = this.originalData.filter(user => user.role === 'DELIVERY_PARTNER');

    deliveryPartners.forEach(partner => {
      this.deliveryPartnerService.getPartnerDocuments(partner.id).subscribe({
        next: (response) => {
          const hasDocuments = response.data && response.data.length > 0;
          this.documentStatus.set(partner.id, hasDocuments);
        },
        error: (error) => {
          console.error(`Error checking documents for partner ${partner.id}:`, error);
          this.documentStatus.set(partner.id, false);
        }
      });
    });
  }

  // Check if delivery partner has documents
  hasDocuments(userId: number): boolean {
    return this.documentStatus.get(userId) || false;
  }

  // Add documents for delivery partner
  addDocuments(user: UserResponse): void {
    if (user.role !== 'DELIVERY_PARTNER') {
      this.swal.toast('Document upload is only available for delivery partners', 'warning');
      return;
    }

    // Navigate to document management page for upload
    this.router.navigate(['/users', user.id, 'documents']);
  }

  private openDocumentViewerDialog(user: UserResponse): void {
    // Use user.id as partnerId since backend expects user ID for delivery partner documents
    this.deliveryPartnerService.getPartnerDocuments(user.id).subscribe({
      next: (response) => {
        if (response.data && response.data.length > 0) {
          // Open document viewer dialog
          const dialogRef = this.dialog.open(DeliveryPartnerDocumentViewerComponent, {
            width: '90%',
            maxWidth: '1200px',
            height: '80vh',
            data: {
              partnerId: user.id,
              partnerName: user.fullName,
              documents: response.data,
              isAdmin: true
            }
          });

          dialogRef.afterClosed().subscribe(result => {
            if (result === 'refresh') {
              // Refresh user list if needed
              this.loadUsers();
            }
          });
        } else {
          this.swal.toast(`No documents found for ${user.fullName}. Use "Manage Documents" to upload.`, 'warning');
        }
      },
      error: (error) => {
        console.error('Error loading partner documents:', error);
        this.swal.toast('Error loading documents. Please try again.', 'error');
      }
    });
  }
}