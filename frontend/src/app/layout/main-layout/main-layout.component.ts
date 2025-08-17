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
  
  // SUPER ADMIN - Can see ALL menus from all roles
  superAdminMenuItems = [
    {
      category: 'System Overview',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/dashboard', badge: null },
        { title: 'System Analytics', icon: 'analytics', route: '/analytics', badge: null },
        { title: 'System Health', icon: 'monitor_heart', route: '/system/health', badge: null }
      ]
    },
    {
      category: 'User Management',
      items: [
        { title: 'All Users', icon: 'people', route: '/users', badge: null },
        { title: 'Admins', icon: 'admin_panel_settings', route: '/users/admins', badge: null },
        { title: 'Managers', icon: 'manage_accounts', route: '/users/managers', badge: null },
        { title: 'Shop Owners', icon: 'store_mall_directory', route: '/users/shop-owners', badge: null },
        { title: 'Delivery Partners', icon: 'delivery_dining', route: '/users/delivery-partners', badge: null },
        { title: 'Customers', icon: 'person', route: '/users/customers', badge: null }
      ]
    },
    {
      category: 'Shop Management',
      items: [
        { title: 'All Shops', icon: 'store', route: '/shops', badge: null },
        { title: 'Shop Master', icon: 'store', route: '/shops/master', badge: null },
        { title: 'Shop Approvals', icon: 'check_circle', route: '/shops/approvals', badge: '3' },
        { title: 'Shop Categories', icon: 'category', route: '/shops/categories', badge: null }
      ]
    },
    {
      category: 'Product Management',
      items: [
        { title: 'All Products', icon: 'inventory', route: '/products', badge: null },
        { title: 'Product Master', icon: 'inventory_2', route: '/products/master', badge: null },
        { title: 'Categories', icon: 'category', route: '/products/categories', badge: null },
        { title: 'Product Approvals', icon: 'approval', route: '/products/approvals', badge: null }
      ]
    },
    {
      category: 'Order Management',
      items: [
        { title: 'All Orders', icon: 'receipt_long', route: '/orders', badge: '45' },
        { title: 'Order Analytics', icon: 'trending_up', route: '/orders/analytics', badge: null },
        { title: 'Order Issues', icon: 'report_problem', route: '/orders/issues', badge: '3' }
      ]
    },
    {
      category: 'Delivery Management',
      items: [
        { title: 'Delivery Partners', icon: 'delivery_dining', route: '/delivery/admin/partners', badge: '5' },
        { title: 'Order Assignments', icon: 'assignment', route: '/delivery/admin/assignments', badge: null },
        { title: 'Live Tracking', icon: 'gps_fixed', route: '/delivery/admin/tracking', badge: null },
        { title: 'Delivery Analytics', icon: 'analytics', route: '/delivery/analytics', badge: null },
        { title: 'Delivery Zones', icon: 'map', route: '/delivery/zones', badge: null }
      ]
    },
    {
      category: 'Financial Management',
      items: [
        { title: 'Revenue Overview', icon: 'payments', route: '/finance/revenue', badge: null },
        { title: 'Partner Payouts', icon: 'account_balance', route: '/finance/payouts', badge: null },
        { title: 'Commission Settings', icon: 'percent', route: '/finance/commission', badge: null },
        { title: 'Financial Reports', icon: 'assessment', route: '/finance/reports', badge: null }
      ]
    },
    {
      category: 'System Administration',
      items: [
        { title: 'System Settings', icon: 'settings', route: '/admin/settings', badge: null },
        { title: 'App Configuration', icon: 'tune', route: '/admin/config', badge: null },
        { title: 'Notifications', icon: 'notifications', route: '/admin/notifications', badge: '8' },
        { title: 'Audit Logs', icon: 'history', route: '/admin/audit', badge: null },
        { title: 'Backup & Restore', icon: 'backup', route: '/admin/backup', badge: null }
      ]
    }
  ];

  // ADMIN - Standard admin access
  adminMenuItems = [
    {
      category: 'Overview',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/dashboard', badge: null },
        { title: 'Analytics', icon: 'analytics', route: '/analytics', badge: null }
      ]
    },
    {
      category: 'Order Management',
      items: [
        { title: 'All Orders', icon: 'receipt_long', route: '/orders', badge: '12' }
      ]
    },
    {
      category: 'Shop Management',
      items: [
        { title: 'Shop Master', icon: 'store', route: '/shops/master', badge: null },
        { title: 'Shop Approvals', icon: 'check_circle', route: '/shops/approvals', badge: '3' }
      ]
    },
    {
      category: 'Product Management',
      items: [
        { title: 'Product Master', icon: 'inventory_2', route: '/products/master', badge: null },
        { title: 'Categories', icon: 'category', route: '/products/categories', badge: null }
      ]
    },
    {
      category: 'User Management',
      items: [
        { title: 'Users', icon: 'people', route: '/users', badge: null },
        { title: 'Customers', icon: 'person', route: '/admin/customers', badge: null }
      ]
    },
    {
      category: 'Delivery Management',
      items: [
        { title: 'Delivery Partners', icon: 'delivery_dining', route: '/delivery/admin/partners', badge: '5' },
        { title: 'Order Assignments', icon: 'assignment', route: '/delivery/admin/assignments', badge: null },
        { title: 'Live Tracking', icon: 'gps_fixed', route: '/delivery/admin/tracking', badge: null },
        { title: 'Delivery Analytics', icon: 'analytics', route: '/delivery/analytics', badge: null }
      ]
    },
    {
      category: 'System',
      items: [
        { title: 'Settings', icon: 'settings', route: '/settings', badge: null },
        { title: 'Notifications', icon: 'notifications', route: '/notifications', badge: '8' }
      ]
    }
  ];

  // MANAGER - Operations management focus
  managerMenuItems = [
    {
      category: 'Operations Overview',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/manager/dashboard', badge: null },
        { title: 'Operations Analytics', icon: 'analytics', route: '/manager/analytics', badge: null }
      ]
    },
    {
      category: 'Order Management',
      items: [
        { title: 'Active Orders', icon: 'receipt_long', route: '/orders', badge: '12' },
        { title: 'Order Processing', icon: 'assignment_turned_in', route: '/manager/orders/processing', badge: '5' },
        { title: 'Issue Resolution', icon: 'support', route: '/manager/orders/issues', badge: '3' }
      ]
    },
    {
      category: 'Shop Operations',
      items: [
        { title: 'Shop Performance', icon: 'trending_up', route: '/manager/shops/performance', badge: null },
        { title: 'Shop Issues', icon: 'report_problem', route: '/manager/shops/issues', badge: '2' },
        { title: 'Shop Reviews', icon: 'rate_review', route: '/manager/shops/reviews', badge: null }
      ]
    },
    {
      category: 'Delivery Operations',
      items: [
        { title: 'Delivery Partners', icon: 'delivery_dining', route: '/delivery/admin/partners', badge: '5' },
        { title: 'Live Tracking', icon: 'gps_fixed', route: '/delivery/admin/tracking', badge: null },
        { title: 'Delivery Issues', icon: 'local_shipping', route: '/manager/delivery/issues', badge: '1' }
      ]
    },
    {
      category: 'Customer Service',
      items: [
        { title: 'Customer Support', icon: 'support_agent', route: '/manager/support', badge: '8' },
        { title: 'Complaints', icon: 'feedback', route: '/manager/complaints', badge: '4' },
        { title: 'Refunds', icon: 'money_off', route: '/manager/refunds', badge: '2' }
      ]
    },
    {
      category: 'Reports',
      items: [
        { title: 'Daily Reports', icon: 'assessment', route: '/manager/reports/daily', badge: null },
        { title: 'Performance Reports', icon: 'bar_chart', route: '/manager/reports/performance', badge: null }
      ]
    }
  ];

  shopOwnerMenuItems = [
    {
      category: 'Main',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/shop-owner', badge: null },
        { title: 'Shop Overview', icon: 'store', route: '/shop-owner/overview', badge: null }
      ]
    },
    {
      category: 'Products',
      items: [
        { title: 'My Products', icon: 'inventory', route: '/shop-owner/products', badge: null },
        { title: 'Add Product', icon: 'add_box', route: '/shop-owner/products/add', badge: null },
        { title: 'Categories', icon: 'category', route: '/shop-owner/products/categories', badge: null },
        { title: 'Bulk Upload', icon: 'cloud_upload', route: '/shop-owner/products/bulk-upload', badge: null }
      ]
    },
    {
      category: 'Orders & Sales',
      items: [
        { title: 'My Orders', icon: 'receipt_long', route: '/orders', badge: null },
        { title: 'Order Tracking', icon: 'local_shipping', route: '/delivery/tracking', badge: null },
        { title: 'Sales Analytics', icon: 'trending_up', route: '/analytics', badge: null }
      ]
    },
    {
      category: 'Inventory',
      items: [
        { title: 'Stock Management', icon: 'inventory_2', route: '/shop-owner/inventory', badge: null }
      ]
    },
    {
      category: 'Management',
      items: [
        { title: 'Notifications', icon: 'notifications', route: '/shop-owner/notifications', badge: this.getNotificationCount().toString() }
      ]
    },
    {
      category: 'Shop Management',
      items: [
        { title: 'Shop Profile', icon: 'business', route: '/shop-owner/shop/profile', badge: null },
        { title: 'Settings', icon: 'settings', route: '/shop-owner/settings', badge: null }
      ]
    }
  ];

  deliveryPartnerMenuItems = [
    {
      category: 'Main',
      items: [
        { title: 'Dashboard', icon: 'dashboard', route: '/delivery/partner/dashboard', badge: null },
        { title: 'My Orders', icon: 'local_shipping', route: '/delivery/partner/orders', badge: '3' }
      ]
    },
    {
      category: 'Delivery',
      items: [
        { title: 'Available Orders', icon: 'assignment', route: '/delivery/partner/available', badge: '12' },
        { title: 'My Deliveries', icon: 'delivery_dining', route: '/delivery/partner/deliveries', badge: null },
        { title: 'Earnings', icon: 'payments', route: '/delivery/partner/earnings', badge: null },
        { title: 'Performance', icon: 'trending_up', route: '/delivery/partner/performance', badge: null }
      ]
    },
    {
      category: 'Account',
      items: [
        { title: 'Profile', icon: 'person', route: '/delivery/partner/profile', badge: null },
        { title: 'Documents', icon: 'description', route: '/delivery/partner/documents', badge: null },
        { title: 'Vehicle Info', icon: 'two_wheeler', route: '/delivery/partner/vehicle', badge: null }
      ]
    },
    {
      category: 'Support',
      items: [
        { title: 'Help Center', icon: 'help', route: '/delivery/partner/help', badge: null },
        { title: 'Emergency', icon: 'emergency', route: '/delivery/partner/emergency', badge: null }
      ]
    }
  ];

  get currentMenuItems() {
    const user = this.authService.getCurrentUser();
    switch (user?.role) {
      case 'SUPER_ADMIN':
        return this.superAdminMenuItems;
      case 'ADMIN':
        return this.adminMenuItems;
      case 'MANAGER':
        return this.managerMenuItems;
      case 'SHOP_OWNER':
        return this.shopOwnerMenuItems;
      case 'DELIVERY_PARTNER':
        return this.deliveryPartnerMenuItems;
      default:
        return [];
    }
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
      case 'SUPER_ADMIN': return 'Super Administrator';
      case 'ADMIN': return 'Administrator';
      case 'MANAGER': return 'Manager';
      case 'SHOP_OWNER': return 'Shop Owner';
      case 'DELIVERY_PARTNER': return 'Delivery Partner';
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

  // Notification methods
  getNotificationCount(): number {
    return this.notifications.filter(n => !n.read).length;
  }

  // Page title methods
  getCurrentPageTitle(): string {
    const url = this.router.url;
    const allItems = this.currentMenuItems.flatMap(section => section.items);
    const menuItem = allItems.find((item: any) => url.startsWith(item.route));
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