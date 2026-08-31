import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/role_guard.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/language_select_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/customer/dashboard/customer_dashboard.dart';
import '../features/customer/screens/shop_listing_screen.dart';
import '../features/customer/screens/shop_details_screen.dart';
// import '../features/customer/screens/shop_details_clean.dart';
import '../features/customer/screens/profile_screen.dart';
import '../features/customer/screens/address_management_screen.dart';
import '../features/customer/screens/notifications_screen.dart';
import '../features/customer/cart/cart_screen.dart';
import '../features/customer/screens/orders_screen.dart';
import '../features/customer/screens/marketplace_screen.dart';
import '../features/customer/screens/create_post_screen.dart';
import '../features/customer/screens/farmer_products_screen.dart';
import '../features/customer/screens/create_farmer_post_screen.dart';
import '../features/customer/screens/labour_screen.dart';
import '../features/customer/screens/create_labour_screen.dart';
import '../features/customer/screens/travel_screen.dart';
import '../features/customer/screens/create_travel_screen.dart';
// import '../features/customer/screens/parcel_screen.dart';
// import '../features/customer/screens/create_parcel_screen.dart';
import '../features/customer/screens/panchayat_screen.dart';
import '../features/customer/screens/my_posts_screen.dart';
import '../features/customer/screens/womens_corner_screen.dart';
import '../features/customer/screens/create_womens_corner_screen.dart';
import '../features/customer/screens/smart_order_screen.dart';
import '../features/customer/screens/voice_assistant_screen.dart';
import '../features/shop_owner/dashboard/shop_owner_dashboard.dart';
import '../features/shop_owner/orders/order_processing_screen.dart';
// import '../features/delivery_fee_test/delivery_fee_test_screen.dart'; // Temporarily disabled
import 'package:provider/provider.dart';
import '../shared/providers/feature_config_provider.dart';
import '../shared/providers/cart_provider.dart';
import '../core/theme/village_theme.dart';

/// Closes the keyboard whenever a screen is pushed or popped so a
/// text field's focus never carries over to the next screen
class _KeyboardDismissObserver extends NavigatorObserver {
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();
}

class AppRouter {
  // Global navigator key for navigation from services
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Lets screens (e.g. voice assistant) react when another route
  /// covers them — used to silence TTS/mic on navigation
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: RoleGuard.redirectLogic,
    observers: [_KeyboardDismissObserver(), routeObserver],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const LanguageSelectScreen(),
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
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
            path: '/customer/cart',
            builder: (context, state) => const CartScreen(),
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
          GoRoute(
            path: '/customer/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/customer/marketplace/create',
            builder: (context, state) => const CreatePostScreen(),
          ),
          GoRoute(
            path: '/customer/farmer-products',
            builder: (context, state) => const FarmerProductsScreen(),
          ),
          GoRoute(
            path: '/customer/farmer-products/create',
            builder: (context, state) => const CreateFarmerPostScreen(),
          ),
          GoRoute(
            path: '/customer/labours',
            builder: (context, state) => const LabourScreen(),
          ),
          GoRoute(
            path: '/customer/labours/create',
            builder: (context, state) => const CreateLabourScreen(),
          ),
          GoRoute(
            path: '/customer/travels',
            builder: (context, state) => const TravelScreen(),
          ),
          GoRoute(
            path: '/customer/travels/create',
            builder: (context, state) => const CreateTravelScreen(),
          ),
          GoRoute(
            path: '/customer/womens-corner',
            builder: (context, state) => const WomensCornerScreen(),
          ),
          GoRoute(
            path: '/customer/womens-corner/create',
            builder: (context, state) => const CreateWomensCornerScreen(),
          ),
          GoRoute(
            path: '/customer/smart-order',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return SmartOrderScreen(
                shopId: extra?['shopId'] as int?,
                shopName: extra?['shopName'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/customer/voice-assistant',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return VoiceAssistantScreen(
                shopId: extra?['shopId'] as int?,
                shopName: extra?['shopName'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/customer/village',
            builder: (context, state) => const PanchayatScreen(),
          ),
          GoRoute(
            path: '/customer/my-posts',
            builder: (context, state) {
              final module = state.uri.queryParameters['module'];
              return MyPostsScreen(initialModule: module);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/shop-owner/dashboard',
        builder: (context, state) => const ShopOwnerDashboard(),
      ),
      GoRoute(
        path: '/shop-owner/orders-management',
        builder: (context, state) => const OrderProcessingScreen(),
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
  // All possible nav items in order: Home is always shown
  static const List<_NavItem> _allNavItems = [
    _NavItem(key: 'nav_home', label: 'Home', icon: Icons.home, route: '/customer/dashboard', alwaysShow: true),
    _NavItem(key: 'nav_cart', label: 'Cart', icon: Icons.shopping_cart, route: '/customer/cart'),
    _NavItem(key: 'nav_orders', label: 'Orders', icon: Icons.list_alt, route: '/customer/orders'),
    _NavItem(key: 'nav_profile', label: 'Profile', icon: Icons.person, route: '/customer/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // Deliberately NOT listening to CartProvider here. Rebuilding the whole
    // shell (Scaffold + body slot) on EVERY cart notify constantly re-laid-out
    // the active page's slot, and under heavy add/remove churn the page's own
    // provider subscription was intermittently lost - the cart screen then
    // froze (state changed, no redraw) until re-entered. Only the little cart
    // badge listens now, via the Selector below.
    return Consumer<FeatureConfigProvider>(
      builder: (context, featureConfig, _) {
        final visibleItems = _allNavItems
            .where((item) => item.alwaysShow || featureConfig.isVisible(item.key))
            .toList();

        final path = GoRouterState.of(context).uri.path;
        var selectedIndex = 0;
        for (var i = 0; i < visibleItems.length; i++) {
          final route = visibleItems[i].route;
          if (route == '/customer/dashboard') continue;
          if (path == route || path.startsWith('$route/')) {
            selectedIndex = i;
            break;
          }
        }
        if (selectedIndex >= visibleItems.length) selectedIndex = 0;

        final showBottomNav = visibleItems.length >= 2;

        return Scaffold(
          body: widget.child,
          bottomNavigationBar: showBottomNav
              ? BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    context.go(visibleItems[index].route);
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: VillageTheme.primaryGreen,
                  unselectedItemColor: Colors.black54,
                  items: visibleItems.map((item) {
                    // Only the badge itself listens to the cart - see comment
                    // at the top of build() for why the shell must not.
                    return BottomNavigationBarItem(
                      icon: item.key == 'nav_cart'
                          ? Selector<CartProvider, int>(
                              selector: (_, cart) => cart.productCount,
                              builder: (_, badge, __) => Badge(
                                isLabelVisible: badge > 0,
                                label: Text('$badge'),
                                child: Icon(item.icon),
                              ),
                            )
                          : Icon(item.icon),
                      label: item.label,
                    );
                  }).toList(),
                )
              : null,
        );
      },
    );
  }
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final String route;
  final bool alwaysShow;

  const _NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
    this.alwaysShow = false,
  });
}
