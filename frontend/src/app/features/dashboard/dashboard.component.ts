import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';

import { AuthService } from '../../core/services/auth.service';
import { User } from '../../core/models/auth.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatToolbarModule,
    MatSidenavModule,
    MatListModule,
    MatMenuModule,
    MatDividerModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  currentUser: User | null = null;
  sidenavOpen = true;
  
  // Make router accessible in template
  public router = this.routerService;

  menuItems = [
    {
      title: 'Dashboard',
      icon: 'dashboard',
      route: '/dashboard',
      roles: ['ADMIN', 'SHOP_OWNER']
    },
    {
      title: 'Shop Master',
      icon: 'store',
      route: '/shops/master',
      roles: ['ADMIN']
    },
    {
      title: 'Shop List',
      icon: 'list',
      route: '/shops',
      roles: ['ADMIN', 'SHOP_OWNER']
    },
    {
      title: 'Users',
      icon: 'people',
      route: '/users',
      roles: ['ADMIN']
    },
    {
      title: 'Settings',
      icon: 'settings',
      route: '/settings',
      roles: ['ADMIN', 'SHOP_OWNER']
    }
  ];

  constructor(
    private authService: AuthService,
    private routerService: Router
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();
    
    if (!this.currentUser) {
      this.routerService.navigate(['/auth/login']);
    }
  }

  onLogout(): void {
    this.authService.logout();
  }

  navigateTo(route: string): void {
    this.routerService.navigate([route]);
  }

  hasAccess(roles: string[]): boolean {
    if (!this.currentUser) return false;
    return roles.includes(this.currentUser.role);
  }

  toggleSidenav(): void {
    this.sidenavOpen = !this.sidenavOpen;
  }
}