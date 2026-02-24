import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/post_filter_bar.dart';
import '../services/travel_service.dart';
import '../services/bus_timing_service.dart';
import '../widgets/renewal_payment_handler.dart';
import 'create_travel_screen.dart';
import 'travel_post_detail_screen.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

final _nameBlurFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5);

class _TravelScreenState extends State<TravelScreen> with SingleTickerProviderStateMixin {
  final TravelService _travelService = TravelService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _selectedVehicleType;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  double? _userLatitude;
  double? _userLongitude;
  double _selectedRadius = 50.0;
  String _searchText = '';

  // My Posts tab
  late TabController _tabController;
  List<dynamic> _myPosts = [];
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;
  Set<int> _selectedForRenewal = {};
  bool _isRenewing = false;

  // Bus Timing tab
  final BusTimingService _busTimingService = BusTimingService();
  final TextEditingController _busSearchController = TextEditingController();
  List<dynamic> _busTimings = [];
  List<_BusRouteGroup> _busRouteGroups = [];
  bool _isBusLoading = true;
  String? _busErrorMessage;
  String _selectedBusLocation = '';
  List<String> _busLocationOptions = [];
  String? _busExpandedKey;
  bool _busTimingsLoaded = false;

  static const Color _travelTeal = Color(0xFF00897B);

  static const Map<String, String> _vehicleTypeLabels = {
    'All': 'All',
    'BUS': 'Bus',
    'LORRY': 'Lorry',
    'SMALL_BUS': 'Mini Bus',
    'RENT': 'Rent',
    'CAR': 'Car',
  };

  static const Map<String, String> _vehicleTypeTamilMap = {
    'All': '\u0B85\u0BA9\u0BC8\u0BA4\u0BCD\u0BA4\u0BC1\u0BAE\u0BCD',
    'BUS': '\u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1',
    'LORRY': '\u0BB2\u0BBE\u0BB0\u0BBF',
    'SMALL_BUS': '\u0BAE\u0BBF\u0BA9\u0BBF \u0BAA\u0BB8\u0BCD',
    'RENT': '\u0BB5\u0BBE\u0B9F\u0B95\u0BC8',
    'CAR': '\u0B95\u0BBE\u0BB0\u0BCD',
  };

