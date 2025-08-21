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
    
    if (!isLoggedIn) {
      if (_isAuthRoute(currentPath)) {
        return null;
      }
      return '/login';
    }
    
    final userRole = await AuthService.getCurrentUserRole();
    
    if (_isAuthRoute(currentPath)) {
      return _getHomeRouteForRole(userRole);
    }
    
    if (!_hasPermissionForRoute(currentPath, userRole)) {
      return _getHomeRouteForRole(userRole);
    }
    
    return null;
  }
  
  static bool _isAuthRoute(String path) {
    final authRoutes = ['/login', '/register', '/otp-verification', '/forgot-password'];
    return authRoutes.contains(path) || path == '/';
  }
  
  static bool _hasPermissionForRoute(String path, String? userRole) {
    if (userRole == null) return false;
    
    if (path.startsWith('/customer/')) {
      return userRole == 'CUSTOMER';
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
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
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