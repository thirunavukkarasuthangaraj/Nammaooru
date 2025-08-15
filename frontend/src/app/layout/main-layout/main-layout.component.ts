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
  
  // Complete menu structure organized by user role
  adminMenuItems = [
    {
      category: 'Overview',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/dashboard', badge: null }
      ]
    },
    {
      category: 'Shop Management',
      items: [
        { title: 'Shop Master', icon: 'store', route: '/shops/master', badge: null },
        { title: 'All Shops', icon: 'store_mall_directory', route: '/shops', badge: 'new' },
        { title: 'Shop Approvals', icon: 'check_circle', route: '/shops/approvals', badge: '3' }
      ]
    },
    {
      category: 'Product Management',
      items: [
        { title: 'Product Master', icon: 'inventory_2', route: '/products/master', badge: null },
        { title: 'Categories', icon: 'category', route: '/products/categories', badge: null },
        { title: 'Bulk Assignment', icon: 'assignment', route: '/products/bulk-assignment', badge: null }
      ]
    },
    {
      category: 'User Management',
      items: [
        { title: 'Users', icon: 'people', route: '/users', badge: null },
        { title: 'Roles & Permissions', icon: 'security', route: '/users/roles', badge: null }
      ]
    },
    {
      category: 'System',
      items: [
        { title: 'Settings', icon: 'settings', route: '/settings', badge: null },
        { title: 'System Reports', icon: 'analytics', route: '/reports/system', badge: null }
      ]
    }
  ];

  shopOwnerMenuItems = [
    {
      category: 'Main',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/shop-owner', badge: null },
        { title: 'Shop Overview', icon: 'storefront', route: '/shop-owner/overview', badge: null }
      ]
    },
    {
      category: 'Products',
      items: [
        { title: 'My Products', icon: 'inventory', route: '/shop-owner/products', badge: null },
        { title: 'Add Product', icon: 'add_box', route: '/shop-owner/products/add', badge: null },
        { title: 'Browse Products', icon: 'shopping_basket', route: '/shop-owner/products/browse', badge: null },
        { title: 'Bulk Upload', icon: 'cloud_upload', route: '/shop-owner/products/bulk-upload', badge: null },
        { title: 'Categories', icon: 'category', route: '/shop-owner/products/categories', badge: null }
      ]
    },
    {
      category: 'Inventory',
      items: [
        { title: 'Stock Management', icon: 'inventory_2', route: '/shop-owner/inventory', badge: null },
        { title: 'Low Stock Alerts', icon: 'warning', route: '/shop-owner/inventory/alerts', badge: '8' },
        { title: 'Pricing Management', icon: 'local_offer', route: '/shop-owner/inventory/pricing', badge: null }
      ]
    },
    {
      category: 'Orders & Sales',
      items: [
        { title: 'My Orders', icon: 'receipt_long', route: '/shop-owner/orders', badge: '5' },
        { title: 'Customers', icon: 'people', route: '/shop-owner/customers', badge: null },
        { title: 'Sales Analytics', icon: 'trending_up', route: '/shop-owner/analytics', badge: null },
        { title: 'Promotions', icon: 'local_offer', route: '/shop-owner/promotions', badge: 'new' }
      ]
    },
    {
      category: 'Shop Management',
      items: [
        { title: 'Shop Profile', icon: 'store', route: '/shop-owner/shop/profile', badge: null },
        { title: 'Settings', icon: 'settings', route: '/shop-owner/settings', badge: null },
        { title: 'Business Hours', icon: 'schedule', route: '/shop-owner/business-hours', badge: null },
        { title: 'Delivery Settings', icon: 'local_shipping', route: '/shop-owner/delivery', badge: null }
      ]
    },
    {
      category: 'Reports',
      items: [
        { title: 'Performance', icon: 'assessment', route: '/shop-owner/reports/performance', badge: null },
        { title: 'Inventory Reports', icon: 'inventory', route: '/shop-owner/reports/inventory', badge: null },
        { title: 'Financial Reports', icon: 'account_balance', route: '/shop-owner/reports/financial', badge: null }
      ]
    },
    {
      category: 'Account',
      items: [
        { title: 'Profile', icon: 'person', route: '/shop-owner/profile', badge: null },
        { title: 'Notifications', icon: 'notifications', route: '/shop-owner/notifications', badge: '3' },
        { title: 'Help', icon: 'help', route: '/shop-owner/help', badge: null },
        { title: 'Feedback', icon: 'feedback', route: '/shop-owner/feedback', badge: null }
      ]
    }
  ];

  get currentMenuItems() {
    const user = this.authService.getCurrentUser();
    if (user?.role === 'SHOP_OWNER') {
      return this.shopOwnerMenuItems;
    } else if (user?.role === 'ADMIN') {
      return this.adminMenuItems;
    }
    return [];
  }

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
    const allItems = this.currentMenuItems.flatMap(section => section.items);
    const menuItem = allItems.find(item => url.startsWith(item.route));
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