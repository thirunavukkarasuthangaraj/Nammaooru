import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../../core/services/auth.service';
import { Router } from '@angular/router';
import { User, UserRole } from '../../../core/models/auth.model';

@Component({
  selector: 'app-role-test',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatCardModule,
    MatIconModule
  ],
  template: `
    <div class="role-test-container">
      <mat-card class="test-card">
        <mat-card-header>
          <mat-card-title>🧪 Role Testing Tool</mat-card-title>
          <mat-card-subtitle>Test different user roles and their menus</mat-card-subtitle>
        </mat-card-header>
        
        <mat-card-content>
          <div class="current-user" *ngIf="currentUser">
            <h3>Current User:</h3>
            <p><strong>Username:</strong> {{ currentUser.username }}</p>
            <p><strong>Email:</strong> {{ currentUser.email }}</p>
            <p><strong>Role:</strong> {{ getUserRoleDisplay(currentUser.role) }}</p>
          </div>

          <div class="role-buttons">
            <h3>Switch to Role:</h3>
            
            <button mat-raised-button 
                    color="primary" 
                    (click)="loginAs('customer')"
                    class="role-btn">
              <mat-icon>person</mat-icon>
              Customer
            </button>
            
            <button mat-raised-button 
                    color="accent" 
                    (click)="loginAs('shopowner')"
                    class="role-btn">
              <mat-icon>store</mat-icon>
              Shop Owner
            </button>
            
            <button mat-raised-button 
                    color="warn" 
                    (click)="loginAs('superadmin')"
                    class="role-btn">
              <mat-icon>supervisor_account</mat-icon>
              Super Admin
            </button>
            
            <button mat-raised-button 
                    (click)="loginAs('delivery')"
                    class="role-btn">
              <mat-icon>delivery_dining</mat-icon>
              Delivery Partner
            </button>
          </div>

          <div class="test-credentials">
            <h3>📋 Test Credentials:</h3>
            <div class="credential-item">
              <strong>Customer:</strong> customer@example.com / customer123
            </div>
            <div class="credential-item">
              <strong>Shop Owner:</strong> shopowner@example.com / shop123
            </div>
            <div class="credential-item">
              <strong>Super Admin:</strong> superadmin@shopmanagement.com / password
            </div>
            <div class="credential-item">
              <strong>Delivery:</strong> delivery@example.com / delivery123
            </div>
          </div>
        </mat-card-content>

        <mat-card-actions>
          <button mat-button (click)="logout()">
            <mat-icon>logout</mat-icon>
            Logout
          </button>
          <button mat-button (click)="goToDashboard()">
            <mat-icon>dashboard</mat-icon>
            Go to Dashboard
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .role-test-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 80vh;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }

    .test-card {
      width: 100%;
      max-width: 600px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    .current-user {
      margin-bottom: 24px;
      padding: 16px;
      background: #f5f5f5;
      border-radius: 8px;
      border-left: 4px solid #2196f3;
    }

    .current-user h3 {
      margin: 0 0 12px 0;
      color: #333;
    }

    .role-buttons {
      margin-bottom: 24px;
    }

    .role-buttons h3 {
      margin-bottom: 16px;
    }

    .role-btn {
      margin: 8px;
      min-width: 140px;
      height: 48px;
    }

    .test-credentials {
      padding: 16px;
      background: #fff9c4;
      border-radius: 8px;
      border-left: 4px solid #ffc107;
    }

    .test-credentials h3 {
      margin: 0 0 12px 0;
      color: #333;
    }

    .credential-item {
      margin: 8px 0;
      font-family: 'Courier New', monospace;
      font-size: 14px;
    }

    mat-card-actions {
      padding: 16px;
      justify-content: space-between;
    }
  `]
})
export class RoleTestComponent {
  
  currentUser: User | null = null;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {
    this.currentUser = this.authService.getCurrentUser();
  }

  loginAs(role: string): void {
    // Create mock user for testing
    let mockUser: User;
    
    switch (role) {
      case 'customer':
        mockUser = {
          id: 1,
          username: 'customer',
          email: 'customer@example.com',
          role: UserRole.USER, // USER is the customer role
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        };
        break;
      case 'shopowner':
        mockUser = {
          id: 2,
          username: 'shopowner',
          email: 'shopowner@example.com',
          role: UserRole.SHOP_OWNER,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        };
        break;
      case 'superadmin':
        mockUser = {
          id: 3,
          username: 'superadmin',
          email: 'superadmin@shopmanagement.com',
          role: UserRole.SUPER_ADMIN,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        };
        break;
      case 'delivery':
        mockUser = {
          id: 4,
          username: 'delivery',
          email: 'delivery@example.com',
          role: UserRole.DELIVERY_PARTNER,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        };
        break;
      default:
        return;
    }

    // Set mock session for testing
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('shop_management_user', JSON.stringify(mockUser));
      localStorage.setItem('shop_management_token', 'mock-token-' + role);
    }

    // Update auth service
    (this.authService as any).currentUserSubject.next(mockUser);
    this.currentUser = mockUser;

    console.log('🧪 Test Login:', mockUser);
  }

  logout(): void {
    this.authService.logout();
    this.currentUser = null;
  }

  goToDashboard(): void {
    this.router.navigate(['/dashboard']);
  }

  getUserRoleDisplay(role?: string): string {
    switch (role) {
      case 'SUPER_ADMIN': return 'Super Administrator';
      case 'ADMIN': return 'Administrator';
      case 'MANAGER': return 'Manager';
      case 'SHOP_OWNER': return 'Shop Owner';
      case 'DELIVERY_PARTNER': return 'Delivery Partner';
      case 'USER': return 'Customer';
      default: return 'Unknown';
    }
  }
}