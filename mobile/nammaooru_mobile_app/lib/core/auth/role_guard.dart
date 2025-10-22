import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';

class RoleGuard {
  static Future<String?> redirectLogic(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final currentPath = state.uri.path;

    debugPrint('RoleGuard - Path: $currentPath, LoggedIn: $isLoggedIn');

    // Allow guest access to customer browsing routes
    if (!isLoggedIn) {
      if (_isAuthRoute(currentPath)) {
        debugPrint('RoleGuard - Allowing auth route: $currentPath');
        return null; // Allow auth routes
      }

      if (_isGuestAccessibleRoute(currentPath)) {
        debugPrint('RoleGuard - Allowing guest access to: $currentPath');
        return null; // Allow guest browsing
      }

      debugPrint('RoleGuard - Redirecting to login from: $currentPath');
      return '/login'; // Redirect to login for protected routes
    }

    final userRole = await AuthService.getCurrentUserRole();
    debugPrint('RoleGuard - User role: $userRole');

    // Only redirect from auth routes ONCE after login, not on manual navigation
    if (_isAuthRoute(currentPath)) {
      debugPrint('RoleGuard - Auth route detected: $currentPath');
      return _getHomeRouteForRole(userRole);
    }

    // If user is trying to access customer dashboard, allow it for USER/CUSTOMER roles
    if (currentPath == '/customer/dashboard' && (userRole == 'USER' || userRole == 'CUSTOMER')) {
      debugPrint('RoleGuard - Allowing customer dashboard access');
      return null;
    }

    // Allow navigation to any route the user has permission for
    if (_hasPermissionForRoute(currentPath, userRole)) {
      return null; // Allow navigation
    }

    // If user doesn't have permission, redirect to their dashboard
    return _getHomeRouteForRole(userRole);
  }

  /// Routes that guests can access without login
  static bool _isGuestAccessibleRoute(String path) {
    final guestRoutes = [
      '/customer/dashboard',
      '/customer/shops',
      '/customer/shop/',
      '/customer/categories',
      '/customer/cart',
    ];

    // Check if path starts with any guest route
    for (final route in guestRoutes) {
      if (path.startsWith(route)) {
        return true;
      }
    }

    return false;
  }
  
  static bool _isAuthRoute(String path) {
    final authRoutes = ['/login', '/register', '/otp-verification', '/forgot-password'];
    return authRoutes.contains(path) || path == '/';
  }
  
  static bool _hasPermissionForRoute(String path, String? userRole) {
    if (userRole == null) return false;
    
    if (path.startsWith('/customer/')) {
      return userRole == 'CUSTOMER' || userRole == 'USER';
    }
    
    if (path.startsWith('/shop-owner/')) {
      return userRole == 'SHOP_OWNER';
    }
    
    if (path.startsWith('/delivery-partner/')) {
      return userRole == 'DELIVERY_PARTNER';
    }
    
    return true;
  }
  
  static String _getHomeRouteForRole(String? userRole) {
    switch (userRole) {
      case 'CUSTOMER':
      case 'USER':  // USER role from backend maps to customer dashboard
        return '/customer/dashboard';
      case 'SHOP_OWNER':
        return '/shop-owner/dashboard';
      case 'DELIVERY_PARTNER':
        return '/delivery-partner/dashboard';
      default:
        return '/login';
    }
  }
  
  static Widget buildRoleBasedWidget({
    required String? userRole,
    Widget? customerWidget,
    Widget? shopOwnerWidget,
    Widget? deliveryPartnerWidget,
    Widget? defaultWidget,
  }) {
    switch (userRole) {
      case 'CUSTOMER':
      case 'USER':  // USER role from backend maps to customer widgets
        return customerWidget ?? defaultWidget ?? const SizedBox.shrink();
      case 'SHOP_OWNER':
        return shopOwnerWidget ?? defaultWidget ?? const SizedBox.shrink();
      case 'DELIVERY_PARTNER':
        return deliveryPartnerWidget ?? defaultWidget ?? const SizedBox.shrink();
      default:
        return defaultWidget ?? const SizedBox.shrink();
    }
  }
  
  static List<BottomNavigationBarItem> getRoleBasedNavItems(String? userRole) {
    switch (userRole) {
      case 'CUSTOMER':
      case 'USER':  // USER role from backend gets customer navigation
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case 'SHOP_OWNER':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case 'DELIVERY_PARTNER':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      default:
        return [];
    }
  }
}