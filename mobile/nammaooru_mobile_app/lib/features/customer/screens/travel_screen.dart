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
import '../services/travel_service.dart';
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

  // My Posts tab
  late TabController _tabController;
  List<dynamic> _myPosts = [];
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;

  static const Color _travelTeal = Color(0xFF00897B);

  static const Map<String, String> _vehicleTypeLabels = {
    'All': 'All',
    'CAR': 'Car',
    'SMALL_BUS': 'Small Bus',
    'BUS': 'Bus',
  };

  static const Map<String, String> _vehicleTypeTamilMap = {
    'All': '\u0B85\u0BA9\u0BC8\u0BA4\u0BCD\u0BA4\u0BC1\u0BAE\u0BCD',
    'CAR': '\u0B95\u0BBE\u0BB0\u0BCD',
    'SMALL_BUS': '\u0B9A\u0BBF\u0BB1\u0BBF\u0BAF \u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1',
    'BUS': '\u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1',
  };

  static const Map<String, IconData> _vehicleTypeIcons = {
    'CAR': Icons.directions_car,
    'SMALL_BUS': Icons.airport_shuttle,
    'BUS': Icons.directions_bus,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_myPostsLoaded) {
        _loadMyPosts();
      }
    });
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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

    // Get user location for nearby filtering
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      }
    } catch (e) {
      // Location unavailable - will show all posts
    }

    try {
      final response = await _travelService.getApprovedPosts(
        page: 0,
        size: 20,
        vehicleType: _selectedVehicleType,
        latitude: _userLatitude,
        longitude: _userLongitude,
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
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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

  void _navigateToCreatePost() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyPostsTab(),
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

  // --- Tab 1: Browse Travels ---

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Vehicle type filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _vehicleTypeLabels.length,
              itemBuilder: (context, index) {
                final type = _vehicleTypeLabels.keys.elementAt(index);
                final isSelected = (_selectedVehicleType == null && type == 'All') ||
                    _selectedVehicleType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getVehicleTypeTamil(type, context)),
                    selected: isSelected,
                    onSelected: (_) => _onVehicleTypeSelected(type),
                    selectedColor: _travelTeal.withOpacity(0.2),
                    checkmarkColor: _travelTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? _travelTeal : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Posts list
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildPostCard(_posts[index]);
                        },
                      ),
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

    return RefreshIndicator(
      onRefresh: () async {
        _myPostsLoaded = false;
        await _loadMyPosts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myPosts.length,
        itemBuilder: (context, index) {
          final post = _myPosts[index];
          return _buildMyPostCard(post);
        },
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
      default:
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
        statusIcon = Icons.hourglass_empty;
    }

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
                      if (status == 'APPROVED') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
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
}
