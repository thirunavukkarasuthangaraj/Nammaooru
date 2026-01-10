import { Component, OnInit, ViewChild, OnDestroy, HostListener } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { MatSidenav } from '@angular/material/sidenav';
import { AuthService } from '../../core/services/auth.service';
import { VersionService } from '../../core/services/version.service';
import { OrderService } from '../../core/services/order.service';
import { SoundService } from '../../core/services/sound.service';
import { MenuPermissionService, MENU_PERMISSION_ROUTES } from '../../core/services/menu-permission.service';
import { User, UserRole } from '../../core/models/auth.model';
import { Observable, Subject, debounceTime, distinctUntilChanged, filter, interval } from 'rxjs';
import { takeUntil, catchError, switchMap } from 'rxjs/operators';
import { of } from 'rxjs';

interface HeaderNotification {
  id: number;
  title: string;
  message: string;
  time: Date;
  type: string;
  icon: string;
  read: boolean;
}

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
  
  // Notifications - loaded from API
  notificationCount = 0;

  // Version info
  versionInfo: any = null;
  notifications: HeaderNotification[] = [];
  notificationsLoading = false;
  private previousPendingCount = -1; // -1 means not initialized yet (first load)

  private destroy$ = new Subject<void>();

  // User menu permissions (for shop owners)
  userMenuPermissions: Set<string> = new Set();

  // SUPER ADMIN - Can see ALL menus from all roles
  superAdminMenuItems = [
    {
      category: 'System Overview',
      items: [
        { title: 'Analytics', icon: 'analytics', route: '/analytics', badge: null },
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
      category: 'Thiru Software',
      items: [
        { title: 'All Shops', icon: 'store', route: '/shops', badge: null },
        { title: 'Shop Master', icon: 'store', route: '/shops/master', badge: null },
        { title: 'Shop Approvals', icon: 'check_circle', route: '/shops/approvals', badge: '3' }
      ]
    },
    {
      category: 'Product Management',
      items: [
        { title: 'All Products', icon: 'inventory', route: '/products', badge: null },
        { title: 'Product Master', icon: 'inventory_2', route: '/products/master', badge: null },
        { title: 'Categories', icon: 'category', route: '/products/categories', badge: null },
        { title: 'Bulk Import', icon: 'cloud_upload', route: '/products/bulk-import', badge: null }
      ]
    },
    {
      category: 'Order Management',
      items: [
        { title: 'All Orders', icon: 'receipt_long', route: '/orders', badge: '45' },
        { title: 'Order Issues', icon: 'report_problem', route: '/orders/issues', badge: '3' }
      ]
    },
    {
      category: 'Delivery Management',
      items: [
        { title: 'Delivery Partners', icon: 'delivery_dining', route: '/delivery/admin/partners', badge: '5' },
        { title: 'Order Assignments', icon: 'assignment', route: '/delivery/admin/assignments', badge: null },
        { title: 'Live Tracking', icon: 'gps_fixed', route: '/delivery/admin/tracking', badge: null },
        { title: 'Delivery Zones', icon: 'map', route: '/delivery/zones', badge: null },
        { title: 'Delivery Fee Management', icon: 'local_shipping', route: '/admin/delivery-fees', badge: null }
      ]
    },
    {
      category: 'Financial Management',
      items: [
        { title: 'Revenue Overview', icon: 'payments', route: '/finance/revenue', badge: null },
        { title: 'Partner Payments', icon: 'account_balance_wallet', route: '/delivery/partner-payments', badge: null },
        { title: 'Partner Payouts', icon: 'account_balance', route: '/finance/payouts', badge: null },
        { title: 'Commission Settings', icon: 'percent', route: '/finance/commission', badge: null },
        { title: 'Financial Reports', icon: 'assessment', route: '/finance/reports', badge: null }
      ]
    },
    {
      category: 'Marketing & Promotions',
      items: [
        { title: 'Promo Codes', icon: 'local_offer', route: '/admin/promo-codes', badge: null },
        { title: 'Push Notifications', icon: 'notifications_active', route: '/admin/push-notifications', badge: null },
        { title: 'Marketing Messages', icon: 'campaign', route: '/admin/marketing', badge: null }
      ]
    },
    {
      category: 'System Administration',
      items: [
        { title: 'System Settings', icon: 'settings', route: '/settings', badge: null },
        { title: 'App Configuration', icon: 'tune', route: '/admin/config', badge: null },
        { title: 'Menu Permissions', icon: 'menu_open', route: '/admin/menu-permissions', badge: null },
        { title: 'Delivery Fee Management', icon: 'local_shipping', route: '/admin/delivery-fees', badge: null },
        { title: 'Notifications', icon: 'notifications', route: '/notifications', badge: '8' },
        { title: 'Audit Logs', icon: 'history', route: '/admin/audit', badge: null },
        { title: 'Backup & Restore', icon: 'backup', route: '/admin/backup', badge: null }
      ]
    }
  ];

  // ADMIN - Standard admin access
  adminMenuItems = [
    {
      category: 'Order Management',
      items: [
        { title: 'All Orders', icon: 'receipt_long', route: '/orders', badge: '12' }
      ]
    },
    {
      category: 'Thiru Software',
      items: [
        { title: 'Shop Master', icon: 'store', route: '/shops/master', badge: null },
        { title: 'Shop Approvals', icon: 'check_circle', route: '/shops/approvals', badge: '3' }
      ]
    },
    {
      category: 'Product Management',
      items: [
        { title: 'Product Master', icon: 'inventory_2', route: '/products/master', badge: null },
        { title: 'Categories', icon: 'category', route: '/products/categories', badge: null },
        { title: 'Bulk Import', icon: 'cloud_upload', route: '/products/bulk-import', badge: null }
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
        { title: 'Live Tracking', icon: 'gps_fixed', route: '/delivery/admin/tracking', badge: null }
      ]
    },
    {
      category: 'Marketing & Promotions',
      items: [
        { title: 'Promo Codes', icon: 'local_offer', route: '/admin/promo-codes', badge: null },
        { title: 'Push Notifications', icon: 'notifications_active', route: '/admin/push-notifications', badge: null },
        { title: 'Marketing Messages', icon: 'campaign', route: '/admin/marketing', badge: null }
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
        { title: 'Dashboard', icon: 'dashboard', route: '/shop-owner/dashboard', badge: null }
      ]
    },
    {
      category: 'Thiru Software',
      items: [
        { title: 'Shop Profile', icon: 'store', route: '/shop-owner/profile', badge: null }
      ]
    },
    {
      category: 'Products',
      items: [
        { title: 'My Products', icon: 'inventory_2', route: '/shop-owner/my-products', badge: null },
        { title: 'Browse Products', icon: 'search', route: '/shop-owner/browse-products', badge: null },
        { title: 'Combos', icon: 'card_giftcard', route: '/shop-owner/combos', badge: null },
        { title: 'Bulk Import', icon: 'cloud_upload', route: '/products/bulk-import', badge: null }
      ]
    },
    {
      category: 'Orders',
      items: [
        { title: 'Order Management', icon: 'assignment_turned_in', route: '/shop-owner/orders-management', badge: '7' },
        { title: 'Notifications', icon: 'notifications', route: '/shop-owner/notifications', badge: '5' }
      ]
    },
    {
      category: 'Marketing',
      items: [
        { title: 'Promo Codes', icon: 'local_offer', route: '/shop-owner/promo-codes', badge: null }
      ]
    }
  ];

  deliveryPartnerMenuItems = [
    {
      category: 'Main',
      items: [
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

  // Customer menu items - Simplified to 4 core features
  customerMenuItems = [
    {
      category: 'Main',
      items: [
        { title: 'Shop Browser', icon: 'store', route: '/customer/shops', badge: null },
        { title: 'Orders', icon: 'receipt_long', route: '/customer/orders', badge: null },
        { title: 'Cart', icon: 'shopping_cart', route: '/customer/cart', badge: null },
        { title: 'Profile & Address', icon: 'person', route: '/customer/profile', badge: null }
      ]
    }
  ];

  get currentMenuItems() {
    const user = this.authService.getCurrentUser();

    // If no user is authenticated, return empty menu
    if (!user || !this.authService.isAuthenticated()) {
      return [];
    }

    // Log for debugging
    console.log('Current user role:', user.role, 'Type:', typeof user.role);

    switch (user.role) {
      case UserRole.SUPER_ADMIN:
      case 'SUPER_ADMIN':
        console.log('Showing SUPER_ADMIN menus');
        return this.superAdminMenuItems;
      case UserRole.ADMIN:
      case 'ADMIN':
        console.log('Showing ADMIN menus');
        return this.adminMenuItems;
      case UserRole.MANAGER:
      case 'MANAGER':
        console.log('Showing MANAGER menus');
        return this.managerMenuItems;
      case UserRole.SHOP_OWNER:
      case 'SHOP_OWNER':
        console.log('Showing SHOP_OWNER menus');
        return this.getFilteredShopOwnerMenus();
      case UserRole.DELIVERY_PARTNER:
      case 'DELIVERY_PARTNER':
        console.log('Showing DELIVERY_PARTNER menus');
        return this.deliveryPartnerMenuItems;
      case UserRole.USER:
      case UserRole.CUSTOMER:
      case 'USER':
      case 'CUSTOMER':
        console.log('Showing CUSTOMER menus');
        return this.customerMenuItems;
      default:
        console.log('Unknown role, showing empty menu:', user.role);
        return [];
    }
  }

  /**
   * Filter shop owner menus based on user permissions
   */
  private getFilteredShopOwnerMenus(): any[] {
    // If no permissions loaded yet, show all menus (will update after permissions load)
    if (this.userMenuPermissions.size === 0) {
      return this.shopOwnerMenuItems;
    }

    // Map route to permission name
    const routeToPermission: { [key: string]: string } = {};
    for (const [permission, route] of Object.entries(MENU_PERMISSION_ROUTES)) {
      routeToPermission[route] = permission;
    }

    // Filter menu items based on permissions
    const filteredMenus: any[] = [];

    for (const category of this.shopOwnerMenuItems) {
      const filteredItems: any[] = [];

      for (const item of category.items) {
        const permission = routeToPermission[item.route];
        // If no permission mapping exists for this route, show it
        if (!permission || this.userMenuPermissions.has(permission)) {
          filteredItems.push(item);
        }
      }

      // Only include category if it has visible items
      if (filteredItems.length > 0) {
        filteredMenus.push({
          category: category.category,
          items: filteredItems
        });
      }
    }

    return filteredMenus;
  }

  constructor(
    private authService: AuthService,
    public router: Router,
    private versionService: VersionService,
    private orderService: OrderService,
    private soundService: SoundService,
    private menuPermissionService: MenuPermissionService
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {
    this.checkScreenSize();
    this.setupSearchSubscription();
    this.setupRouterSubscription();
    this.loadVersionInfo();
    this.loadNotifications();
    this.loadMenuPermissions();

    // Subscribe to menu permissions changes
    this.menuPermissionService.menuPermissions$
      .pipe(takeUntil(this.destroy$))
      .subscribe(permissions => {
        this.userMenuPermissions = permissions;
      });

    // Auto-refresh notifications every 60 seconds
    interval(60000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.loadNotifications();
      });
  }

  private loadMenuPermissions(): void {
    const currentUser = this.authService.getCurrentUser();
    if (currentUser && this.authService.isAuthenticated()) {
      this.menuPermissionService.loadMyMenuPermissions();
    }
  }
  
  private loadVersionInfo(): void {
    this.versionService.getVersionInfo().subscribe(info => {
      this.versionInfo = info;
    });
  }

  private loadNotifications(): void {
    const currentUser = this.authService.getCurrentUser();
    if (!currentUser || !this.authService.isAuthenticated()) {
      return;
    }

    // Get shop ID for shop owner, or load general notifications
    const shopId = localStorage.getItem('current_shop_id');

    if (shopId && (currentUser.role === 'SHOP_OWNER' || (currentUser.role as any) === UserRole.SHOP_OWNER)) {
      this.notificationsLoading = true;
      this.orderService.getOrdersByShop(shopId, 0, 10)
        .pipe(
          takeUntil(this.destroy$),
          catchError(() => of({ data: { content: [] } }))
        )
        .subscribe({
          next: (response) => {
            const orders = response.data?.content || [];

            // Count current pending orders
            const currentPendingCount = orders.filter((order: any) => order.status === 'PENDING').length;

            // Play sound if there are new pending orders (but not on first load)
            if (this.previousPendingCount >= 0 && currentPendingCount > this.previousPendingCount) {
              console.log('🔔 New order detected! Playing notification sound...');
              this.soundService.playOrderNotification();
            }

            // Update previous count (first load will set it from -1 to actual count)
            this.previousPendingCount = currentPendingCount;

            this.notifications = orders
              .filter((order: any) => order.status === 'PENDING' || this.isRecentOrder(order))
              .slice(0, 5)
              .map((order: any) => this.orderToNotification(order));
            this.notificationCount = this.notifications.filter(n => !n.read).length;
            this.notificationsLoading = false;
          },
          error: () => {
            this.notificationsLoading = false;
          }
        });
    }
  }

  private isRecentOrder(order: any): boolean {
    const orderDate = new Date(order.createdAt);
    const oneHourAgo = new Date();
    oneHourAgo.setHours(oneHourAgo.getHours() - 1);
    return orderDate > oneHourAgo;
  }

  private orderToNotification(order: any): HeaderNotification {
    let title = '';
    let icon = 'shopping_cart';
    let type = 'order';

    switch (order.status) {
      case 'PENDING':
        title = 'New Order';
        icon = 'shopping_cart';
        type = 'order';
        break;
      case 'CONFIRMED':
      case 'ACCEPTED':
        title = 'Order Accepted';
        icon = 'check_circle';
        type = 'success';
        break;
      case 'PREPARING':
        title = 'Preparing Order';
        icon = 'restaurant';
        type = 'info';
        break;
      case 'READY_FOR_PICKUP':
        title = 'Ready for Pickup';
        icon = 'inventory_2';
        type = 'info';
        break;
      case 'OUT_FOR_DELIVERY':
        title = 'Out for Delivery';
        icon = 'delivery_dining';
        type = 'info';
        break;
      case 'DELIVERED':
        title = 'Delivered';
        icon = 'done_all';
        type = 'success';
        break;
      case 'CANCELLED':
        title = 'Order Cancelled';
        icon = 'cancel';
        type = 'warning';
        break;
      default:
        title = 'Order Update';
        icon = 'notifications';
        type = 'info';
    }

    return {
      id: order.id,
      title: title,
      message: `${order.orderNumber} - ₹${order.totalAmount}`,
      time: new Date(order.createdAt),
      type: type,
      icon: icon,
      read: order.status !== 'PENDING'
    };
  }

  // Format time for display in Indian format
  formatNotificationTime(date: Date): string {
    if (!date) return '';
    const d = new Date(date);
    const day = d.getDate();
    const month = d.getMonth() + 1;
    const year = d.getFullYear() % 100;
    let hours = d.getHours();
    const minutes = d.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    return `${day}/${month}/${year}, ${hours}:${minutes} ${ampm}`;
  }

  getClientVersion(): string {
    return this.versionService.getVersion().replace('v', '');
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
    // Match CSS media query at 1024px where sidebar is hidden
    this.isMobile = window.innerWidth <= 1024;
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

  markAllNotificationsAsRead(): void {
    this.notifications.forEach(notification => {
      notification.read = true;
    });
    this.notificationCount = 0;
  }

  markNotificationAsRead(notificationId: number): void {
    const notification = this.notifications.find(n => n.id === notificationId);
    if (notification && !notification.read) {
      notification.read = true;
      this.notificationCount = this.getNotificationCount();
    }
  }

  onNotificationClick(event: MouseEvent): void {
    // Prevent menu from closing when clicking on notification items
    event.stopPropagation();
  }

  // Page title methods
  getCurrentPageTitle(): string {
    const url = this.router.url;
    const allItems = this.currentMenuItems.flatMap(section => section.items);
    const menuItem = allItems.find((item: any) => url.startsWith(item.route));
    return menuItem ? menuItem.title : 'NammaOoru Thiru Software';
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