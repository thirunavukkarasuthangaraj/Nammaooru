import { Component, OnInit, ViewChild, OnDestroy, HostListener } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { MatSidenav } from '@angular/material/sidenav';
import { AuthService } from '../../core/services/auth.service';
import { User, UserRole } from '../../core/models/auth.model';
import { Observable, Subject, debounceTime, distinctUntilChanged, filter } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'app-main-layout',
  templateUrl: './main-layout.component.html',
  styleUrls: ['./main-layout.component.scss']
})
export class MainLayoutComponent implements OnInit, OnDestroy {
  @ViewChild('sidenav') sidenav!: MatSidenav;
  
  // User and authentication
  currentUser$: Observable<User | null>;
  
  // Sidebar state
  isSidebarCollapsed = false;
  isMobileSidebarOpen = false;
  isMobile = false;
  
  // Search functionality
  searchQuery = '';
  private searchSubject = new Subject<string>();
  
  // Notifications
  notificationCount = 3; // Mock data
  notifications = [
    {
      id: 1,
      title: 'New Order Received',
      message: 'Order #12345 has been placed',
      time: new Date(),
      type: 'order',
      icon: 'shopping_cart',
      read: false
    },
    {
      id: 2,
      title: 'Low Stock Alert',
      message: 'Product inventory is running low',
      time: new Date(),
      type: 'warning',
      icon: 'warning',
      read: false
    },
    {
      id: 3,
      title: 'Shop Approved',
      message: 'New shop registration approved',
      time: new Date(),
      type: 'success',
      icon: 'check_circle',
      read: false
    }
  ];
  
  private destroy$ = new Subject<void>();
  
  menuItems = [
    { 
      title: 'Dashboard', 
      icon: 'dashboard', 
      route: '/dashboard', 
      roles: ['ADMIN', 'SHOP_OWNER', 'USER'] 
    },
    
    // Shop Management - Visible to Admin
    { 
      title: 'Shop Master', 
      icon: 'store', 
      route: '/shops/master', 
      roles: ['ADMIN'] 
    },
    { 
      title: 'All Shops', 
      icon: 'store_mall_directory', 
      route: '/shops', 
      roles: ['ADMIN', 'SHOP_OWNER'] 
    },
    
    // Product Management - Admin Section
    { 
      title: 'Product Master', 
      icon: 'inventory_2', 
      route: '/products/master', 
      roles: ['ADMIN'] 
    },
    { 
      title: 'Categories', 
      icon: 'category', 
      route: '/products/categories', 
      roles: ['ADMIN'] 
    },
    { 
      title: 'Bulk Product Assignment', 
      icon: 'assignment', 
      route: '/products/bulk-assignment', 
      roles: ['ADMIN'] 
    },
    
    // Product Management - Shop Owner Section
    { 
      title: 'Select Products', 
      icon: 'add_shopping_cart', 
      route: '/products/shop-owner', 
      roles: ['ADMIN', 'SHOP_OWNER'] 
    },
    { 
      title: 'My Shop Products', 
      icon: 'shopping_cart', 
      route: '/products/my-shop', 
      roles: ['ADMIN', 'SHOP_OWNER'] 
    },
    
    // User Management
    { 
      title: 'Users', 
      icon: 'people', 
      route: '/users', 
      roles: ['ADMIN'] 
    },
    
    // Common Features
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

  ngOnInit(): void {
    this.checkScreenSize();
    this.setupSearchSubscription();
    this.setupRouterSubscription();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // Screen size detection
  @HostListener('window:resize', ['$event'])
  onResize(event: any): void {
    this.checkScreenSize();
  }

  private checkScreenSize(): void {
    this.isMobile = window.innerWidth < 768;
    if (this.isMobile) {
      this.isSidebarCollapsed = true;
    }
  }

  // Setup methods
  private setupSearchSubscription(): void {
    this.searchSubject
      .pipe(
        debounceTime(300),
        distinctUntilChanged(),
        takeUntil(this.destroy$)
      )
      .subscribe(query => {
        this.performSearch(query);
      });
  }

  private setupRouterSubscription(): void {
    this.router.events
      .pipe(
        filter(event => event instanceof NavigationEnd),
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        if (this.isMobile) {
          this.closeMobileSidebar();
        }
      });
  }

  // Sidebar methods
  toggleSidebar(): void {
    this.isSidebarCollapsed = !this.isSidebarCollapsed;
  }

  toggleMobileSidebar(): void {
    this.isMobileSidebarOpen = !this.isMobileSidebarOpen;
  }

  closeMobileSidebar(): void {
    this.isMobileSidebarOpen = false;
  }

  // Search methods
  onGlobalSearch(event: any): void {
    const query = event.target.value;
    this.searchSubject.next(query);
  }

  private performSearch(query: string): void {
    if (query.trim()) {
      console.log('Searching for:', query);
      // Implement actual search logic here
      // Navigate to search results page or show dropdown
    }
  }

  clearSearch(): void {
    this.searchQuery = '';
    this.searchSubject.next('');
  }

  // User methods
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

  getUserAvatar(username?: string): string {
    // Return a default avatar URL or generate one based on username
    return `https://ui-avatars.com/api/?name=${username || 'User'}&background=0ea5e9&color=fff&size=40&rounded=true`;
  }

  getUserRoleDisplay(role?: string): string {
    switch (role) {
      case 'ADMIN': return 'Administrator';
      case 'SHOP_OWNER': return 'Shop Owner';
      case 'MANAGER': return 'Manager';
      case 'USER': return 'User';
      default: return 'User';
    }
  }

  // Navigation methods
  navigateTo(route: string): void {
    this.router.navigate([route]);
  }

  onLogout(): void {
    this.authService.logout();
  }

  // Page title methods
  getCurrentPageTitle(): string {
    const url = this.router.url;
    const menuItem = this.menuItems.find(item => url.startsWith(item.route));
    return menuItem ? menuItem.title : 'NammaOoru Shop Management';
  }

  getCurrentPageBreadcrumb(): string {
    const url = this.router.url;
    const segments = url.split('/').filter(segment => segment);
    
    if (segments.length === 0) return 'Home';
    if (segments.length === 1) return 'Home / ' + this.capitalizeFirst(segments[0]);
    
    return 'Home / ' + segments.map(seg => this.capitalizeFirst(seg)).join(' / ');
  }

  private capitalizeFirst(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  // Legacy method for backward compatibility
  toggleSidenav(): void {
    this.toggleSidebar();
  }
}