  static const Map<String, IconData> _vehicleTypeIcons = {
    'BUS': Icons.directions_bus,
    'LORRY': Icons.local_shipping,
    'SMALL_BUS': Icons.airport_shuttle,
    'RENT': Icons.car_rental,
    'CAR': Icons.directions_car,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_myPostsLoaded) {
        _loadMyPosts();
      }
      if (_tabController.index == 2 && !_busTimingsLoaded) {
        _loadBusTimings();
      }
    });
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _busSearchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    // Fetch GPS in background (don't block the API call)
    if (_userLatitude == null || _userLongitude == null) {
      LocationService.instance.getCurrentPosition().then((position) {
        if (position != null && position.latitude != null && position.longitude != null) {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        }
      }).catchError((_) {});
    }

    try {
      final response = await _travelService.getApprovedPosts(
        page: 0,
        size: 20,
        vehicleType: _selectedVehicleType,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
      );

      if (mounted) {
        final data = response['data'];
        setState(() {
          _posts = data?['content'] ?? [];
          _hasMore = data?['hasNext'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    _currentPage++;
    try {
      final response = await _travelService.getApprovedPosts(
        page: _currentPage,
        size: 20,
        vehicleType: _selectedVehicleType,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
      );

      if (mounted) {
        final data = response['data'];
        setState(() {
          _posts.addAll(data?['content'] ?? []);
          _hasMore = data?['hasNext'] ?? false;
        });
      }
    } catch (e) {
      _currentPage--;
    }
  }

  Future<void> _loadMyPosts() async {
    setState(() => _isLoadingMyPosts = true);
    try {
      final response = await _travelService.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = response['data'] ?? [];
          _myPostsLoaded = true;
          _isLoadingMyPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyPosts = false);
      }
    }
  }

  String _getVehicleTypeDisplay(String? vehicleType) {
    if (vehicleType == null) return '';
    return _vehicleTypeLabels[vehicleType] ?? vehicleType;
  }

  String _getVehicleTypeTamil(String type, BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final english = _vehicleTypeLabels[type] ?? type;
    final tamil = _vehicleTypeTamilMap[type] ?? type;
    return lang.getText(english, tamil);
  }

  void _onVehicleTypeSelected(String vehicleType) {
    setState(() {
      _selectedVehicleType = vehicleType == 'All' ? null : vehicleType;
    });
    _loadPosts();
  }

  void _callOrLogin(Map<String, dynamic> post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }
    _callDriver(post['phone'] ?? '');
  }

  Future<void> _callDriver(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _showReportDialog(Map<String, dynamic> post) {
    final reasons = [
      'Fake / Incorrect Information',
      'Wrong Contact Number',
      'Scam / Fraud',
      'Inappropriate Content',
      'Not Available Anymore',
      'Other',
    ];
    String? selectedReason;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.flag, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              const Text('Report Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting "${post['title']}"?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _travelTeal,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _submitReport(post, selectedReason!, detailsController.text);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(Map<String, dynamic> post, String reason, String details) async {
    final postId = post['id'];
    if (postId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report listings'), backgroundColor: Colors.orange),
      );
      return;
    }

    final result = await _travelService.reportPost(postId, reason, details: details);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] == true ? 'Listing reported' : 'Failed to report')),
          backgroundColor: result['success'] == true ? _travelTeal : Colors.red,
        ),
      );
    }
  }

  void _navigateToCreatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTravelScreen()),
    ).then((_) {
      _loadPosts();
      _myPostsLoaded = false;
      _loadMyPosts();
      _tabController.animateTo(1);
    });
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Travels', '\u0BAA\u0BAF\u0BA3\u0B99\u0BCD\u0B95\u0BB3\u0BCD'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _travelTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: langProvider.getText('Browse', '\u0BAA\u0BBE\u0BB0\u0BCD\u0B95\u0BCD\u0B95')),
            Tab(text: '${langProvider.getText('My Posts', '\u0B8E\u0BA9\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD')}${_myPosts.isNotEmpty ? ' (${_myPosts.length})' : ''}'),
            Tab(text: langProvider.getText('Bus Timing', '\u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1 \u0BA8\u0BC7\u0BB0\u0BAE\u0BCD')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyPostsTab(),
          _buildBusTimingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(),
        backgroundColor: _travelTeal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  List<Map<String, dynamic>> _buildCarouselPosts() {
    return _posts
        .whereType<Map<String, dynamic>>()
        .where((post) => post['featured'] == true)
        .take(8)
        .toList();
  }

  // --- Tab 1: Browse Travels ---

  Widget _buildBrowseTab() {
    return Column(
      children: [
        PostFilterBar(
          categories: _vehicleTypeLabels.keys.toList(),
          selectedCategory: _selectedVehicleType,
          onCategoryChanged: (type) => _onVehicleTypeSelected(type ?? 'All'),
          selectedRadius: _selectedRadius,
          onRadiusChanged: (radius) {
            setState(() => _selectedRadius = radius ?? 50.0);
            _loadPosts();
          },
          searchText: _searchText,
          onSearchSubmitted: (text) {
            setState(() => _searchText = text);
            _loadPosts();
          },
          accentColor: VillageTheme.primaryGreen,
          categoryLabelBuilder: (type) => _getVehicleTypeTamil(type, context),
        ),
        // Posts list
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: Builder(builder: (context) {
                        final carouselPosts = _buildCarouselPosts();
                        final hasCarousel = carouselPosts.isNotEmpty;
                        final offset = hasCarousel ? 1 : 0;
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _posts.length + offset + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (hasCarousel && index == 0) {
                              return _FeaturedBannerCarousel(
                                posts: carouselPosts,
                                onPostTap: (post) => _navigateToDetail(post),
                                accentColor: const Color(0xFF1565C0),
                              );
                            }
                            final postIndex = index - offset;
                            if (postIndex == _posts.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildPostCard(_posts[postIndex]);
                          },
                        );
                      }),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            langProvider.getText('No travel listings yet', '\u0BAA\u0BAF\u0BA3\u0BAA\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD \u0B87\u0BA9\u0BCD\u0BA9\u0BC1\u0BAE\u0BCD \u0B87\u0BB2\u0BCD\u0BB2\u0BC8'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            langProvider.getText('Be the first to post!', '\u0BAE\u0BC1\u0BA4\u0BB2\u0BBF\u0BB2\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD!'),
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(),
            icon: const Icon(Icons.add),
            label: Text(langProvider.getText('Add Travel', '\u0BAA\u0BAF\u0BA3\u0BAE\u0BCD \u0B9A\u0BC7\u0BB0\u0BCD\u0B95\u0BCD\u0B95')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _travelTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  static String? _getFirstImageUrl(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];
    if (imageUrls != null && imageUrls.toString().isNotEmpty) {
      final first = imageUrls.toString().split(',').first.trim();
      if (first.isNotEmpty) return ImageUrlHelper.getFullImageUrl(first);
    }
    return null;
  }

  void _navigateToDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelPostDetailScreen(post: post),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isUnavailable = post['status'] == 'SOLD';
    final fullImageUrl = _getFirstImageUrl(post);
    final vehicleType = post['vehicleType']?.toString() ?? '';
    final vehicleIcon = _vehicleTypeIcons[vehicleType] ?? Icons.directions_bus;

    return GestureDetector(
      onTap: () => _navigateToDetail(post),
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or icon
              if (fullImageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    width: 100,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 130,
                      color: _travelTeal.withOpacity(0.1),
                      child: Icon(vehicleIcon, size: 40, color: _travelTeal),
                    ),
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _travelTeal.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Icon(vehicleIcon, size: 40, color: _travelTeal),
                ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Builder(builder: (context) {
                        final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                        return isLoggedIn
                            ? Text(
                                post['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : ClipRect(
                                child: ImageFiltered(
                                  imageFilter: _nameBlurFilter,
                                  child: Text(
                                    post['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: VillageTheme.primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                      }),
                      const SizedBox(height: 4),
                      // Vehicle type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _travelTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getVehicleTypeDisplay(vehicleType),
                          style: const TextStyle(fontSize: 11, color: _travelTeal, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // From -> To route
                      if ((post['fromLocation'] != null && post['fromLocation'].toString().isNotEmpty) ||
                          (post['toLocation'] != null && post['toLocation'].toString().isNotEmpty))
                        Row(
                          children: [
                            Icon(Icons.route, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${post['fromLocation'] ?? ''} \u2192 ${post['toLocation'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // Price
                      if (post['price'] != null && post['price'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              post['price'].toString(),
                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Call & Report buttons
                      if (!isUnavailable)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () => _callOrLogin(post),
                                  icon: const Icon(Icons.call, size: 16),
                                  label: const Text('Call', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _travelTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 32,
                              width: 32,
                              child: IconButton(
                                onPressed: () => _showReportDialog(post),
                                icon: Icon(Icons.flag_outlined, color: Colors.grey[500], size: 18),
                                padding: EdgeInsets.zero,
                                tooltip: 'Report this listing',
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
          // UNAVAILABLE badge
          if (isUnavailable)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UNAVAILABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  // --- Tab 2: My Posts ---

  Widget _buildMyPostsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Please log in to see your listings', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: _travelTeal, foregroundColor: Colors.white),
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMyPosts) {
      return const Center(child: LoadingWidget());
    }

    if (_myPosts.isEmpty) {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('You haven\'t posted anything yet', '\u0BA8\u0BC0\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0BA9\u0BCD\u0BA9\u0BC1\u0BAE\u0BCD \u0B8E\u0BA4\u0BC1\u0BB5\u0BC1\u0BAE\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BBF\u0B9F\u0BB5\u0BBF\u0BB2\u0BCD\u0BB2\u0BC8'),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add),
              label: Text(langProvider.getText('Add Travel', '\u0BAA\u0BAF\u0BA3\u0BAE\u0BCD \u0B9A\u0BC7\u0BB0\u0BCD\u0B95\u0BCD\u0B95')),
              style: ElevatedButton.styleFrom(backgroundColor: _travelTeal, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    // Count expired/expiring posts for bulk selection
    final expiredPostIds = _myPosts.where((p) {
      final vTo = p['validTo'] != null ? DateTime.tryParse(p['validTo'].toString()) : null;
      if (vTo == null) return false;
      final now = DateTime.now();
      return vTo.isBefore(now) || (vTo.isAfter(now) && vTo.difference(now).inDays <= 3);
    }).map((p) => p['id'] as int).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _myPostsLoaded = false;
        setState(() => _selectedForRenewal.clear());
        await _loadMyPosts();
      },
      child: Column(
        children: [
          if (expiredPostIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  SizedBox(width: 24, height: 24,
                    child: Checkbox(
                      value: _selectedForRenewal.length == expiredPostIds.length && expiredPostIds.isNotEmpty,
                      tristate: true,
                      onChanged: (val) {
                        setState(() {
                          if (_selectedForRenewal.length == expiredPostIds.length) {
                            _selectedForRenewal.clear();
                          } else {
                            _selectedForRenewal = expiredPostIds.toSet();
                          }
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedForRenewal.isEmpty ? 'Select expired posts to renew' : '${_selectedForRenewal.length} selected',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  if (_selectedForRenewal.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isRenewing ? null : _renewSelectedPosts,
                      icon: _isRenewing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_isRenewing ? 'Renewing...' : 'Renew All (${_selectedForRenewal.length})'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                final post = _myPosts[index];
                return _buildMyPostCard(post);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostCard(Map<String, dynamic> post) {
    final status = post['status'] ?? 'PENDING_APPROVAL';
    final fullImageUrl = _getFirstImageUrl(post);
    final vehicleType = post['vehicleType']?.toString() ?? '';
    final vehicleIcon = _vehicleTypeIcons[vehicleType] ?? Icons.directions_bus;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'SOLD':
        statusColor = Colors.blue;
        statusText = 'Unavailable';
        statusIcon = Icons.block;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'FLAGGED':
        statusColor = const Color(0xFFB71C1C);
        statusText = 'Flagged';
        statusIcon = Icons.flag;
        break;
      case 'HOLD':
        statusColor = Colors.amber.shade700;
        statusText = 'On Hold';
        statusIcon = Icons.pause_circle;
        break;
      case 'HIDDEN':
        statusColor = Colors.grey;
        statusText = 'Hidden';
        statusIcon = Icons.visibility_off;
        break;
      case 'CORRECTION_REQUIRED':
        statusColor = Colors.deepOrange;
        statusText = 'Correction Required';
        statusIcon = Icons.edit;
        break;
      case 'REMOVED':
        statusColor = const Color(0xFFB71C1C);
        statusText = 'Removed';
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
        statusIcon = Icons.hourglass_empty;
    }

    // Validity dates and expiry status
    final validFrom = post['validFrom'] != null ? DateTime.tryParse(post['validFrom'].toString()) : null;
    final validTo = post['validTo'] != null ? DateTime.tryParse(post['validTo'].toString()) : null;
    final now = DateTime.now();
    final bool isExpiringSoon = validTo != null && validTo.isAfter(now) && validTo.difference(now).inDays <= 3;
    final bool isExpired = validTo != null && validTo.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          // Validity & expiry info
          if (validTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isExpired ? Colors.red.withOpacity(0.08) : isExpiringSoon ? Colors.orange.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Valid: ${validFrom != null ? "${validFrom.day}/${validFrom.month}/${validFrom.year}" : "—"} - ${validTo.day}/${validTo.month}/${validTo.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: const Text('EXPIRING SOON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or icon
              if (fullImageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: fullImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80, height: 80, color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80, height: 80, color: _travelTeal.withOpacity(0.1),
                        child: Icon(vehicleIcon, size: 30, color: _travelTeal),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _travelTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(vehicleIcon, size: 30, color: _travelTeal),
                  ),
                ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getVehicleTypeDisplay(vehicleType),
                        style: TextStyle(fontSize: 13, color: _travelTeal, fontWeight: FontWeight.w500),
                      ),
                      if ((post['fromLocation'] != null && post['fromLocation'].toString().isNotEmpty) ||
                          (post['toLocation'] != null && post['toLocation'].toString().isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${post['fromLocation'] ?? ''} \u2192 ${post['toLocation'] ?? ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isExpiringSoon || isExpired) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _selectedForRenewal.contains(post['id']),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedForRenewal.add(post['id']);
                                    } else {
                                      _selectedForRenewal.remove(post['id']);
                                    }
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isRenewing ? null : () => _renewSinglePost(post['id']),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Renew Post'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await _travelService.markAsUnavailable(post['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                    );
                                    if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                                  }
                                },
                                icon: const Icon(Icons.block, size: 16),
                                label: const Text('Unavailable', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
                            const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showEditTravelSheet(post),
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Listing?'),
                                  content: const Text('This action cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final result = await _travelService.deletePost(post['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                  );
                                  if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      if (status == 'SOLD') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await _travelService.markAsAvailable(post['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                    );
                                    if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Mark Available', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Listing?'),
                                    content: const Text('This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final result = await _travelService.deletePost(post['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                    );
                                    if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditTravelSheet(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final phoneController = TextEditingController(text: post['phone'] ?? '');
    final fromController = TextEditingController(text: post['fromLocation'] ?? '');
    final toController = TextEditingController(text: post['toLocation'] ?? '');
    final priceController = TextEditingController(text: post['price'] ?? '');
    final seatsController = TextEditingController(text: post['seatsAvailable']?.toString() ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: fromController, decoration: const InputDecoration(labelText: 'From Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: toController, decoration: const InputDecoration(labelText: 'To Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: seatsController, decoration: const InputDecoration(labelText: 'Seats Available', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      final updates = <String, dynamic>{};
                      if (titleController.text != (post['title'] ?? '')) updates['title'] = titleController.text;
                      if (phoneController.text != (post['phone'] ?? '')) updates['phone'] = phoneController.text;
                      if (fromController.text != (post['fromLocation'] ?? '')) updates['fromLocation'] = fromController.text;
                      if (toController.text != (post['toLocation'] ?? '')) updates['toLocation'] = toController.text;
                      if (priceController.text != (post['price'] ?? '')) updates['price'] = priceController.text;
                      if (seatsController.text != (post['seatsAvailable']?.toString() ?? '')) {
                        updates['seatsAvailable'] = int.tryParse(seatsController.text);
                      }
                      if (descController.text != (post['description'] ?? '')) updates['description'] = descController.text;
                      if (updates.isEmpty) { Navigator.pop(ctx); return; }
                      final result = await _travelService.editPost(post['id'], updates);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _travelTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _renewSinglePost(int postId) {
    final handler = RenewalPaymentHandler(context: context, postType: 'TRAVELS');
    handler.renewSingle(
      onTokenReceived: (paidTokenId) async {
        final result = await _travelService.renewPost(postId, paidTokenId: paidTokenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
          );
          if (result['success'] == true) {
            setState(() { _myPostsLoaded = false; _selectedForRenewal.remove(postId); });
            _loadMyPosts();
          }
        }
        handler.dispose();
      },
      onCancelled: () => handler.dispose(),
    );
  }

  void _renewSelectedPosts() {
    if (_selectedForRenewal.isEmpty) return;
    final selectedIds = _selectedForRenewal.toList();
    final count = selectedIds.length;

    setState(() => _isRenewing = true);
    final handler = RenewalPaymentHandler(context: context, postType: 'TRAVELS');
    handler.renewBulk(
      count: count,
      onTokensReceived: (paidTokenIds) async {
        int successCount = 0;
        for (int i = 0; i < selectedIds.length && i < paidTokenIds.length; i++) {
          final result = await _travelService.renewPost(selectedIds[i], paidTokenId: paidTokenIds[i]);
          if (result['success'] == true) successCount++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successCount of $count posts renewed successfully'), backgroundColor: successCount > 0 ? Colors.green : Colors.red),
          );
          setState(() { _isRenewing = false; _selectedForRenewal.clear(); _myPostsLoaded = false; });
          _loadMyPosts();
        }
        handler.dispose();
      },
      onCancelled: () {
        setState(() => _isRenewing = false);
        handler.dispose();
      },
    );
  }

  // --- Tab 3: Bus Timing ---

  Future<void> _loadBusTimings() async {
    setState(() {
      _isBusLoading = true;
      _busErrorMessage = null;
    });

    try {
      final response = await _busTimingService.getActiveBusTimings();

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        final locations = <String>{};
        for (final t in data) {
          if (t['locationArea'] != null && t['locationArea'].toString().isNotEmpty) {
            locations.add(t['locationArea'].toString());
          }
        }

        setState(() {
          _busTimings = data;
          _busLocationOptions = locations.toList()..sort();
          _isBusLoading = false;
          _busTimingsLoaded = true;
        });
        _applyBusFilters();
      } else {
        setState(() {
          _busErrorMessage = response['message'] ?? 'Failed to load bus timings';
          _isBusLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _busErrorMessage = 'Could not connect to server';
        _isBusLoading = false;
      });
    }
  }

  int _parseBusTimeForSort(String time) {
    if (time.isEmpty) return 0;
    try {
      final t = time.toUpperCase().trim();
      final isPM = t.contains('PM');
      final cleaned = t.replaceAll(RegExp(r'[APM\s]'), '');
      final parts = cleaned.split(':');
      var hour = int.parse(parts[0]);
      final min = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return hour * 60 + min;
    } catch (_) {
      return 0;
    }
  }

  void _applyBusFilters() {
    final search = _busSearchController.text.toLowerCase().trim();

    final filtered = _busTimings.where((t) {
      if (_selectedBusLocation.isNotEmpty && t['locationArea'] != _selectedBusLocation) {
        return false;
      }
      if (search.isNotEmpty) {
        final busNumber = (t['busNumber'] ?? '').toString().toLowerCase();
        final busName = (t['busName'] ?? '').toString().toLowerCase();
        final routeFrom = (t['routeFrom'] ?? '').toString().toLowerCase();
        final routeTo = (t['routeTo'] ?? '').toString().toLowerCase();
        final viaStops = (t['viaStops'] ?? '').toString().toLowerCase();
        return busNumber.contains(search) ||
            busName.contains(search) ||
            routeFrom.contains(search) ||
            routeTo.contains(search) ||
            viaStops.contains(search);
      }
      return true;
    }).toList();

    final Map<String, List<dynamic>> groupMap = {};
    for (final t in filtered) {
      final from = (t['routeFrom'] ?? '').toString().trim();
      final to = (t['routeTo'] ?? '').toString().trim();
      final key = '$from \u2192 $to';
      groupMap.putIfAbsent(key, () => []);
      groupMap[key]!.add(t);
    }

    final groups = <_BusRouteGroup>[];
    for (final entry in groupMap.entries) {
      entry.value.sort((a, b) {
        final timeA = _parseBusTimeForSort(a['departureTime'] ?? '');
        final timeB = _parseBusTimeForSort(b['departureTime'] ?? '');
        return timeA.compareTo(timeB);
      });
      groups.add(_BusRouteGroup(route: entry.key, timings: entry.value));
    }
    groups.sort((a, b) => a.route.compareTo(b.route));

    setState(() {
      _busRouteGroups = groups;
      _busExpandedKey = null;
    });
  }

  Widget _buildBusTimingTab() {
    return Column(
      children: [
        // Search bar
        Container(
          color: _travelTeal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _busSearchController,
            onChanged: (_) => _applyBusFilters(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search bus number, route...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              suffixIcon: _busSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                      onPressed: () {
                        _busSearchController.clear();
                        _applyBusFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Location filter chips
        if (_busLocationOptions.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildBusFilterChip('All', ''),
                ..._busLocationOptions.map((loc) => _buildBusFilterChip(loc, loc)),
              ],
            ),
          ),
        // Content
        Expanded(child: _buildBusBody()),
      ],
    );
  }

  Widget _buildBusFilterChip(String label, String value) {
    final isSelected = _selectedBusLocation == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: _travelTeal,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? _travelTeal : Colors.grey[300]!),
        onSelected: (_) {
          setState(() => _selectedBusLocation = value);
          _applyBusFilters();
        },
      ),
    );
  }

  Widget _buildBusBody() {
    if (_isBusLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_busErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_busErrorMessage!, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBusTimings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _travelTeal, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_busRouteGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _busSearchController.text.isNotEmpty || _selectedBusLocation.isNotEmpty
                  ? 'No bus timings match your search'
                  : 'No bus timings available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBusTimings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _busRouteGroups.length,
        itemBuilder: (context, groupIndex) {
          return _buildBusRouteGroupCard(_busRouteGroups[groupIndex], groupIndex);
        },
      ),
    );
  }

  Widget _buildBusRouteGroupCard(_BusRouteGroup group, int groupIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[500]!]),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(group.route, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${group.timings.length} bus${group.timings.length > 1 ? 'es' : ''}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          ...List.generate(group.timings.length, (timingIndex) {
            final timing = group.timings[timingIndex];
            final key = '$groupIndex-$timingIndex';
            final isExpanded = _busExpandedKey == key;
            final isLast = timingIndex == group.timings.length - 1;
            return _buildBusTimingRow(timing, key, isExpanded, isLast);
          }),
        ],
      ),
    );
  }

  List<Map<String, String>> _parseBusStops(String? viaStops) {
    if (viaStops == null || viaStops.isEmpty) return [];
    try {
      final parsed = jsonDecode(viaStops);
      if (parsed is List) {
        return parsed.map<Map<String, String>>((s) => {
          'name': (s['name'] ?? '').toString(),
          'time': (s['time'] ?? '').toString(),
        }).where((s) => s['name']!.isNotEmpty).toList();
      }
    } catch (_) {
      if (viaStops.contains(',') || viaStops.trim().isNotEmpty) {
        return viaStops.split(',').map((s) => {'name': s.trim(), 'time': ''}).where((s) => s['name']!.isNotEmpty).toList();
      }
    }
    return [];
  }

  Widget _buildBusTimingRow(dynamic timing, String key, bool isExpanded, bool isLast) {
    final busType = timing['busType'] ?? 'GOVERNMENT';
    final isGovt = busType == 'GOVERNMENT';
    final fare = timing['fare'];
    final depTime = timing['departureTime'] ?? '';
    final arrTime = timing['arrivalTime'] ?? '';
    final stops = _parseBusStops(timing['viaStops']?.toString());

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _busExpandedKey = isExpanded ? null : key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(depTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[800])),
                      Text(arrTime, style: TextStyle(fontSize: 11, color: Colors.red[600])),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.grey[200]),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGovt ? Colors.blue[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isGovt ? Colors.blue[200]! : Colors.orange[200]!),
                        ),
                        child: Text(timing['busNumber'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isGovt ? Colors.blue[800] : Colors.orange[800])),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: isGovt ? Colors.blue[700] : Colors.orange[700], borderRadius: BorderRadius.circular(3)),
                        child: Text(isGovt ? 'Govt' : 'Pvt', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                      if (stops.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('${stops.length} stops', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
                if (fare != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('\u20B9${fare is double ? fare.toStringAsFixed(0) : fare}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[700])),
                  ),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timing['busName'] != null && timing['busName'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(timing['busName'], style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ),
                _buildBusRouteTimeline(timing, stops),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(_getBusOperatingDaysLabel(timing['operatingDays'] ?? 'DAILY'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(timing['locationArea'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        if (!isLast && !isExpanded) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildBusRouteTimeline(dynamic timing, List<Map<String, String>> stops) {
    return Column(
      children: [
        _buildBusTimelineRow(color: Colors.green[600]!, dotSize: 10, name: timing['routeFrom'] ?? '', time: timing['departureTime'] ?? '', timeBg: const Color(0xFFE8F5E9), timeColor: const Color(0xFF2E7D32), isFirst: true, isLast: stops.isEmpty, isBold: true),
        for (int i = 0; i < stops.length; i++)
          _buildBusTimelineRow(color: Colors.orange[600]!, dotSize: 7, name: stops[i]['name'] ?? '', time: stops[i]['time'] ?? '', timeBg: const Color(0xFFFFF3E0), timeColor: const Color(0xFFE65100), isFirst: false, isLast: false, isBold: false),
        _buildBusTimelineRow(color: Colors.red[600]!, dotSize: 10, name: timing['routeTo'] ?? '', time: timing['arrivalTime'] ?? '', timeBg: const Color(0xFFFFEBEE), timeColor: const Color(0xFFC62828), isFirst: false, isLast: true, isBold: true),
      ],
    );
  }

  Widget _buildBusTimelineRow({required Color color, required double dotSize, required String name, required String time, required Color timeBg, required Color timeColor, required bool isFirst, required bool isLast, required bool isBold}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: Colors.grey[300])) else const Expanded(child: SizedBox()),
                Container(width: dotSize, height: dotSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[300])) else const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isBold ? 6 : 4),
              child: Text(name, style: TextStyle(fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, fontSize: isBold ? 14 : 13, color: isBold ? Colors.black87 : Colors.grey[700])),
            ),
          ),
          if (time.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(vertical: isBold ? 4 : 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: timeBg, borderRadius: BorderRadius.circular(6)),
              child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 12 : 11, color: timeColor)),
            ),
        ],
      ),
    );
  }

  String _getBusOperatingDaysLabel(String days) {
    switch (days) {
      case 'DAILY': return 'Daily';
      case 'WEEKDAYS': return 'Mon-Fri';
      case 'WEEKENDS': return 'Sat-Sun';
      default: return days;
    }
  }
}

class _BusRouteGroup {
  final String route;
  final List<dynamic> timings;
  _BusRouteGroup({required this.route, required this.timings});
}

// ─── Featured Banner Carousel ───

class _FeaturedBannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final Function(Map<String, dynamic>) onPostTap;
  final Color accentColor;

  const _FeaturedBannerCarousel({
    required this.posts,
    required this.onPostTap,
    required this.accentColor,
  });

  @override
  State<_FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<_FeaturedBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && widget.posts.length > 1) {
        final nextPage = (_currentPage + 1) % widget.posts.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<String> _parseImageUrls(Map<String, dynamic> post) {
    final raw = post['imageUrls'] ?? post['imageUrl'] ?? '';
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    return raw.toString().split(',').where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.star, color: widget.accentColor, size: 20),
              const SizedBox(width: 6),
              Text(
                'Featured',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.accentColor),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              final imageUrls = _parseImageUrls(post);
              final firstImage = imageUrls.isNotEmpty ? imageUrls.first : null;

              return GestureDetector(
                onTap: () => widget.onPostTap(post),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstImage != null)
                          CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Text(
                            post['title'] ?? post['name'] ?? post['serviceName'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        if (widget.posts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.posts.length, (index) {
              return Container(
                width: _currentPage == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage == index ? widget.accentColor : Colors.grey[350],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
