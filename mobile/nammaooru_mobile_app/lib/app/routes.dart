import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/role_guard.dart';
import '../core/auth/auth_service.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/customer/dashboard/customer_dashboard.dart';
import '../features/customer/screens/shop_listing_screen.dart';
import '../features/customer/screens/shop_details_screen.dart';
import '../features/customer/screens/profile_screen.dart';
import '../features/customer/screens/address_management_screen.dart';
import '../features/customer/cart/cart_screen.dart';
import '../features/customer/screens/orders_screen.dart';
import '../features/shop_owner/dashboard/shop_owner_dashboard.dart';
import '../features/shop_owner/products/product_management_screen.dart';
import '../features/shop_owner/orders/order_processing_screen.dart';
import '../features/shop_owner/analytics/analytics_screen.dart';
import '../features/shop_owner/inventory/inventory_screen.dart';
import '../features/delivery_partner/dashboard/delivery_partner_dashboard.dart';
// import '../features/delivery_fee_test/delivery_fee_test_screen.dart'; // Temporarily disabled

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: RoleGuard.redirectLogic,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // GoRoute(
      //   path: '/delivery-fee-test',
      //   builder: (context, state) => const DeliveryFeeTestScreen(),
      // ), // Temporarily disabled
      ShellRoute(
        builder: (context, state, child) {
          return CustomerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/customer/dashboard',
            builder: (context, state) => const CustomerDashboard(),
          ),
          GoRoute(
            path: '/customer/shops',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              final categoryTitle = state.uri.queryParameters['categoryTitle'];
              return ShopListingScreen(
                category: category,
                categoryTitle: categoryTitle,
              );
            },
          ),
          GoRoute(
            path: '/customer/shop/:shopId',
            builder: (context, state) {
              final shopIdStr = state.pathParameters['shopId']!;
              final shopId = int.parse(shopIdStr);
              final shop = state.extra as Map<String, dynamic>?;
              return ShopDetailsScreen(
                shopId: shopId,
                shop: shop,
              );
            },
          ),
          GoRoute(
            path: '/customer/categories',
            builder: (context, state) => const ShopListingScreen(
              categoryTitle: 'All Categories',
            ),
          ),
          GoRoute(
            path: '/customer/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/customer/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/customer/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/customer/addresses',
            builder: (context, state) => const AddressManagementScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ShopOwnerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/shop-owner/dashboard',
            builder: (context, state) => const ShopOwnerDashboard(),
          ),
          GoRoute(
            path: '/shop-owner/products',
            builder: (context, state) => const ProductManagementScreen(),
          ),
          GoRoute(
            path: '/shop-owner/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/shop-owner/orders-management',
            builder: (context, state) => const OrderProcessingScreen(),
          ),
          GoRoute(
            path: '/shop-owner/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DeliveryPartnerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/delivery-partner/dashboard',
            builder: (context, state) => const DeliveryPartnerDashboard(),
          ),
        ],
      ),
    ],
  );
}

class CustomerShell extends StatefulWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userRole = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = userRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToCustomerRoute(index, context);
        },
        items: RoleGuard.getRoleBasedNavItems(_userRole),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _navigateToCustomerRoute(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customer/dashboard');
        break;
      case 1:
        context.go('/customer/cart');
        break;
      case 2:
        context.go('/customer/orders');
        break;
      case 3:
        context.go('/customer/profile');
        break;
    }
  }
}

class ShopOwnerShell extends StatefulWidget {
  final Widget child;

  const ShopOwnerShell({super.key, required this.child});

  @override
  State<ShopOwnerShell> createState() => _ShopOwnerShellState();
}

class _ShopOwnerShellState extends State<ShopOwnerShell> {
  int _currentIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userRole = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = userRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToShopOwnerRoute(index, context);
        },
        items: RoleGuard.getRoleBasedNavItems(_userRole),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _navigateToShopOwnerRoute(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/shop-owner/dashboard');
        break;
      case 1:
        context.go('/shop-owner/products');
        break;
      case 2:
        context.go('/shop-owner/orders-management');
        break;
      case 3:
        context.go('/shop-owner/analytics');
        break;
      case 4:
        context.go('/shop-owner/profile');
        break;
    }
  }
}

class DeliveryPartnerShell extends StatefulWidget {
  final Widget child;

  const DeliveryPartnerShell({super.key, required this.child});

  @override
  State<DeliveryPartnerShell> createState() => _DeliveryPartnerShellState();
}

class _DeliveryPartnerShellState extends State<DeliveryPartnerShell> {
  int _currentIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userRole = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = userRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToDeliveryPartnerRoute(index, context);
        },
        items: RoleGuard.getRoleBasedNavItems(_userRole),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _navigateToDeliveryPartnerRoute(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/delivery-partner/dashboard');
        break;
      case 1:
        context.go('/delivery-partner/orders');
        break;
      case 2:
        context.go('/delivery-partner/map');
        break;
      case 3:
        context.go('/delivery-partner/earnings');
        break;
      case 4:
        context.go('/delivery-partner/profile');
        break;
    }
  }
}
