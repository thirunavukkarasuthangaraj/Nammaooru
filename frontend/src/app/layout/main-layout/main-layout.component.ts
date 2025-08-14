import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSidenav } from '@angular/material/sidenav';
import { AuthService } from '../../core/services/auth.service';
import { User, UserRole } from '../../core/models/auth.model';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-main-layout',
  templateUrl: './main-layout.component.html',
  styleUrls: ['./main-layout.component.scss']
})
export class MainLayoutComponent implements OnInit {
  @ViewChild('sidenav') sidenav!: MatSidenav;
  
  currentUser$: Observable<User | null>;
  sidenavOpen = true;
  
  menuItems = [
    { 
      title: 'Dashboard', 
      icon: 'dashboard', 
      route: '/dashboard', 
      roles: ['ADMIN', 'SHOP_OWNER', 'USER'] 
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
    },
    { 
      title: 'Reports', 
      icon: 'analytics', 
      route: '/reports', 
      roles: ['ADMIN', 'SHOP_OWNER'] 
    }
  ];

  constructor(
    private authService: AuthService,
    public router: Router
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {}

  toggleSidenav(): void {
    this.sidenavOpen = !this.sidenavOpen;
  }

  hasAccess(roles: string[]): boolean {
    const user = this.authService.getCurrentUser();
    return user ? roles.includes(user.role) : false;
  }

  getUserInitials(name?: string): string {
    if (!name) return 'U';
    return name
      .split(' ')
      .map(part => part.charAt(0))
      .join('')
      .substring(0, 2)
      .toUpperCase();
  }

  navigateTo(route: string): void {
    this.router.navigate([route]);
  }

  onLogout(): void {
    this.authService.logout();
  }

  getCurrentPageTitle(): string {
    const url = this.router.url;
    const menuItem = this.menuItems.find(item => url.startsWith(item.route));
    return menuItem ? menuItem.title : 'Shop Management';
  }
}