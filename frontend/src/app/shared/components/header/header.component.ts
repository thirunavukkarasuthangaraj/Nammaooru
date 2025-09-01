import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AuthService } from '@core/services/auth.service';
import { VersionService } from '@core/services/version.service';
import { User, UserRole } from '@core/models/auth.model';

@Component({
  selector: 'app-header',
  template: `
    <mat-toolbar color="primary" class="header-toolbar">
      <div class="toolbar-content">
        <div class="brand-section">
          <button mat-icon-button (click)="toggleSidenav()" *ngIf="currentUser$ | async">
            <mat-icon>menu</mat-icon>
          </button>
          <a routerLink="/" class="brand-link">
            <mat-icon class="brand-icon">store</mat-icon>
            <span class="brand-text">Shop Manager</span>
          </a>
        </div>

        <div class="navigation-section" *ngIf="currentUser$ | async">
          <nav class="nav-links">
            <a mat-button routerLink="/shops" routerLinkActive="active">
              <mat-icon>store</mat-icon>
              Shops
            </a>
            
            <a mat-button routerLink="/admin" routerLinkActive="active" *ngIf="isAdmin()">
              <mat-icon>admin_panel_settings</mat-icon>
              Admin
            </a>
            
            <a mat-button routerLink="/shop-owner" routerLinkActive="active" *ngIf="canManageShops()">
              <mat-icon>business</mat-icon>
              My Shops
            </a>
          </nav>
        </div>

        <div class="user-section">
          <ng-container *ngIf="currentUser$ | async as user; else loginButton">
            <button mat-icon-button [matMenuTriggerFor]="userMenu" class="user-button">
              <mat-icon>account_circle</mat-icon>
            </button>
            
            <mat-menu #userMenu="matMenu">
              <div class="user-info">
                <div class="user-name">{{user.username}}</div>
                <div class="user-role">{{user.role}}</div>
              </div>
              <mat-divider></mat-divider>
              
              <button mat-menu-item routerLink="/profile">
                <mat-icon>person</mat-icon>
                Profile
              </button>
              
              <button mat-menu-item routerLink="/settings">
                <mat-icon>settings</mat-icon>
                Settings
              </button>
              
              <button mat-menu-item (click)="showVersionInfo()">
                <mat-icon>info</mat-icon>
                <span>Version Info</span>
                <span class="version-badge" *ngIf="versionInfo?.server?.version">
                  v{{versionInfo.server.version}}
                </span>
              </button>
              
              <mat-divider></mat-divider>
              
              <button mat-menu-item (click)="logout()" class="logout-button">
                <mat-icon>exit_to_app</mat-icon>
                Logout
              </button>
            </mat-menu>
          </ng-container>
          
          <ng-template #loginButton>
            <button mat-button routerLink="/auth/login">
              <mat-icon>login</mat-icon>
              Login
            </button>
          </ng-template>
        </div>
      </div>
    </mat-toolbar>
  `,
  styles: [`
    .header-toolbar {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 1000;
      height: 64px;
    }

    .toolbar-content {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 16px;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .brand-link {
      display: flex;
      align-items: center;
      gap: 8px;
      text-decoration: none;
      color: inherit;
    }

    .brand-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .brand-text {
      font-size: 18px;
      font-weight: 500;
      margin-left: 4px;
    }

    .navigation-section {
      flex: 1;
      display: flex;
      justify-content: center;
    }

    .nav-links {
      display: flex;
      gap: 8px;
    }

    .nav-links a {
      display: flex;
      align-items: center;
      gap: 4px;
      transition: background-color 0.2s;
    }

    .nav-links a.active {
      background-color: rgba(255, 255, 255, 0.1);
    }

    .nav-links a:hover {
      background-color: rgba(255, 255, 255, 0.08);
    }

    .user-section {
      display: flex;
      align-items: center;
    }

    .user-button {
      width: 40px;
      height: 40px;
    }

    .user-info {
      padding: 8px 16px;
      border-bottom: 1px solid #e0e0e0;
    }

    .user-name {
      font-weight: 500;
      font-size: 14px;
    }

    .user-role {
      font-size: 12px;
      color: #666;
      text-transform: capitalize;
    }

    .logout-button {
      color: #f44336 !important;
    }

    .version-badge {
      background: #4caf50;
      color: white;
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 8px;
      margin-left: auto;
      font-weight: 500;
    }

    /* Mobile Styles */
    @media (max-width: 768px) {
      .header-toolbar {
        height: 56px;
      }

      .toolbar-content {
        padding: 0 8px;
      }

      .brand-text {
        display: none;
      }

      .navigation-section {
        display: none;
      }

      .nav-links {
        flex-direction: column;
        gap: 0;
      }
    }

    @media (max-width: 480px) {
      .brand-icon {
        font-size: 20px;
        width: 20px;
        height: 20px;
      }

      .user-button {
        width: 36px;
        height: 36px;
      }
    }
  `]
})
export class HeaderComponent implements OnInit {
  currentUser$: Observable<User | null>;
  versionInfo: any = null;

  constructor(
    private authService: AuthService,
    private router: Router,
    private versionService: VersionService
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {
    // Load version info
    this.versionService.getVersionInfo().subscribe(info => {
      this.versionInfo = info;
    });
  }

  isAdmin(): boolean {
    return this.authService.isAdmin();
  }

  canManageShops(): boolean {
    return this.authService.canManageShops();
  }

  logout(): void {
    this.authService.logout();
  }

  toggleSidenav(): void {
    // Implement sidenav toggle for mobile
    // This will be connected to a sidenav service when implemented
  }

  showVersionInfo(): void {
    if (this.versionInfo) {
      const buildDate = this.versionInfo.server.buildDate 
        ? new Date(this.versionInfo.server.buildDate).toLocaleString()
        : 'Unknown';
      
      const message = `🏪 Shop Management System

📱 Frontend Version: ${this.versionInfo.client}
🖥️ Backend Version: v${this.versionInfo.server.version}
📦 Application: ${this.versionInfo.server.name || 'Shop Management Backend'}

🕐 Build Date: ${buildDate}
⚡ Server Status: Online`;
      
      alert(message);
    } else {
      alert(`📱 Frontend: ${this.versionService.getVersion()}\n🖥️ Backend: Loading...`);
    }
  }
}