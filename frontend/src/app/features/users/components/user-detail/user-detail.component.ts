import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserService, UserResponse } from '../../../../core/services/user.service';

@Component({
  selector: 'app-user-detail',
  templateUrl: './user-detail.component.html',
  styleUrls: ['./user-detail.component.scss']
})
export class UserDetailComponent implements OnInit {
  user: UserResponse | null = null;
  loading = false;
  subordinates: UserResponse[] = [];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private userService: UserService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const userId = this.route.snapshot.paramMap.get('id');
    if (userId) {
      const numericUserId = parseInt(userId, 10);
      if (!isNaN(numericUserId)) {
        this.loadUser(numericUserId);
      } else {
        console.error('Invalid user ID:', userId);
        this.snackBar.open('Invalid user ID', 'Close', { duration: 3000 });
        this.router.navigate(['/users']);
      }
    }
  }

  loadUser(userId: number): void {
    this.loading = true;
    this.userService.getUserById(userId).subscribe({
      next: (user) => {
        this.user = user;
        this.loading = false;
        // Load subordinates if user is a manager
        this.loadSubordinates(userId);
      },
      error: (error) => {
        console.error('Error loading user:', error);
        this.snackBar.open('Error loading user details', 'Close', { duration: 3000 });
        this.loading = false;
        this.router.navigate(['/users']);
      }
    });
  }

  loadSubordinates(userId: number): void {
    this.userService.getSubordinates(userId).subscribe({
      next: (subordinates) => {
        this.subordinates = subordinates;
      },
      error: (error) => {
        console.error('Error loading subordinates:', error);
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/users']);
  }

  editUser(): void {
    if (this.user) {
      this.router.navigate(['/users', this.user.id, 'edit']);
    }
  }

  toggleUserStatus(): void {
    if (!this.user) return;

    this.userService.toggleUserStatus(this.user.id).subscribe({
      next: (updatedUser) => {
        this.user = updatedUser;
        this.snackBar.open(`User ${updatedUser.isActive ? 'activated' : 'deactivated'} successfully`, 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error toggling user status:', error);
        this.snackBar.open('Error updating user status', 'Close', { duration: 3000 });
      }
    });
  }

  resetPassword(): void {
    if (!this.user) return;

    if (confirm(`Reset password for ${this.user.fullName}?`)) {
      this.userService.resetPassword(this.user.id).subscribe({
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

  lockUser(): void {
    if (!this.user) return;

    const reason = prompt('Enter reason for locking the user:');
    if (reason) {
      this.userService.lockUser(this.user.id, reason).subscribe({
        next: (updatedUser) => {
          this.user = updatedUser;
          this.snackBar.open('User locked successfully', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error locking user:', error);
          this.snackBar.open('Error locking user', 'Close', { duration: 3000 });
        }
      });
    }
  }

  unlockUser(): void {
    if (!this.user) return;

    this.userService.unlockUser(this.user.id).subscribe({
      next: (updatedUser) => {
        this.user = updatedUser;
        this.snackBar.open('User unlocked successfully', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error unlocking user:', error);
        this.snackBar.open('Error unlocking user', 'Close', { duration: 3000 });
      }
    });
  }

  deleteUser(): void {
    if (!this.user) return;

    if (confirm(`Are you sure you want to delete ${this.user.fullName}? This action cannot be undone.`)) {
      this.userService.deleteUser(this.user.id).subscribe({
        next: () => {
          this.snackBar.open('User deleted successfully', 'Close', { duration: 3000 });
          this.router.navigate(['/users']);
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