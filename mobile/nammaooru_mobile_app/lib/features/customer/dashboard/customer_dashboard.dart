import '../screens/transport/where_is_bus_screen.dart';
import '../../../shared/widgets/gentle_motion.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/order_api_service.dart';
import '../../../shared/services/notification_service.dart';
import '../screens/shop_details_screen.dart';
// import '../screens/shop_details_modern_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/notifications_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/address_service.dart';
import '../widgets/deliver_to_picker.dart';
import '../../../shared/widgets/platform_promos_carousel.dart';
import '../../../shared/widgets/promo_video_banner.dart';
import '../../../shared/widgets/promo_code_sheet.dart';
import '../../../core/services/promo_code_service.dart';
import '../../../services/version_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/update_dialog.dart';
import '../services/combo_service.dart';
import '../models/combo_model.dart';
import '../widgets/combo_banner_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../services/marketplace_service.dart';
import '../services/feature_config_service.dart';
import '../../../shared/providers/feature_config_provider.dart';
import '../../../core/services/api_service.dart';
import '../screens/marketplace_screen.dart';
import '../screens/bus_timing_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/farmer_products_screen.dart';
import '../screens/labour_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/travel_screen.dart';
import '../screens/parcel_screen.dart';
import '../screens/real_estate_screen.dart';
import '../screens/rental_screen.dart';
import '../screens/farmer_post_detail_screen.dart';
import '../screens/labour_post_detail_screen.dart';
import '../screens/travel_post_detail_screen.dart';
import '../screens/parcel_post_detail_screen.dart';
import '../screens/panchayat_screen.dart';
import '../screens/womens_corner_screen.dart';
import '../screens/local_shops_screen.dart';
import '../../../core/services/service_area_service.dart';
import '../../../shared/widgets/service_area_dialog.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with WidgetsBindingObserver {
  // App tour — one key per visible menu tile
  final Map<String, GlobalKey> _featureTourKeys = {};
  bool _tourChecked = false;
  BuildContext? _showcaseCtx;

  String _selectedLocation = 'Getting your location...';
  double? _userLatitude;
  double? _userLongitude;
  bool _isLoadingShops = false;
  bool _isLoadingOrders = false;
  bool _isLocationPickerOpen = false;
  List<dynamic> _featuredShops = [];
  List<dynamic> _recentOrders = [];
  List<CustomerCombo> _combos = [];
  List<PromoCode> _promos = [];
  DateTime? _lastBackPressTime;
  final PageController _unifiedOffersController = PageController();
  Timer? _autoSlideTimer;
  int _currentOfferPage = 0;

  List<dynamic> _marketplacePosts = [];
  bool _isLoadingMarketplace = false;

  List<Map<String, dynamic>> _dynamicFeatures = [];
  bool _isLoadingFeatures = true;  // Start true so defaults don't flash before API responds

  // Featured posts from all categories for banner carousel
  List<Map<String, dynamic>> _featuredPosts = [];
  bool _launchBannerShown = false;

  bool _serviceAreaBlocked = false;
  Future<void>? _serviceAreaCheckFuture;

  final _shopApi = ShopApiService();
  final _orderApi = OrderApiService();
  bool _isReordering = false;
  final _promoService = PromoCodeService();
  final _marketplaceService = MarketplaceService();
  final _featureConfigService = FeatureConfigService();
  final _apiService = ApiService();
  final _serviceAreaService = ServiceAreaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🔵 CustomerDashboard initState called');
    _checkVersionOnStartup();
    _initLocationThenLoadData();
    _checkSignupBonus();
    // App version checking is handled globally in app.dart, no need for duplicate check here
  }

  // If the OS silently killed and fast-restarted the app process while it was
  // backgrounded (common under memory pressure - feels instant to the user,
  // but every in-memory list including _promos/_combos comes back empty),
  // the "SPECIAL OFFERS" banner would otherwise just stay blank forever since
  // nothing else re-triggers that fetch. Retry once on resume, only when
  // there's actually nothing loaded - a no-op the vast majority of the time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _promos.isEmpty && _combos.isEmpty) {
      _loadPromos();
      _loadCombos();
    }
  }

  // Shows the welcome-bonus banner once, the first time the Home screen sees
  // an UNPAID bonus for this account - the grant itself always happens
  // server-side at registration; this is purely a read-only status check.
  Future<void> _checkSignupBonus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('signup_bonus_banner_shown') ?? false) return;

      final result = await _apiService.get('/customer/signup-bonus/mine');
      if (!mounted || result['success'] != true) return;

      final data = result['data'];
      if (data == null || data['status'] != 'UNPAID') return;

      await prefs.setBool('signup_bonus_banner_shown', true);
      final amount = (data['amount'] as num?)?.toStringAsFixed(0) ?? '10';

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🎉 Welcome Gift!'),
          content: Text(
            'You\'ve received ₹$amount as a welcome bonus. '
            'We\'ll send it to your registered mobile number via UPI shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Never let a bonus-status check disrupt the Home screen.
      print('Signup bonus check failed: $e');
    }
  }

  Future<void> _startTourIfNeeded(BuildContext showcaseCtx) async {
    _showcaseCtx = showcaseCtx;
    if (_tourChecked) return;
    _tourChecked = true;
    final prefs = await SharedPreferences.getInstance();
    final tourShown = prefs.getBool('app_tour_shown') ?? false;
    if (!tourShown && mounted) {
      await prefs.setBool('app_tour_shown', true);
      // Wait for dynamic features to load, then start tour on each tile
      Future.delayed(const Duration(milliseconds: 3000), () {
        _triggerTour();
      });
    }
  }

  void _triggerTour() {
    if (!mounted || _showcaseCtx == null) return;
    // User already navigated away from the dashboard — starting now would
    // draw the showcase overlay on top of the pushed screen.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final keys = _featureTourKeys.values.toList();
    if (keys.isEmpty) return;
    ShowCaseWidget.of(_showcaseCtx!).startShowCase(keys);
  }

  void _dismissTour() {
    if (_showcaseCtx == null) return;
    try {
      ShowCaseWidget.of(_showcaseCtx!).dismiss();
    } catch (_) {}
  }

  Future<void> _initLocationThenLoadData() async {
    final featureProvider = Provider.of<FeatureConfigProvider>(context, listen: false);

    // Load nav/section visibility immediately (no GPS needed)
    featureProvider.loadAppConfig();

    // Load feature config immediately — doesn't need GPS
    _loadFeatureConfig();

    // Previously this awaited GPS + reverse-geocoding before even starting
    // the shops/combos/promos/orders fetch, serially stacking a ~1-3s GPS
    // fix plus a network round-trip on top of everything else - the actual
    // source of the slow cold start. Now they run concurrently: the
    // location-independent sections (combos, recent orders, marketplace,
    // featured posts) render immediately, and location-dependent ones
    // (shops, promos) refresh once GPS resolves.
    final locationFuture = _getCurrentLocationOnStartup();
    _loadDashboardData();
    await locationFuture;

    if (mounted) {
      _loadFeaturedShops();
      _loadPromos();
    }

    // Check service area in background — stores future so _guardedNavigate can await it
    _serviceAreaCheckFuture = _checkServiceArea();
  }

  Future<void> _checkServiceArea() async {
    // Skip if no location available (fail-open)
    if (_userLatitude == null || _userLongitude == null) return;

    try {
      // Uses cached config for instant check; refreshes cache in background
      final blocked = await _serviceAreaService.checkAndBlock(
        _userLatitude!,
        _userLongitude!,
      );

      if (blocked && mounted) {
        setState(() => _serviceAreaBlocked = true);
        // Fetch full details for the dialog
        final result = await _serviceAreaService.checkServiceArea(
          _userLatitude!,
          _userLongitude!,
        );
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => ServiceAreaDialog(
              message: result?['message'] ?? 'Service is not available in your area.',
              radiusKm: (result?['radiusKm'] as num?)?.toDouble(),
              centerLat: (result?['centerLat'] as num?)?.toDouble(),
              centerLng: (result?['centerLng'] as num?)?.toDouble(),
              userLat: _userLatitude,
              userLng: _userLongitude,
            ),
          );
        }
      }
    } catch (e) {
      print('Service area check error: $e');
      // Fail-open: allow access on error
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSlideTimer?.cancel();
    _unifiedOffersController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationOnStartup() async {
    try {
      bool hasDisplayName = false;

      // Check if user is authenticated before loading saved addresses
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        // Try to load default saved address for display name only
        try {
          final savedAddresses = await AddressService.instance.getSavedAddresses();
          final defaultAddress = savedAddresses.where((addr) => addr.isDefault).firstOrNull;

          if (defaultAddress != null && mounted) {
            setState(() {
              _selectedLocation = '${defaultAddress.addressLine1}, ${defaultAddress.city}';
            });
            hasDisplayName = true;
          }
        } catch (e) {
          print('Error loading saved addresses: $e');
        }
      }

      // Always get GPS position for location-based shop filtering
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;

        // Only update display location if we don't have a saved address
        if (!hasDisplayName) {
          final address = await LocationService.instance.getAddressFromCoordinates(
            position.latitude!,
            position.longitude!,
          );

          if (address != null && mounted) {
            setState(() {
              final village = address['subLocality'] ?? '';
              final city = address['locality'] ?? '';

              if (village.isNotEmpty && city.isNotEmpty) {
                _selectedLocation = '$village, $city';
              } else if (city.isNotEmpty) {
                _selectedLocation = '$city, ${address['administrativeArea'] ?? ''}';
              } else {
                _selectedLocation = 'Tirupattur, Tamil Nadu';
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _selectedLocation = 'Tirupattur, Tamil Nadu'; // Fallback
        });
      }
    }
  }

  Future<void> _showLocationPicker() async {
    // Prevent multiple clicks with immediate flag setting
    if (_isLocationPickerOpen) return;

    _isLocationPickerOpen = true;
    try {
      await DeliverToPicker.show(
        context,
        currentLocation: _selectedLocation,
        onLocationSelected: (selectedLocation) {
          setState(() {
            _selectedLocation = selectedLocation;
            // DeliverToPicker only returns a display label; the actual
            // coordinates it just picked are stashed in LocationService's
            // cache (setManualPosition/getCurrentPosition) - pick them up
            // here so offers/shops filter by the newly selected location
            // instead of the stale one from app startup.
            if (LocationService.hasCachedPosition) {
              _userLatitude = LocationService.cachedLatitude;
              _userLongitude = LocationService.cachedLongitude;
            }
          });
          // Reload shops and offers around the newly chosen location
          _loadFeaturedShops();
          _loadPromos();
        },
        onAddressBookUpdated: _getCurrentLocationOnStartup,
      );
    } finally {
      _isLocationPickerOpen = false;
    }
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadFeaturedShops(),
      _loadRecentOrders(),
      _loadCombos(),
      _loadPromos(),
      _loadMarketplacePosts(),
      _loadFeaturedPosts(),
    ]);
    _startAutoSlideOffers();
    // The one-time launch interstitial was removed - redundant with the
    // "SPECIAL OFFERS" carousel already on the home screen.
  }

  Future<void> _showLaunchBanner() async {
    if (!mounted || _launchBannerShown || _featuredPosts.isEmpty) return;

    final banner = _featuredPosts.first;
    final imageUrl = (banner['image'] ?? '').toString();
    // A full-screen interstitial with no real banner image just shows a
    // generic gradient + icon placeholder, which looks unfinished/broken
    // rather than promotional - skip it entirely until a real image is set,
    // instead of showing that fallback as if it were the actual offer.
    if (imageUrl.isEmpty) return;
    _launchBannerShown = true;
    final color = banner['color'] is Color ? banner['color'] as Color : VillageTheme.primaryGreen;
    final icon = banner['icon'] is IconData ? banner['icon'] as IconData : Icons.local_offer_rounded;
    final title = (banner['title'] ?? 'Special Offer').toString();
    final subtitle = (banner['subtitle'] ?? '').toString();

    var dialogOpen = true;
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 620),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 28, spreadRadius: 2),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 330,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                ImageUrlHelper.getFullImageUrl(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLaunchBannerFallback(color, icon),
                              )
                            : _buildLaunchBannerFallback(color, icon),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                (banner['label'] ?? 'SPECIAL OFFER').toString().toUpperCase(),
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.black87)),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.35)),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _onFeaturedPostTap(banner);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Explore now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (dialogOpen && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
    await dialogFuture;
    dialogOpen = false;
  }

  Widget _buildLaunchBannerFallback(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.68)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(icon, size: 110, color: Colors.white.withOpacity(0.75))),
    );
  }

  Future<void> _loadFeaturedPosts() async {
    try {
      // Pass user location for nearby filtering
      final queryParams = <String, String>{};
      if (_userLatitude != null && _userLongitude != null) {
        queryParams['lat'] = _userLatitude.toString();
        queryParams['lng'] = _userLongitude.toString();
        queryParams['radius'] = '50';
      }
      final response = await _apiService.get('/featured-posts', queryParams: queryParams, includeAuth: false);
      if (response['success'] != true || response['data'] == null) return;

      final data = response['data'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> allFeatured = [];

      // Config: type -> display properties
      final configs = <String, Map<String, dynamic>>{
        'marketplace': {
          'icon': Icons.storefront_rounded,
          'color': const Color(0xFF4527A0),
          'label': 'Second Hand',
          'labelTamil': 'பழைய பொருட்கள்',
          'screen': const MarketplaceScreen(),
          'titleKey': 'title',
          'subtitleKey': 'description',
          'imageKey': 'imageUrl',
        },
        'farmer': {
          'icon': Icons.eco_rounded,
          'color': const Color(0xFF33691E),
          'label': 'Farm Products',
          'labelTamil': 'விவசாய பொருட்கள்',
          'screen': const FarmerProductsScreen(),
          'titleKey': 'title',
          'subtitleKey': 'description',
          'imageKey': 'imageUrls',
        },
        'labour': {
          'icon': Icons.construction_rounded,
          'color': const Color(0xFF1565C0),
          'label': 'Labours',
          'labelTamil': 'தொழிலாளர்',
          'screen': const LabourScreen(),
          'titleKey': 'name',
          'subtitleKey': 'category',
          'imageKey': 'imageUrls',
        },
        'jobs': {
          'icon': Icons.work_rounded,
          'color': const Color(0xFF2E7D32),
          'label': 'Jobs',
          'labelTamil': 'வேலை வாய்ப்பு',
          'screen': const JobsScreen(),
          'titleKey': 'jobTitle',
          'subtitleKey': 'companyName',
          'imageKey': 'imageUrls',
        },
        'travel': {
          'icon': Icons.directions_car_rounded,
          'color': const Color(0xFF00897B),
          'label': 'Travels',
          'labelTamil': 'பயணங்கள்',
          'screen': const TravelScreen(),
          'titleKey': 'title',
          'subtitleKey': 'fromLocation',
          'imageKey': 'imageUrls',
        },
        'realEstate': {
          'icon': Icons.home_rounded,
          'color': const Color(0xFFAD1457),
          'label': 'Real Estate',
          'labelTamil': 'ரியல் எஸ்டேட்',
          'screen': const RealEstateScreen(),
          'titleKey': 'title',
          'subtitleKey': 'location',
          'imageKey': 'imageUrls',
        },
        'rental': {
          'icon': Icons.vpn_key_rounded,
          'color': const Color(0xFF6A1B9A),
          'label': 'Rentals',
          'labelTamil': 'வாடகை',
          'screen': const RentalScreen(),
          'titleKey': 'title',
          'subtitleKey': 'location',
          'imageKey': 'imageUrls',
        },
        'parcel': {
          'icon': Icons.local_shipping_rounded,
          'color': const Color(0xFFEF6C00),
          'label': 'Packers & Movers',
          'labelTamil': 'போக்குவரத்து',
          'screen': const ParcelScreen(),
          'titleKey': 'serviceName',
          'subtitleKey': 'fromLocation',
          'imageKey': 'imageUrls',
        },
        'womensCorner': {
          'icon': Icons.auto_awesome_rounded,
          'color': const Color(0xFFE91E63),
          'label': "Women's Corner",
          'labelTamil': 'பெண்கள் பகுதி',
          'screen': const WomensCornerScreen(),
          'titleKey': 'title',
          'subtitleKey': 'description',
          'imageKey': 'imageUrls',
        },
      };

      // Parse shop promotions/offers from API
      final promotions = data['promotions'];
      if (promotions is List && promotions.isNotEmpty) {
        for (final promo in promotions) {
          final promoType = promo['type']?.toString() ?? '';
          final discountValue = promo['discountValue'];
          String discountText = '';
          if (promoType == 'PERCENTAGE' && discountValue != null) {
            discountText = '${double.tryParse(discountValue.toString())?.toStringAsFixed(0) ?? ''}% OFF';
          } else if (promoType == 'FIXED_AMOUNT' && discountValue != null) {
            discountText = '₹${double.tryParse(discountValue.toString())?.toStringAsFixed(0) ?? ''} OFF';
          } else if (promoType == 'FREE_SHIPPING') {
            discountText = 'Free Shipping';
          } else if (promoType == 'BUY_ONE_GET_ONE') {
            discountText = 'Buy 1 Get 1';
          }
          allFeatured.add({
            'type': 'promotion',
            'title': promo['title'] ?? 'Special Offer',
            'subtitle': '${promo['shopName'] ?? 'Shop Offer'} • $discountText',
            'image': (promo['bannerUrl'] ?? promo['imageUrl'] ?? '').toString(),
            'icon': Icons.percent_rounded,
            'color': const Color(0xFFFF6F00),
            'label': promo['shopName'] ?? 'Offer',
            'labelTamil': promo['shopName'] ?? 'சலுகை',
            'screen': null,
            'promoCode': promo['code'],
            'discountValue': promo['discountValue'],
            'promoType': promo['type'],
            'shopId': promo['shopId'],
            'postData': promo,
          });
        }
      }

      // Parse combos from API
      final combos = data['combos'];
      if (combos is List && combos.isNotEmpty) {
        for (final combo in combos) {
          final discount = combo['discountPercentage'];
          final discountText = discount != null ? '${double.tryParse(discount.toString())?.toStringAsFixed(0) ?? ''}% OFF' : '';
          allFeatured.add({
            'type': 'combo',
            'title': combo['name'] ?? 'Combo Offer',
            'subtitle': '${combo['shopName'] ?? 'Shop'} • $discountText',
            'image': (combo['bannerImageUrl'] ?? '').toString(),
            'icon': Icons.local_offer_rounded,
            'color': const Color(0xFFE91E63),
            'label': combo['shopName'] ?? 'Combo',
            'labelTamil': combo['shopName'] ?? 'காம்போ',
            'screen': null,
            'comboPrice': combo['comboPrice'],
            'originalPrice': combo['originalPrice'],
          });
        }
      }

      // Parse paid post categories (only paid posts show in banner)
      for (final entry in configs.entries) {
        final key = entry.key;
        final cfg = entry.value;
        final posts = data[key];
        if (posts is List && posts.isNotEmpty) {
          for (final post in posts) {
            // Get image - handle both single imageUrl and comma-separated imageUrls
            String image = '';
            final imgField = cfg['imageKey'] as String;
            final imgValue = (post[imgField] ?? '').toString();
            if (imgValue.isNotEmpty) {
              image = imgValue.split(',').first.trim();
            }

            // Build subtitle
            String subtitle = '';
            final subtitleKey = cfg['subtitleKey'] as String;
            if (subtitleKey == 'fromLocation' && post['fromLocation'] != null) {
              subtitle = '${post['fromLocation']} → ${post['toLocation'] ?? ''}';
            } else {
              subtitle = (post[subtitleKey] ?? post['description'] ?? '').toString();
            }
            // Format UPPERCASE enum values (e.g. GENERAL_LABOUR → General Labour)
            if (subtitle.contains('_') || subtitle == subtitle.toUpperCase() && subtitle.length > 1) {
              subtitle = subtitle.replaceAll('_', ' ').split(' ').map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w
              ).join(' ');
            }

            allFeatured.add({
              'type': key,
              'title': (post[cfg['titleKey']] ?? cfg['label']).toString(),
              'subtitle': subtitle,
              'image': image,
              'icon': cfg['icon'],
              'color': cfg['color'],
              'label': cfg['label'],
              'labelTamil': cfg['labelTamil'],
              'screen': cfg['screen'],
              'postData': post,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _featuredPosts = allFeatured;
        });
      }
    } catch (e) {
      print('Error loading featured posts: $e');
    }
  }

  Future<void> _loadMarketplacePosts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMarketplace = true;
    });
    try {
      final response = await _marketplaceService.getApprovedPosts(page: 0, size: 6);
      if (mounted) {
        final data = response['data'];
        setState(() {
          _marketplacePosts = data?['content'] ?? [];
          _isLoadingMarketplace = false;
        });
      }
    } catch (e) {
      print('Error loading marketplace posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarketplace = false;
        });
      }
    }
  }

  Future<void> _loadPromos() async {
    try {
      // Location-filtered: shop-tied offers only show when the customer is
      // within that shop's own delivery radius of the selected location.
      final promos = await _promoService.getActivePromotions(
        latitude: _userLatitude,
        longitude: _userLongitude,
      );
      if (mounted) {
        setState(() {
          _promos = promos;
        });
      }
    } catch (e) {
      print('Error loading promos: $e');
    }
  }

  /// How long the slide at [page] holds before the carousel moves on. A promo
  /// video needs long enough to actually get its message across; a still
  /// banner is read at a glance.
  Duration _offerSlideDuration(int page) {
    final promoIndex = page - _combos.length;
    if (promoIndex >= 0 &&
        promoIndex < _promos.length &&
        _promos[promoIndex].hasVideo) {
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 5);
  }

  void _startAutoSlideOffers() {
    // Must match _buildUnifiedOffersCarousel's itemCount. _featuredPosts used
    // to be counted here even though they are not slides in this carousel, so
    // the timer animated past the last real page and the rotation stalled
    // there for good.
    final totalItems = _promos.length + _combos.length;

    _autoSlideTimer?.cancel();
    if (totalItems <= 1) return;

    // A plain Timer (re-armed on every page change) rather than Timer.periodic,
    // so each slide can hold for a different length of time.
    _autoSlideTimer = Timer(_offerSlideDuration(_currentOfferPage), () {
      if (!mounted || !_unifiedOffersController.hasClients) return;

      final nextPage = (_currentOfferPage + 1) % totalItems;
      _unifiedOffersController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // onPageChanged re-arms with the new slide's duration; this is only a
      // safety net so the rotation can't die if that callback never fires.
      _startAutoSlideOffers();
    });
  }

  Future<void> _loadCombos() async {
    try {
      final combos = await CustomerComboService.getAllActiveCombos();
      if (mounted) {
        setState(() {
          _combos = combos;
        });
      }
    } catch (e) {
      print('Error loading combos: $e');
    }
  }

  void _showComboDetails(CustomerCombo combo) {
    // Show combo detail bottom sheet directly
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComboDetailBottomSheet(
        combo: combo,
        onAddToCart: () {
          Navigator.pop(context); // Close bottom sheet
          _addComboToCart(combo);
        },
      ),
    );
  }

  Future<void> _addComboToCart(CustomerCombo combo) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // The combo's discounted bundle price only exists on the CustomerCombo
    // itself - each item still carries its own regular unitPrice. Scale
    // every item's price down proportionally so the cart total matches the
    // combo price the customer was shown, instead of the sum of full prices.
    final actualTotal = combo.items.fold<double>(
        0, (sum, item) => sum + (item.unitPrice * item.quantity));
    final denominator = combo.originalPrice > 0 ? combo.originalPrice : actualTotal;
    final discountRatio =
        denominator > 0 ? (combo.comboPrice / denominator) : 1.0;

    // Add each item in the combo to cart
    for (final item in combo.items) {
      // The id is made combo-specific so this cart row never merges with a
      // standalone add of the same product at full price (which would
      // silently overwrite one price with the other for the whole merged
      // quantity).
      final product = ProductModel(
        id: 'combo_${combo.id}_${item.shopProductId}',
        realProductId: item.shopProductId.toString(),
        name: item.productName,
        nameTamil: item.productNameTamil,
        description: item.productName,
        price: item.unitPrice,
        discountPrice: double.parse(
            (item.unitPrice * discountRatio).toStringAsFixed(2)),
        images: item.imageUrl != null ? [item.imageUrl!] : [],
        unit: item.unit ?? 'piece',
        category: 'Combo Item',
        shopId: combo.shopCode ?? combo.shopId.toString(),
        shopDatabaseId: combo.shopId,
        shopName: combo.shopName ?? '',
        stockQuantity: 999,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cartProvider.addToCart(product, quantity: item.quantity);
    }

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${combo.name} added to cart!'),
          backgroundColor: VillageTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildUnifiedOffersCarousel() {
    final totalItems = _promos.length + _combos.length;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unified carousel
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _unifiedOffersController,
            itemCount: totalItems,
            onPageChanged: (index) {
              setState(() => _currentOfferPage = index);
              // The next slide may be a video (which needs a longer dwell than
              // a still banner), so re-time the rotation from here.
              _startAutoSlideOffers();
            },
            itemBuilder: (context, index) {
              // Order: combos first, then promos (shop-based only)
              if (index < _combos.length) {
                return _buildComboCard(_combos[index]);
              } else {
                // Only the visible slide gets to play: PageView.builder keeps
                // neighbours alive, so without this two or three videos would
                // decode and stream at once behind the card on screen.
                return _buildPromoCard(
                  _promos[index - _combos.length],
                  isActive: _currentOfferPage == index,
                );
              }
            },
          ),
        ),
        // Page indicator dots
        if (totalItems > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalItems > 10 ? 10 : totalItems, (dotIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentOfferPage == dotIndex ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentOfferPage == dotIndex
                        ? VillageTheme.primaryGreen
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _onFeaturedPostTap(Map<String, dynamic> post) {
    final type = post['type'];
    final postData = post['postData'] as Map<String, dynamic>?;

    // Handle promotion tap - show promo code details
    if (type == 'promotion') {
      // postData is the raw promotion JSON from the featured feed; everything
      // in it is optional so the sheet only shows what the admin filled in.
      final raw = postData ?? const <String, dynamic>{};
      double? asDouble(dynamic v) =>
          v == null ? null : double.tryParse(v.toString());
      final endDate = raw['endDate']?.toString();
      _showPromoCodeSheet(
        title: (post['title'] ?? 'Special Offer').toString(),
        subtitle: (post['subtitle'] ?? '').toString(),
        code: (post['promoCode'] ?? '').toString(),
        shopId: post['shopId'] is int ? post['shopId'] as int : null,
        shopName: raw['shopName']?.toString(),
        description: raw['description']?.toString(),
        discountLabel: _promoDiscountLabel(
          raw['type']?.toString(),
          asDouble(raw['discountValue']),
        ),
        imageUrl: (post['image'] ?? '').toString(),
        minimumOrderAmount: asDouble(raw['minimumOrderAmount']),
        maximumDiscountAmount: asDouble(raw['maximumDiscountAmount']),
        validUntil: endDate != null ? DateTime.tryParse(endDate) : null,
        firstTimeOnly: raw['isFirstTimeOnly'] == true,
        terms: raw['termsAndConditions']?.toString(),
      );
      return;
    }

    if (postData != null) {
      switch (type) {
        case 'farmer':
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => FarmerPostDetailScreen(post: postData),
          ));
          return;
        case 'labour':
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => LabourPostDetailScreen(post: postData),
          ));
          return;
        case 'travel':
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TravelPostDetailScreen(post: postData),
          ));
          return;
        case 'marketplace':
          // Merge with full marketplace data (has sellerPhone) if available
          final postId = postData['id'];
          final fullPost = _marketplacePosts.firstWhere(
            (p) => p['id'] == postId,
            orElse: () => null,
          );
          final mergedData = fullPost != null
              ? {...Map<String, dynamic>.from(fullPost), ...postData}
              : postData;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MarketplacePostDetailsSheet(post: mergedData),
          );
          return;
        case 'parcel':
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ParcelPostDetailScreen(post: postData),
          ));
          return;
        case 'realEstate':
          // Transform raw API data to the format PropertyDetailsSheet expects
          final listingType = postData['listingType']?.toString() ?? 'FOR_SALE';
          final propertyType = postData['propertyType']?.toString() ?? 'LAND';
          final transformedData = <String, dynamic>{
            'id': postData['id'],
            'title': postData['title'] ?? '',
            'type': propertyType.replaceAll('_', ' ').split(' ').map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w
            ).join(' '),
            'listingType': listingType == 'FOR_RENT' ? 'For Rent' : 'For Sale',
            'price': (postData['price'] as num?)?.toInt() ?? 0,
            'priceUnit': listingType == 'FOR_RENT' ? 'month' : 'total',
            'area': postData['areaSqft'] != null ? '${postData['areaSqft']} sq.ft' : 'N/A',
            'areaSqft': postData['areaSqft'],
            'bedrooms': postData['bedrooms'],
            'bathrooms': postData['bathrooms'],
            'location': postData['location'] ?? '',
            'description': postData['description'] ?? '',
            'images': (postData['imageUrls'] as String?)?.split(',').where((s) => s.trim().isNotEmpty).toList() ?? [],
            'videoUrl': postData['videoUrl'],
            'postedBy': postData['ownerName'] ?? 'Unknown',
            'phone': postData['ownerPhone'] ?? '',
            'postedDate': postData['createdAt'] != null ? DateTime.tryParse(postData['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
            'viewsCount': postData['viewsCount'] ?? 0,
          };
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PropertyDetailsSheet(listing: transformedData),
          );
          return;
      }
    }

    // Fallback: navigate to category screen
    if (post['screen'] != null) {
      final Widget screen = post['screen'] as Widget;
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  Widget _buildFeaturedPostCard(Map<String, dynamic> post) {
    final Color color = post['color'] as Color;
    final IconData icon = post['icon'] as IconData;
    final String imageUrl = post['image'] ?? '';
    final bool hasImage = imageUrl.isNotEmpty;
    final isTamil = Provider.of<LanguageProvider>(context, listen: false).currentLanguage == 'ta';
    final label = isTamil ? (post['labelTamil'] ?? post['label']) : post['label'];

    final bool isCombo = post['type'] == 'combo';

    return GestureDetector(
      onTap: () => _onFeaturedPostTap(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post['subtitle'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCombo
                                ? '₹${post['comboPrice'] ?? ''} (was ₹${post['originalPrice'] ?? ''})'
                                : (isTamil ? 'மேலும் காண்க →' : 'View More →'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasImage)
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ImageUrlHelper.getFullImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          height: 140,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, size: 50, color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(PromoCode promo, {bool isActive = true}) {
    // An image-only banner has no code or discount behind it, so it is the
    // picture or a quiet placeholder - never the gradient text card, which
    // would announce "₹0 OFF" over an empty code.
    final stillCard = promo.isImageOnly
        ? _buildPromoImageCard(
            promo,
            onError: () => _buildPromoPlaceholderCard(promo),
          )
        : _buildPromoImageOrTextCard(promo);

    // A promo video outranks the still banner: it only ever reaches us after a
    // super admin approved it, so if one is present it is the intended
    // creative. Falls all the way back to the image/text card if it won't play.
    if (promo.hasVideo) {
      return PromoVideoBanner(
        videoUrl: promo.videoUrl!,
        posterUrl: promo.videoThumbnailUrl ?? promo.imageUrl,
        isActive: isActive,
        onTap: () => _onPromoTap(promo),
        fallback: stillCard,
      );
    }

    return stillCard;
  }

  Widget _buildPromoImageOrTextCard(PromoCode promo) {
    // A fully-designed banner image (offer text, code, and call-to-action all
    // baked into the graphic) reads far better than plain text drawn over a
    // flat gradient - when one's uploaded, show it as the whole card instead
    // of squeezing it into a side thumbnail next to a second, redundant copy
    // of the same text. Falls back to the text/gradient card below only if
    // no image was uploaded, or it fails to load.
    return _buildPromoImageCard(
      promo,
      onError: () => _buildPromoCardTextContent(promo),
    );
  }

  /// The promo's uploaded picture as the whole card. [onError] builds what
  /// shows instead when there is no usable image URL or it fails to load.
  Widget _buildPromoImageCard(
    PromoCode promo, {
    required Widget Function() onError,
  }) {
    final imageUrl = promo.imageUrl?.trim();
    final bannerUrl = promo.bannerUrl?.trim();
    final url = (imageUrl != null && imageUrl.isNotEmpty)
        ? imageUrl
        : (bannerUrl != null && bannerUrl.isNotEmpty)
            ? bannerUrl
            : null;
    if (url == null) return onError();

    return GestureDetector(
      onTap: () => _onPromoTap(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // Cached (not plain Image.network) so a banner that already
          // loaded once - very likely, since the same handful of promos
          // show on every visit - paints instantly from disk instead of
          // re-downloading and re-showing a loading state every time.
          child: CachedNetworkImage(
            imageUrl: ImageUrlHelper.getFullImageUrl(url),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => Container(
              color: VillageTheme.primaryGreen.withOpacity(0.08),
              alignment: Alignment.center,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: VillageTheme.primaryGreen.withOpacity(0.5)),
              ),
            ),
            errorWidget: (_, __, ___) => onError(),
          ),
        ),
      ),
    );
  }

  /// Neutral stand-in for an image-only banner whose picture is missing or
  /// would not load. There is no code or discount to fall back on, so it just
  /// shows the title (if any) on a soft tile; still tappable for its link.
  Widget _buildPromoPlaceholderCard(PromoCode promo) {
    final title = promo.title.trim();
    return GestureDetector(
      onTap: () => _onPromoTap(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey[500], size: 28),
            if (title.isNotEmpty) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCardTextContent(PromoCode promo) {
    return GestureDetector(
      onTap: () => _onPromoTap(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VillageTheme.primaryGreen,
              VillageTheme.primaryGreen.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VillageTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                promo.shopName ?? 'PLATFORM OFFER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.local_offer, color: Colors.white, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${promo.discountValue.toStringAsFixed(0)} OFF',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          promo.description ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Code: ${promo.code}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // No uploaded image (or it failed to load, via errorBuilder above) -
                  // a decorative icon instead of leaving this side empty.
                  Expanded(
                    flex: 2,
                    child: Icon(Icons.local_offer_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboCard(CustomerCombo combo) {
    final hasImage = combo.bannerImageUrl != null && combo.bannerImageUrl!.trim().isNotEmpty;

    // Same treatment as the promo card: a fully-designed banner image reads
    // far better as the whole card than squeezed into a side thumbnail next
    // to separately-rendered name/price text.
    if (hasImage) {
      return GestureDetector(
        onTap: () => _showComboDetails(combo),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: ImageUrlHelper.getFullImageUrl(combo.bannerImageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, __) => Container(
                color: VillageTheme.primaryGreen.withOpacity(0.08),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: VillageTheme.primaryGreen.withOpacity(0.5)),
                ),
              ),
              errorWidget: (_, __, ___) => _buildComboCardTextContent(combo),
            ),
          ),
        ),
      );
    }

    return _buildComboCardTextContent(combo);
  }

  Widget _buildComboCardTextContent(CustomerCombo combo) {
    return GestureDetector(
      onTap: () => _showComboDetails(combo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Image with discount badge
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: 130,
                    height: 165,
                    child: combo.bannerImageUrl != null
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(combo.bannerImageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.local_offer, size: 40, color: Colors.grey),
                          ),
                  ),
                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${combo.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      combo.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (combo.nameTamil != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        combo.nameTamil!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${combo.itemCount} items included',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${combo.comboPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${combo.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A banner is an advert for a code - tapping it shows the code, big, with a
  /// copy button. It used to jump straight to the shop (or, for a platform
  /// promo, flash a two-second toast the customer could not copy from).
  void _onPromoTap(PromoCode promo) {
    // A picture-only banner has nothing to redeem: it either opens its link
    // or is just an announcement. Never raise the code sheet with an empty code.
    if (promo.isImageOnly) {
      if (promo.hasLink) _openPromoLink(promo.linkUrl!.trim());
      return;
    }

    final shopName = promo.shopName?.trim();
    _showPromoCodeSheet(
      title: promo.title,
      subtitle: '',
      code: promo.code,
      shopId: promo.shopId,
      shopName: (shopName == null || shopName.isEmpty) ? null : shopName,
      description: promo.description,
      discountLabel: promo.formattedDiscount,
      // Still image first; a video promo falls back to its poster frame. The
      // sheet never autoplays the clip - the carousel already did that.
      imageUrl: promo.imageUrl ?? promo.bannerUrl ?? promo.videoThumbnailUrl,
      minimumOrderAmount: promo.minimumOrderAmount,
      maximumDiscountAmount: promo.maximumDiscountAmount,
      validUntil: promo.endDate,
      firstTimeOnly: promo.isFirstTimeOnly == true,
      terms: promo.termsAndConditions,
    );
  }

  /// Opens an image banner's link in the browser (or whatever app claims the
  /// scheme). A bare "example.com" is treated as https; junk is ignored.
  Future<void> _openPromoLink(String link) async {
    final withScheme = link.contains('://') ? link : 'https://$link';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return;
    final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
    if (isWeb && uri.host.isEmpty) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link')),
        );
      }
    } catch (e) {
      print('Error opening promo link $link: $e');
    }
  }

  /// "20% OFF" / "\u20b950 OFF" / "FREE DELIVERY" from a raw promo type + value.
  /// Mirrors [PromoCode.formattedDiscount] for feed entries that arrive as
  /// plain JSON rather than a parsed [PromoCode].
  static String? _promoDiscountLabel(String? type, double? value) {
    switch (type) {
      case 'PERCENTAGE':
        return value == null ? null : '${value.toStringAsFixed(0)}% OFF';
      case 'FIXED_AMOUNT':
        return value == null ? null : '\u20b9${value.toStringAsFixed(0)} OFF';
      case 'FREE_SHIPPING':
        return 'FREE DELIVERY';
      case 'BUY_ONE_GET_ONE':
        return 'BUY 1 GET 1';
      default:
        return null;
    }
  }

  /// Bottom sheet with the promo code and a copy button. Shared by the
  /// SPECIAL OFFERS carousel and the launch banner so both behave the same.
  /// [subtitle] is kept for callers that only have a one-line summary; it is
  /// used as the shop line when [shopName] is absent. Every rich field is
  /// optional - [PromoCodeSheet] hides whatever is null.
  void _showPromoCodeSheet({
    required String title,
    required String subtitle,
    required String code,
    int? shopId,
    String? shopName,
    String? description,
    String? discountLabel,
    String? imageUrl,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    DateTime? validUntil,
    bool firstTimeOnly = false,
    String? terms,
  }) {
    final fallbackShopLine = subtitle.trim().isEmpty ? null : subtitle.trim();
    PromoCodeSheet.show(
      context,
      title: title,
      shopName: shopName ?? fallbackShopLine,
      description: description,
      discountLabel: discountLabel,
      code: code,
      imageUrl: imageUrl,
      minimumOrderAmount: minimumOrderAmount,
      maximumDiscountAmount: maximumDiscountAmount,
      validUntil: validUntil,
      firstTimeOnly: firstTimeOnly,
      terms: terms,
      onVisitShop: shopId == null
          ? null
          : () {
              // The sheet has already popped itself; push with the dashboard's
              // own context so the route lands in the right navigator.
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopDetailsScreen(shopId: shopId, shop: null),
                ),
              );
            },
    );
  }

  Future<void> _loadFeaturedShops() async {
    if (!mounted) return;
    setState(() => _isLoadingShops = true);

    try {
      // A location the user explicitly picked (map / saved address) wins over GPS
      double? lat = LocationService.isManualLocation ? LocationService.cachedLatitude : _userLatitude;
      double? lng = LocationService.isManualLocation ? LocationService.cachedLongitude : _userLongitude;

      // If location not yet available, try to get it now
      if (lat == null || lng == null) {
        try {
          final position = await LocationService.instance.getCurrentPosition();
          if (position != null && position.latitude != null && position.longitude != null) {
            lat = position.latitude;
            lng = position.longitude;
            _userLatitude = lat;
            _userLongitude = lng;
          }
        } catch (e) {
          print('Location fetch failed in _loadFeaturedShops: $e');
        }
      }

      print('🏪 Loading shops - lat: $lat, lng: $lng');

      if (lat != null && lng != null) {
        // Use location-based nearby shops
        final response = await _shopApi.getNearbyShops(
          latitude: lat,
          longitude: lng,
          radius: 10.0,
        );
        print('🏪 Nearby shops response: success=${response['success']}, statusCode=${response['statusCode']}');
        if (mounted && response['success'] == true && response['data'] != null) {
          final shops = response['data']['shops'] ?? [];
          print('🏪 Found ${shops.length} nearby shops within 10km');
          setState(() {
            _featuredShops = shops;
          });
        } else {
          print('🏪 Nearby shops API failed, response: $response');
          // Don't fall back to all shops - show empty if no nearby shops
          if (mounted) {
            setState(() {
              _featuredShops = [];
            });
          }
        }
      } else {
        print('🏪 No location available, loading all active shops');
        // Fallback: no location available, show all active shops
        final response = await _shopApi.getActiveShops(page: 0, size: 10);
        if (mounted && response['success'] == true && response['data'] != null) {
          setState(() {
            _featuredShops = response['data']['content'] ?? [];
          });
        }
      }
    } catch (e) {
      print('🏪 Error loading shops: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load shops', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingShops = false);
      }
    }
  }
  
  Future<void> _reorderFromDashboard(dynamic orderId) async {
    final id = orderId is int ? orderId : int.tryParse(orderId.toString());
    if (id == null) {
      Helpers.showSnackBar(context, 'Failed to reorder', isError: true);
      return;
    }

    // Guard against double-tap: without this, rapid repeated taps stack up
    // multiple loading dialogs, and each one's Navigator.pop() at the end can
    // pop past the dialogs into the screen underneath once they're all done.
    if (_isReordering) return;
    _isReordering = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orderResponse = await _orderApi.getOrderById(id);
      final orderData = (orderResponse['data'] ?? orderResponse) as Map<String, dynamic>;
      final rawItems = (orderData['items'] ?? orderData['orderItems'] ?? []) as List<dynamic>;

      if (rawItems.isEmpty) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        Helpers.showSnackBar(context, 'This order has no items to reorder', isError: true);
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final shopApiService = ShopApiService();

      final firstShopId = (rawItems.first['shopId'] ?? '').toString();
      if (cartProvider.items.isNotEmpty &&
          cartProvider.items.first.product.shopId != firstShopId) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading before asking
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace Cart?'),
            content: const Text(
                'Your cart has items from a different shop. Reordering will clear it first. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
            ],
          ),
        );
        if (confirmed != true) return;
        cartProvider.clearCart();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }
      }

      int added = 0;
      int unavailable = 0;

      final fetched = await Future.wait(rawItems.map((item) async {
        try {
          final productId = int.tryParse((item['productId'] ?? item['shopProductId'] ?? '').toString());
          final shopId = int.tryParse((item['shopId'] ?? '').toString());
          final quantity = (item['quantity'] ?? 1) as int;
          if (productId == null || shopId == null) return null;
          final response = await shopApiService
              .getCustomerProductDetails(shopId, productId)
              .timeout(const Duration(seconds: 10));
          final data = (response['data'] ?? response) as Map<String, dynamic>;
          // This endpoint's response has no "shopDatabaseId" key (only "shopId", already
          // numeric here), so ProductModel.fromJson leaves shopDatabaseId null - checkout
          // requires it and rejects the item with "Invalid shop information" otherwise.
          final product = ProductModel.fromJson(data).copyWith(shopDatabaseId: shopId);
          return MapEntry(product, quantity);
        } catch (e) {
          return null;
        }
      }));

      for (final entry in fetched) {
        if (entry == null) {
          unavailable++;
          continue;
        }
        final ok = await cartProvider.addToCart(entry.key, quantity: entry.value, clearCartConfirmed: true);
        if (ok) {
          added++;
        } else {
          unavailable++;
        }
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

      if (added == 0) {
        Helpers.showSnackBar(context, 'None of these items are available right now', isError: true);
        return;
      }

      Helpers.showSnackBar(
        context,
        unavailable > 0 ? 'Added $added item(s) to cart, $unavailable unavailable' : 'Added $added item(s) to cart',
      );

      if (mounted) {
        context.go('/customer/cart'); // switch the bottom nav tab, not stack a new page
      }
    } catch (e) {
      // showDialog defaults to the root navigator; a plain Navigator.pop(context)
      // resolves to the nearest (nested/shell) navigator instead and, if this
      // page is the only one on that stack, pops the page itself and crashes
      // go_router ("popped the last page off of the stack"). Must match roots.
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      Helpers.showSnackBar(context, 'Failed to reorder', isError: true);
    } finally {
      _isReordering = false;
    }
  }

  Future<void> _loadRecentOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingOrders = true);

    try {
      // Check if user is authenticated before loading orders
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        // Guest user - skip loading orders
        if (mounted) {
          setState(() {
            _recentOrders = [];
            _isLoadingOrders = false;
          });
        }
        return;
      }

      // User is logged in - load orders
      final response = await _orderApi.getCustomerOrders(page: 0, size: 3);
      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _recentOrders = response['data']['content'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading recent orders: $e');
        // Don't show error for orders as user might not be logged in
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }
  
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressTime = now;
      Helpers.showSnackBar(
        context,
        'Press back again to exit',
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 CustomerDashboard build called');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ShowCaseWidget(
      enableAutoScroll: true,
      disableMovingAnimation: true,
      builder: (showcaseCtx) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startTourIfNeeded(showcaseCtx));
        return _buildDashboardContent(context, showcaseCtx, isDarkMode);
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, BuildContext showcaseCtx, bool isDarkMode) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop && await _onWillPop()) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF171E19) : const Color(0xFFFFFFFF),
        body: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildCurvedHeader(),
            Consumer<FeatureConfigProvider>(builder: (context, featureConfig, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (featureConfig.isVisible('section_special_offers')) ...[
                    _buildUnifiedOffersCarousel(),
                    const SizedBox(height: 4),
                  ],
                  _buildServiceCategories(),
                  const SizedBox(height: 24),
                  _buildNearbyOnHome(),
                  if (featureConfig.isVisible('section_featured_shops') && (_isLoadingShops || _featuredShops.isNotEmpty)) ...[
                    const SizedBox(height: 8), _buildFeaturedShops(),
                  ],
                  if (featureConfig.isVisible('section_recent_orders')) ...[
                    const SizedBox(height: 24), _buildRecentOrders(),
                  ],
                ]),
              );
            }),
          ]),
        ),
      ),
    );
  }

  // Automatic version check on dashboard startup
  Future<void> _checkVersionOnStartup() async {
    try {
      print('🔄 Starting version check...');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('📱 Current app version: $currentVersion');

      final versionInfo = await VersionService.checkVersion(currentVersion);
      print('✅ Version check response: $versionInfo');

      if (!mounted) {
        print('⚠️ Widget not mounted, cannot show dialog');
        return;
      }

      if (versionInfo != null) {
        print('ℹ️ Update available! Showing dialog...');
        // Show update dialog only if update is available
        final isMandatory = versionInfo['isMandatory'] ?? false;

        // Add small delay to ensure context is ready
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) {
          print('⚠️ Widget unmounted during delay');
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: !isMandatory, // Prevent dismissing mandatory updates by tapping outside
          builder: (context) => UpdateDialog(
            currentVersion: currentVersion,
            newVersion: versionInfo['currentVersion'] ?? 'Unknown',
            releaseNotes: versionInfo['releaseNotes'] ?? '',
            updateUrl: versionInfo['updateUrl'] ?? '',
            isMandatory: isMandatory,
            updateRequired: versionInfo['updateRequired'] ?? false,
          ),
        );
        print('✅ Dialog shown successfully');
      } else {
        print('ℹ️ No update needed or check skipped');
      }
      // If versionInfo is null, no update needed - do nothing (silent success)
    } catch (e) {
      // Silent fail for version check - don't bother user with errors
      print('❌ Version check failed: $e');
    }
  }

  Widget _buildCurvedHeader() {
    final lang = Provider.of<LanguageProvider>(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF3D9140)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(children: [
        // Logo badge: white disc with the brand house mark, like the mockup
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.home_rounded, color: Color(0xFF2E7D32), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(lang.appName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5))),
        // Outlined language pill with a dropdown caret
        OutlinedButton(
          onPressed: () => lang.toggleLanguage(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(lang.showTamil ? 'English' : 'தமிழ்', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ]),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: lang.getText('Notifications', 'அறிவிப்புகள்'),
          style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, fixedSize: const Size(44, 44)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ]),
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _showLocationPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: VillageTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELIVER TO',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  static const _featureCacheKey = 'cached_feature_config';

  Future<void> _loadFeatureConfig() async {
    final lat = _userLatitude ?? 12.4966;
    final lng = _userLongitude ?? 78.5729;

    // Show cached features instantly if available — no shimmer needed
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_featureCacheKey);
    if (cached != null) {
      try {
        final List<dynamic> raw = json.decode(cached);
        final cachedFeatures = raw
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (cachedFeatures.isNotEmpty && mounted) {
          for (final f in cachedFeatures) {
            _featureTourKeys.putIfAbsent(f['featureName']?.toString() ?? '', () => GlobalKey());
          }
          setState(() {
            _dynamicFeatures = cachedFeatures;
            _isLoadingFeatures = false;
          });
        }
      } catch (_) {}
    } else {
      setState(() => _isLoadingFeatures = true);
    }

    // Fetch fresh from API in background — update if response arrives
    try {
      final provider = Provider.of<FeatureConfigProvider>(context, listen: false);
      await provider.load(lat, lng).timeout(const Duration(seconds: 8));

      final features = provider.serviceFeatures;
      if (features.isNotEmpty) {
        // Save to cache for next app open
        await prefs.setString(_featureCacheKey, json.encode(features));
        if (mounted) {
          for (final f in features) {
            _featureTourKeys.putIfAbsent(f['featureName']?.toString() ?? '', () => GlobalKey());
          }
          setState(() {
            _dynamicFeatures = features;
            _isLoadingFeatures = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFeatures = false);
      }
    } catch (e) {
      print('🔴 Feature config API FAILED: $e');
      if (mounted) setState(() => _isLoadingFeatures = false);
    }
  }

  // Map icon string from backend to Flutter IconData
  IconData _mapIcon(String? iconName, {String? route}) {
    const iconMap = <String, IconData>{
      'shopping_basket_rounded': Icons.shopping_basket_rounded,
      'restaurant_rounded': Icons.restaurant_rounded,
      'storefront_rounded': Icons.storefront_rounded,
      'eco_rounded': Icons.eco_rounded,
      'agriculture_rounded': Icons.agriculture_rounded,
      'construction_rounded': Icons.construction_rounded,
      'engineering_rounded': Icons.engineering_rounded,
      'directions_bus_rounded': Icons.directions_bus_rounded,
      'local_shipping_rounded': Icons.local_shipping_rounded,
      'directions_car_rounded': Icons.directions_car_rounded,
      'home_work_rounded': Icons.home_work_rounded,
      'vpn_key_rounded': Icons.vpn_key_rounded,
      'account_balance_rounded': Icons.account_balance_rounded,
      'work_rounded': Icons.work_rounded,
      'spa_rounded': Icons.spa_rounded,
      'recycling_rounded': Icons.recycling_rounded,
      'shopping_bag_rounded': Icons.shopping_bag_rounded,
      'fastfood_rounded': Icons.fastfood_rounded,
    };
    return iconMap[iconName] ?? _iconForRoute(route);
  }

  // Fallback when backend sends no/unknown icon name — pick by feature route
  IconData _iconForRoute(String? route) {
    if (route == null || route.isEmpty) return Icons.grid_view_rounded;
    if (route.contains('grocery')) return Icons.shopping_basket_rounded;
    if (route.contains('food')) return Icons.restaurant_rounded;
    if (route.contains('marketplace')) return Icons.recycling_rounded;
    if (route.contains('farmer')) return Icons.agriculture_rounded;
    if (route.contains('labour')) return Icons.engineering_rounded;
    if (route.contains('travel') || route.contains('bus')) return Icons.directions_bus_rounded;
    if (route.contains('parcel')) return Icons.local_shipping_rounded;
    if (route.contains('real-estate')) return Icons.home_work_rounded;
    if (route.contains('rental')) return Icons.vpn_key_rounded;
    if (route.contains('women')) return Icons.spa_rounded;
    if (route.contains('village') || route.contains('panchayat')) return Icons.account_balance_rounded;
    if (route.contains('job')) return Icons.work_rounded;
    return Icons.grid_view_rounded;
  }

  // Parse hex color string to Color
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF2196F3);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  /// Checks service area before any navigation — awaits pending check if not done yet
  Future<void> _guardedNavigate(VoidCallback navigate) async {
    // If check is still running, wait for it (max 5s)
    if (_serviceAreaCheckFuture != null) {
      await _serviceAreaCheckFuture!.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    }

    if (!mounted) return;

    if (ServiceAreaService.isCurrentlyBlocked) {
      final result = ServiceAreaService.lastResult;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ServiceAreaDialog(
          message: result?['message'] ?? 'Service is not available in your area.',
          radiusKm: (result?['radiusKm'] as num?)?.toDouble(),
          centerLat: (result?['centerLat'] as num?)?.toDouble(),
          centerLng: (result?['centerLng'] as num?)?.toDouble(),
          userLat: _userLatitude,
          userLng: _userLongitude,
        ),
      );
      return;
    }
    navigate();
  }

  // Navigate based on route from backend — checks service area on every tap
  void _navigateToFeature(String? route) {
    if (route == null || route.isEmpty) return;
    _dismissTour();
    _guardedNavigate(() => _doNavigateToFeature(route));
  }

  void _doNavigateToFeature(String route) {

    // Map backend routes to actual navigation
    if (route.contains('category=grocery')) {
      context.push('/customer/shops?category=grocery&categoryTitle=Grocery');
    } else if (route.contains('category=food')) {
      context.push('/customer/shops?category=food&categoryTitle=Food');
    } else if (route.contains('marketplace')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
    } else if (route.contains('farmer-products')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmerProductsScreen()));
    } else if (route.contains('labours')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LabourScreen()));
    } else if (route.contains('travels')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const TravelScreen()));
    } else if (route.contains('parcels')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ParcelScreen()));
    } else if (route.contains('real-estate')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RealEstateScreen()));
    } else if (route.contains('rentals')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalScreen()));
    } else if (route.contains('transport')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const WhereIsBusScreen()));
    } else if (route.contains('bus-timing')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const TravelScreen()));
    } else if (route.contains('womens-corner')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const WomensCornerScreen()));
    } else if (route.contains('jobs')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const JobsScreen()));
    } else if (route.contains('local-shops')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalShopsScreen()));
    } else if (route.contains('village') || route.contains('panchayat')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PanchayatScreen()));
    }
  }

  Widget _buildAiOrderBanner() {
    return GestureDetector(
      onTap: () {
        // Go directly to Smart Order screen (global mode — searches all shops)
        context.push('/customer/smart-order');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Order / AI ஆர்டர்',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Speak, snap a photo, or type your order!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoadingFeatures) {
          return _buildCategoryLoadingShimmer();
        }
        if (_dynamicFeatures.isNotEmpty) {
          return _buildDynamicCategories(languageProvider);
        }
        // API returned empty — show retry
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  languageProvider.getText('Could not load services', 'சேவைகளை ஏற்ற முடியவில்லை'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadFeatureConfig,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(languageProvider.getText('Retry', 'மீண்டும் முயற்சி')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillageTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryLoadingShimmer() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Same fixed tile height as the real tiles — width-independent
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: _serviceTileHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: List.generate(4, (index) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 70, height: 14, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 56, height: 10, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  // Short tour description per feature route (en, ta)
  static const Map<String, List<String>> _tourDescriptions = {
    'grocery':        ['Order grocery & daily essentials from nearby shops.',        'அருகிலுள்ள கடைகளில் மளிகை & தினசரி பொருட்கள் ஆர்டர் செய்யுங்கள்.'],
    'food':           ['Order hot food from restaurants & home kitchens.',            'உணவகங்கள் & வீட்டு சமையல்காரர்களிடம் சாப்பாடு ஆர்டர் செய்யுங்கள்.'],
    'marketplace':    ['Buy & sell used / second-hand items in your local area.',       'உங்கள் பகுதியில் பழைய பொருட்களை வாங்கவும் விற்கவும்.'],
    'farmer':         ['Buy fresh farm produce directly from local farmers.',         'விவசாயிகளிடம் நேரடியாக கொள்முதல் செய்யுங்கள்.'],
    'labours':        ['Find skilled workers for any job in your village.',           'உங்கள் கிராமத்தில் திறமையான தொழிலாளர்களை கண்டறியுங்கள்.'],
    'travels':        ['Book cars & buses for local or outstation trips.',            'உள்ளூர் / வெளியூர் பயணங்களுக்கு வாகனம் பதிவு செய்யுங்கள்.'],
    'parcels':        ['Send parcels & find packers and movers near you.',            'பொருட்கள் அனுப்புங்கள் & பேக்கர்ஸ் மூவர்ஸ் கண்டறியுங்கள்.'],
    'real-estate':    ['Buy, sell or rent land, houses & properties.',                'நிலம், வீடு & சொத்துக்களை வாங்கவும் / விற்கவும் / வாடகை விடவும்.'],
    'rentals':        ['Rent shops, houses, vehicles & equipment.',                   'கடை, வீடு, வாகனம் & உபகரணங்களை வாடகைக்கு எடுங்கள்.'],
    'womens-corner':  ['Beauty, fashion & products from women entrepreneurs.',        'பெண் தொழில்முனைவோரிடம் அழகு & ஆடை பொருட்கள்.'],
    'village':        ['Panchayat details & local government information.',           'பஞ்சாயத்து விவரங்கள் & உள்ளாட்சி தகவல்கள்.'],
    'jobs':           ['Find jobs near you — call or WhatsApp employers directly.',   'அருகிலுள்ள வேலை வாய்ப்புகளை தேடி நேரடியாக தொடர்பு கொள்ளுங்கள்.'],
  };

  String _getTourDesc(String? route, bool isTamil) {
    if (route == null) return '';
    final key = _tourDescriptions.keys.firstWhere(
      (k) => route.contains(k),
      orElse: () => '',
    );
    if (key.isEmpty) return '';
    return isTamil ? _tourDescriptions[key]![1] : _tourDescriptions[key]![0];
  }

  // Service tile: fixed height so a 2-line title + 2-line subtitle (Tamil
  // glyphs are tall) can never overflow on a narrow screen.
  static const double _serviceTileHeight = 108;

  // Short one-liner shown under each service title (en, ta)
  static const Map<String, List<String>> _serviceSubtitles = {
    'grocery':        ['Daily needs delivered to your home',  'தினசரி தேவைகள் வீட்டுக்கே'],
    'food':           ['Hot food from local kitchens',        'உள்ளூர் சமையலில் சூடான உணவு'],
    'marketplace':    ['Buy & sell used items',               'பழைய பொருட்கள் வாங்க & விற்க'],
    'farmer':         ['Fresh from our farmers',              'விவசாயிகளிடம் இருந்து நேரடியாக'],
    'labours':        ['Find skilled local workers',          'திறமையான தொழிலாளர்கள்'],
    'travels':        ['Buses, cars, vans and more',          'பேருந்து, கார், வேன் மற்றும் பல'],
    'parcels':        ['Safe & reliable moving services',     'பாதுகாப்பான பேக்கிங் & மூவிங்'],
    'real-estate':    ['Buy, Sell or Rent properties',        'சொத்து வாங்க, விற்க, வாடகை'],
    'rentals':        ['Find or list rental items',           'வாடகைக்கு எடுக்க / விட'],
    'womens-corner':  ["Women products & services",           'பெண்கள் பொருட்கள் & சேவைகள்'],
    'village':        ['Panchayat & local info',              'பஞ்சாயத்து & உள்ளூர் தகவல்'],
    'panchayat':      ['Panchayat & local info',              'பஞ்சாயத்து & உள்ளூர் தகவல்'],
    'jobs':           ['Find jobs near you',                  'அருகில் வேலை வாய்ப்புகள்'],
    'bus':            ['Live bus timings & tracking',         'பேருந்து நேரம் & கண்காணிப்பு'],
    'transport':      ['Track your bus live',                 'பேருந்தை நேரலையில் கண்காணிக்க'],
    'local-shops':    ['Shops around your village',           'உங்கள் ஊர் கடைகள்'],
    'shops':          ['Shops around your village',           'உங்கள் ஊர் கடைகள்'],
  };

  // Bundled service pictures (cropped from the home mockup), keyed by a
  // route fragment. Preferred over the backend imageUrl so the home grid
  // always shows the same artwork.
  static const Map<String, String> _serviceAssets = {
    'grocery':       'assets/images/services/grocery.png',
    'labours':       'assets/images/services/labours.png',
    'farmer':        'assets/images/services/farmer.png',
    'womens-corner': 'assets/images/services/womens_corner.png',
    'real-estate':   'assets/images/services/real_estate.png',
    'parcels':       'assets/images/services/parcels.png',
    'travels':       'assets/images/services/travels.png',
    'rentals':       'assets/images/services/rentals.png',
  };

  String? _getServiceAsset(String? route) {
    if (route == null) return null;
    for (final entry in _serviceAssets.entries) {
      if (route.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String _getServiceSubtitle(String? route, bool isTamil) {
    if (route == null) return '';
    final key = _serviceSubtitles.keys.firstWhere(
      (k) => route.contains(k),
      orElse: () => '',
    );
    if (key.isEmpty) return '';
    return isTamil ? _serviceSubtitles[key]![1] : _serviceSubtitles[key]![0];
  }

  Widget _buildDynamicCategories(LanguageProvider languageProvider) {
    final isTamil = languageProvider.currentLanguage == 'ta';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Fixed tile height (icon badge + 2-line label) instead of an
          // aspect ratio, so narrow screens can never overflow
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: _serviceTileHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: _dynamicFeatures.map((feature) {
            final featureName = feature['featureName']?.toString() ?? '';
            final title = isTamil && feature['displayNameTamil'] != null && feature['displayNameTamil'].toString().isNotEmpty
                ? feature['displayNameTamil']
                : feature['displayName'] ?? '';
            final tourKey = _featureTourKeys[featureName];
            final desc = _getTourDesc(feature['route']?.toString(), isTamil);
            final tile = _buildModernCategoryTile(
              icon: _mapIcon(feature['icon'], route: feature['route']?.toString()),
              title: title,
              subtitle: _getServiceSubtitle(feature['route']?.toString(), isTamil),
              color: _parseColor(feature['color']),
              imageUrl: feature['imageUrl']?.toString(),
              assetPath: _getServiceAsset(feature['route']?.toString()),
              onTap: () => _navigateToFeature(feature['route']),
            );
            if (tourKey == null || desc.isEmpty) return tile;
            final tooltipWidth = (MediaQuery.sizeOf(context).width - 40)
                .clamp(0.0, 320.0).toDouble();
            return Showcase.withWidget(
              key: tourKey,
              height: null,
              width: tooltipWidth,
              onBarrierClick: _dismissTour,
              container: Container(
                width: tooltipWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title, style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _parseColor(feature['color']),
                            )),
                          ),
                          IconButton(
                            tooltip: languageProvider.getText('Dismiss tour', 'வழிகாட்டியை மூடு'),
                            onPressed: _dismissTour,
                            icon: const Icon(Icons.close_rounded, color: Colors.black54),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(desc, style: const TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.black87,
                        )),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _dismissTour,
                            child: Text(languageProvider.getText('Skip tour', 'தவிர்')),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_showcaseCtx != null) {
                                ShowCaseWidget.of(_showcaseCtx!).next();
                              }
                            },
                            child: Text(languageProvider.getText(
                              tourKey == _featureTourKeys.values.last ? 'Done' : 'Next',
                              tourKey == _featureTourKeys.values.last ? 'முடிந்தது' : 'அடுத்து',
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              child: tile,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNearbyOnHome() {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        final shops = _featuredShops.where((s) => s['isActive'] != false).toList();

        // Nothing to browse yet - skip the whole section (header included)
        // instead of showing a "Browse local shops" placeholder prompt.
        if (!_isLoadingShops && shops.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang.getText('Nearby shops', 'அருகிலுள்ள கடைகள்'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/customer/shops'),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      lang.getText('See all', 'அனைத்தும்'),
                      style: const TextStyle(
                        color: VillageTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: VillageTheme.primaryGreen),
                  ]),
                ),
              ],
            ),
            if (_isLoadingShops)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: LoadingWidget()),
              )
            else
              SizedBox(
                height: 188,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: shops.length,
                  itemBuilder: (context, index) => _buildShopCard(shops[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildModernCategoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? imageUrl,
    String? assetPath,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Pastel card tinted from the service colour (soft wash on light theme,
    // deeper wash on dark), a stronger tint for the picture disc and the
    // chevron disc so they lift off the card - matches the home mockup.
    final cardTint = Color.lerp(color, dark ? const Color(0xFF202923) : Colors.white, dark ? 0.82 : 0.90)!;
    final discTint = Color.lerp(color, dark ? const Color(0xFF202923) : Colors.white, dark ? 0.65 : 0.78)!;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return DepthPress(child: Material(
      color: cardTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: dark ? Colors.white10 : color.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          child: Row(children: [
            // Picture disc (service image from the backend, icon fallback)
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: discTint, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: assetPath != null
                  ? Image.asset(assetPath, fit: BoxFit.cover)
                  : hasImage
                      ? Image.network(
                          ImageUrlHelper.getFullImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 26),
                        )
                      : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.15, fontWeight: FontWeight.w700, color: dark ? Colors.white : const Color(0xFF1F2A24))),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.2, color: dark ? Colors.white60 : const Color(0xFF5F6B64))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Chevron disc
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: discTint, shape: BoxShape.circle),
              child: Icon(Icons.chevron_right_rounded, size: 20, color: dark ? Colors.white : color),
            ),
          ]),
        ),
      ),
    ));
  }

  Widget _buildBuySellCard(String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VillageTheme.primaryGreen,
              VillageTheme.primaryGreen.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: VillageTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Post & Browse',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, String nameEn, String imageUrl) {
    return GestureDetector(
      onTap: () {
        final category = Uri.encodeComponent(nameEn.toLowerCase());
        final title = Uri.encodeComponent(nameEn);
        context.push('/customer/shops?category=$category&categoryTitle=$title');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Buy & Sell',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to sell items'), backgroundColor: Colors.orange),
                      );
                      context.push('/login');
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()))
                        .then((_) => _loadMarketplacePosts());
                  },
                  child: const Text(
                    'Post',
                    style: TextStyle(color: VillageTheme.warningOrange, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: VillageTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: _isLoadingMarketplace
              ? const Center(child: LoadingWidget())
              : _marketplacePosts.isEmpty
                  ? Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('No items for sale yet', style: TextStyle(color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              const Text('Tap to browse or sell', style: TextStyle(color: VillageTheme.primaryGreen, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _marketplacePosts.length,
                      itemBuilder: (context, index) {
                        return _buildMarketplaceCard(_marketplacePosts[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMarketplaceCard(Map<String, dynamic> post) {
    final isSold = post['status'] == 'SOLD';
    final imageUrl = post['imageUrl'];
    final price = post['price'];

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                          height: 110,
                          width: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 110,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 110,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 110,
                          width: 160,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                        ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (price != null)
                        Text(
                          '\u20B9${double.tryParse(price.toString())?.toStringAsFixed(0) ?? price}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryGreen,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${post['sellerName']?.split(' ').first ?? ''}${post['location'] != null ? ' - ${post['location']}' : ''}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post['sellerPhone'] != null && !isSold)
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse('tel:${post['sellerPhone']}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.call, size: 16, color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // SOLD badge
            if (isSold)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SOLD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedShops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Shops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/customer/shops');
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: VillageTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _isLoadingShops
              ? const Center(child: LoadingWidget())
              : _featuredShops.isEmpty
                  ? const Center(
                      child: Text(
                        'No shops available',
                        style: TextStyle(color: VillageTheme.secondaryText),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredShops.length,
                      itemBuilder: (context, index) {
                        final shop = _featuredShops[index];
                        return _buildShopCard(shop);
                      },
                    ),
        ),
      ],
    );
  }

  /// Extract logo URL from shop images
  String? _getShopLogoUrl(Map<String, dynamic>? shop) {
    if (shop == null) return null;
    final images = shop['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return null;

    // Find LOGO type first, then primary, then first image
    var logo = images.firstWhere(
      (img) => img['imageType'] == 'LOGO',
      orElse: () => images.firstWhere(
        (img) => img['isPrimary'] == true,
        orElse: () => images.isNotEmpty ? images.first : null,
      ),
    );

    return logo?['imageUrl'];
  }

  Widget _buildShopCard(Map<String, dynamic>? shop) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final shopName = shop != null ? languageProvider.getShopName(shop) : 'Shop';
    final businessType = shop?['businessType'] ?? 'Store';
    final rating = shop?['averageRating']?.toString() ?? '4.0';
    final deliveryTime = shop?['estimatedDeliveryTime']?.toString() ?? '30';
    final isActive = shop?['isActive'] ?? true;
    final logoUrl = _getShopLogoUrl(shop);

    if (!isActive) return const SizedBox();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailsScreen(
              shopId: shop?['id'] ?? 1,
              shop: shop,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        // Flat soft-grey card matching the app-wide design system.
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(logoUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 12,
                          color: VillageTheme.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$deliveryTime min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VillageTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessType,
                    style: const TextStyle(
                      fontSize: 10,
                      color: VillageTheme.hintText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/customer/orders');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: VillageTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingOrders
            ? const Center(child: LoadingWidget())
            : _recentOrders.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: VillageTheme.primaryGreen.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Orders Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your order history will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: VillageTheme.hintText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/customer/shops');
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                          label: const Text('Start Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VillageTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _recentOrders.take(3).map((order) {
                      return _buildOrderCard(order);
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildPromotionalBanners() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: VillageTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VillageTheme.primaryGreen,
                      VillageTheme.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '50% OFF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'On your first grocery order',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Apply offer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: VillageTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Order Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber = order['orderNumber'] ?? 'N/A';
    final totalAmount = order['totalAmount']?.toString() ?? '0';
    final status = order['status'] ?? 'PENDING';
    final itemCount = order['itemCount'] ?? order['numberOfItems'] ?? order['items']?.length ?? 1;
    final createdAt = order['createdAt'] ?? '';

    Color statusColor = VillageTheme.primaryGreen;
    String statusText = status;

    switch (status.toUpperCase()) {
      case 'DELIVERED':
        statusColor = VillageTheme.successGreen;
        statusText = 'Delivered';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'CONFIRMED':
        statusColor = VillageTheme.primaryGreen;
        statusText = 'Confirmed';
        break;
      default:
        statusText = status;
    }

    return GestureDetector(
      onTap: () {
        context.go('/customer/orders');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.primaryText,
                    ),
                  ),
                  Text(
                    '$itemCount items • ₹$totalAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: VillageTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (status.toUpperCase() == 'DELIVERED')
                  TextButton(
                    onPressed: () => _reorderFromDashboard(order['id']),
                    child: const Text(
                      'Reorder',
                      style: TextStyle(
                        color: VillageTheme.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsAppChannel(BuildContext context) async {
    const whatsappChannelUrl = 'https://www.whatsapp.com/channel/0029VbB1iXbAYlULfRaQlc0z';
    final whatsappUrl = Uri.parse(whatsappChannelUrl);

    // Show loading indicator
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Opening WhatsApp Channel...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Try to launch the URL
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.platformDefault,
      );

      // Close loading dialog - use post frame callback to avoid navigator lock issues
      if (mounted && Navigator.of(context).canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
        });
      }

      if (launched) {
        // Success
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Opening WhatsApp Channel...',
            isError: false,
          );
        }
      } else {
        // Failed to launch - show fallback dialog
        if (mounted) {
          await _showWhatsAppLinkDialog(context, whatsappChannelUrl);
        }
      }
    } catch (e) {
      // Close loading dialog - use post frame callback to avoid navigator lock issues
      if (mounted && Navigator.of(context).canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
        });
      }

      // Show fallback dialog
      if (mounted) {
        await _showWhatsAppLinkDialog(context, whatsappChannelUrl);
      }
    }
  }

  Future<void> _showWhatsAppLinkDialog(BuildContext context, String url) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.message,
                color: Color(0xFF25D366),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Join Our WhatsApp Channel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get fresh farmer products directly! Copy the link below and open it in your browser:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) {
                        Helpers.showSnackBar(
                          context,
                          'Link copied to clipboard!',
                          isError: false,
                        );
                      }
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF25D366), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can also search for "NammaOoru Farmer Products" on WhatsApp',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Link copied! Open it in your browser.',
                  isError: false,
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Link', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for curved header
class _CurvedHeaderPainter extends CustomPainter {
  final Color color;

  _CurvedHeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height - 60);

    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated View Details Button with pulse effect
class _AnimatedViewButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedViewButton({required this.onTap});

  @override
  State<_AnimatedViewButton> createState() => _AnimatedViewButtonState();
}

class _AnimatedViewButtonState extends State<_AnimatedViewButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VillageTheme.primaryGreen,
                    const Color(0xFF66BB6A),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: VillageTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
