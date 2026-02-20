import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/services/location_service.dart';
import '../services/marketplace_service.dart';
import '../services/real_estate_service.dart';
import '../widgets/renewal_payment_handler.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/post_filter_bar.dart';
import 'create_post_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

final _nameBlurFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5);

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;
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

  // Real Estate tab
  final RealEstateService _realEstateService = RealEstateService();
  List<Map<String, dynamic>> _reListings = [];
  bool _reIsLoading = true;
  String? _reError;
  int _reCurrentPage = 0;
  bool _reHasMore = true;
  final ScrollController _reScrollController = ScrollController();
  String _reSelectedFilter = 'All';
  final List<String> _reFilters = ['All', 'For Sale', 'For Rent', 'Land', 'House', 'Apartment'];
  bool _reLoaded = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Vehicles',
    'Clothing',
    'Food',
    'Finance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_reLoaded) {
        _reFetchListings();
      }
      if (_tabController.index == 2 && !_myPostsLoaded) {
        _loadMyPosts();
      }
      setState(() {}); // Update FAB icon
    });
    _loadPosts();
    _scrollController.addListener(_onScroll);
    _reScrollController.addListener(_reOnScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _reScrollController.dispose();
    super.dispose();
  }

  // ─── Marketplace methods ───

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
      final response = await _marketplaceService.getApprovedPosts(
        page: 0,
        size: 20,
        category: _selectedCategory,
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
      final response = await _marketplaceService.getApprovedPosts(
        page: _currentPage,
        size: 20,
        category: _selectedCategory,
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
      final response = await _marketplaceService.getMyPosts();
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

  String _getCategoryTamil(String cat, BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    const tamilMap = {
      'All': 'அனைத்தும்',
      'Electronics': 'எலக்ட்ரானிக்ஸ்',
      'Furniture': 'மரச்சாமான்',
      'Vehicles': 'வாகனங்கள்',
      'Clothing': 'ஆடைகள்',
      'Food': 'உணவு',
      'Finance': 'நிதி',
      'Other': 'பிற',
    };
    return lang.getText(cat, tamilMap[cat] ?? cat);
  }

  String _getReFilterTamil(String filter) {
    const tamilMap = {
      'All': 'அனைத்தும்',
      'For Sale': 'விற்பனைக்கு',
      'For Rent': 'வாடகைக்கு',
      'Land': 'நிலம்',
      'House': 'வீடு',
      'Apartment': 'அடுக்குமாடி',
    };
    return tamilMap[filter] ?? filter;
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
    _loadPosts();
  }

  void _callOrLogin(Map<String, dynamic> post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }
    _callSeller(post['sellerPhone'] ?? '');
  }

  Future<void> _callSeller(String phone) async {
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
      'Fake / Counterfeit Product',
      'Stolen Product',
      'Scam / Fraud',
      'Inappropriate Content',
      'Wrong Information',
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
              const Text('Report Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  activeColor: VillageTheme.primaryGreen,
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
        const SnackBar(content: Text('Please log in to report posts'), backgroundColor: Colors.orange),
      );
      return;
    }

    final result = await _marketplaceService.reportPost(postId, reason, details: details);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] == true ? 'Post reported' : 'Failed to report')),
          backgroundColor: result['success'] == true ? VillageTheme.primaryGreen : Colors.red,
        ),
      );
    }
  }

  // ─── Real Estate methods ───

  void _reOnScroll() {
    if (_reScrollController.position.pixels >= _reScrollController.position.maxScrollExtent - 200) {
      if (!_reIsLoading && _reHasMore) {
        _reLoadMore();
      }
    }
  }

  Future<void> _reFetchListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _reCurrentPage = 0;
        _reHasMore = true;
        _reListings = [];
      });
    }

    setState(() {
      _reIsLoading = true;
      _reError = null;
    });

    try {
      String? propertyType;
      String? listingType;

      if (_reSelectedFilter == 'For Sale') {
        listingType = 'FOR_SALE';
      } else if (_reSelectedFilter == 'For Rent') {
        listingType = 'FOR_RENT';
      } else if (_reSelectedFilter != 'All') {
        propertyType = _reSelectedFilter.toUpperCase();
      }

      final response = await _realEstateService.getApprovedPosts(
        page: _reCurrentPage,
        size: 20,
        propertyType: propertyType,
        listingType: listingType,
        search: _reSearchText.isNotEmpty ? _reSearchText : null,
      );

      if (response['success'] == true || response['data'] != null) {
        final content = response['data']?['content'] as List? ?? [];
        final newListings = content.map<Map<String, dynamic>>((item) => _reMapApiToLocal(item)).toList();

        setState(() {
          if (refresh || _reCurrentPage == 0) {
            _reListings = newListings;
          } else {
            _reListings.addAll(newListings);
          }
          _reHasMore = newListings.length >= 20;
          _reIsLoading = false;
          _reLoaded = true;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch listings');
      }
    } catch (e) {
      setState(() {
        _reIsLoading = false;
        _reError = e.toString();
        _reLoaded = true;
      });
    }
  }

  Future<void> _reLoadMore() async {
    _reCurrentPage++;
    await _reFetchListings();
  }

  Map<String, dynamic> _reMapApiToLocal(Map<String, dynamic> api) {
    final listingType = api['listingType']?.toString() ?? 'FOR_SALE';
    final propertyType = api['propertyType']?.toString() ?? 'LAND';

    return {
      'id': api['id'],
      'title': api['title'] ?? '',
      'type': _reFormatPropertyType(propertyType),
      'listingType': listingType == 'FOR_RENT' ? 'For Rent' : 'For Sale',
      'price': (api['price'] as num?)?.toInt() ?? 0,
      'priceUnit': listingType == 'FOR_RENT' ? 'month' : 'total',
      'area': api['areaSqft'] != null ? '${api['areaSqft']} sq.ft' : 'N/A',
      'areaSqft': api['areaSqft'],
      'bedrooms': api['bedrooms'],
      'bathrooms': api['bathrooms'],
      'location': api['location'] ?? '',
      'description': api['description'] ?? '',
      'images': (api['imageUrls'] as String?)?.split(',') ?? [],
      'videoUrl': api['videoUrl'],
      'postedBy': api['ownerName'] ?? 'Unknown',
      'phone': api['ownerPhone'] ?? '',
      'postedDate': api['createdAt'] != null ? DateTime.tryParse(api['createdAt']) ?? DateTime.now() : DateTime.now(),
      'viewsCount': api['viewsCount'] ?? 0,
    };
  }

  String _reFormatPropertyType(String type) {
    switch (type.toUpperCase()) {
      case 'LAND': return 'Land';
      case 'HOUSE': return 'House';
      case 'APARTMENT': return 'Apartment';
      case 'VILLA': return 'Villa';
      case 'COMMERCIAL': return 'Commercial';
      case 'PLOT': return 'Plot';
      case 'FARM_LAND': return 'Farm Land';
      case 'PG_HOSTEL': return 'PG/Hostel';
      default: return type;
    }
  }

  String _reGetFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    return ImageUrlHelper.getFullImageUrl(path.trim());
  }

  List<String> _reGetImageUrls(Map<String, dynamic> listing) {
    final images = listing['images'];
    if (images == null) return [];
    if (images is List) {
      return images.where((img) => img != null && img.toString().trim().isNotEmpty)
          .map<String>((img) => _reGetFullImageUrl(img.toString().trim()))
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  String _reFormatPrice(int price) {
    if (price >= 10000000) {
      return '${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(2)} L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} K';
    }
    return price.toString();
  }

  String _reFormatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Ooru Market', 'ஊரு மார்க்கெட்'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: VillageTheme.primaryGreen,
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
            Tab(text: langProvider.getText('Buy & Sell', 'வாங்க & விற்க')),
            Tab(text: langProvider.getText('Real Estate', 'ரியல் எஸ்டேட்')),
            Tab(text: '${langProvider.getText('My Posts', 'என் பதிவுகள்')}${_myPosts.isNotEmpty ? ' (${_myPosts.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Approved Marketplace Posts
          _buildMarketplaceTab(),
          // Tab 2: Real Estate Browse
          _buildRealEstateTab(),
          // Tab 3: My Posts
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 1) {
            _showPostPropertySheet();
          } else {
            _navigateToCreatePost();
          }
        },
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // ─── Tab 1: Marketplace Buy & Sell ───

  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        PostFilterBar(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (cat) => _onCategorySelected(cat ?? 'All'),
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
          categoryLabelBuilder: (cat) => _getCategoryTamil(cat, context),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items for sale yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post something!',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(),
            icon: const Icon(Icons.add),
            label: const Text('Sell Something'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VillageTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarketplacePostDetailsSheet(post: post),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isSold = post['status'] == 'SOLD';
    final imageUrl = post['imageUrl'];
    final voiceUrl = post['voiceUrl'];
    final price = post['price'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
      onTap: () => _showPostDetails(post),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                      if (voiceUrl != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.volume_up, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            post['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: VillageTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatPrice(price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: VillageTheme.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                      Text(
                        post['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final sellerName = post['sellerName'] ?? 'Seller';
                      return Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          if (isLoggedIn)
                            Text(
                              sellerName,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            )
                          else
                            ClipRect(
                              child: ImageFiltered(
                                imageFilter: _nameBlurFilter,
                                child: Text(
                                  sellerName,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          if (post['location'] != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                post['location'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    if (post['category'] != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post['category'],
                          style: const TextStyle(fontSize: 11, color: VillageTheme.primaryGreen),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Call & Report buttons
                    if (!isSold)
                      Builder(builder: (context) {
                        final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                        return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _callOrLogin(post),
                              icon: const Icon(Icons.call, size: 18),
                              label: Text(isLoggedIn
                                  ? 'Call ${post['sellerName']?.split(' ').first ?? 'Seller'}'
                                  : 'Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showReportDialog(post),
                            icon: Icon(Icons.flag_outlined, color: Colors.grey[500]),
                            tooltip: 'Report this post',
                          ),
                        ],
                      );
                      }),
                  ],
                ),
              ),
            ],
          ),
          // SOLD OUT badge
          if (isSold)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SOLD OUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    if (numPrice >= 100000) {
      return '\u20B9${(numPrice / 100000).toStringAsFixed(1)}L';
    } else if (numPrice >= 1000) {
      return '\u20B9${(numPrice / 1000).toStringAsFixed(numPrice % 1000 == 0 ? 0 : 1)}K';
    }
    return '\u20B9${numPrice.toStringAsFixed(0)}';
  }

  String _reSearchText = '';

  // ─── Tab 2: Real Estate Browse ───

  Widget _buildRealEstateTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: TextEditingController(text: _reSearchText)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _reSearchText.length),
                ),
              decoration: InputDecoration(
                hintText: 'Search by location...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                suffixIcon: _reSearchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                        onPressed: () {
                          setState(() => _reSearchText = '');
                          _reFetchListings(refresh: true);
                        },
                        padding: EdgeInsets.zero,
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: (text) {
                setState(() => _reSearchText = text);
                _reFetchListings(refresh: true);
              },
            ),
          ),
        ),
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _reFilters.map((filter) {
                final isSelected = _reSelectedFilter == filter;
                final lang = Provider.of<LanguageProvider>(context, listen: false);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lang.getText(filter, _getReFilterTamil(filter))),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _reSelectedFilter = filter);
                      _reFetchListings(refresh: true);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: VillageTheme.primaryGreen.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? VillageTheme.primaryGreen : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: VillageTheme.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Listings
        Expanded(
          child: _reIsLoading && _reListings.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _reError != null && _reListings.isEmpty
                  ? _buildReErrorState()
                  : _reListings.isEmpty
                      ? _buildReEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _reFetchListings(refresh: true),
                          child: ListView.builder(
                            controller: _reScrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _reListings.length + (_reHasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _reListings.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _buildPropertyCard(_reListings[index]);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildReEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No properties found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Be the first to post a property!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildReErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Failed to load properties', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(_reError ?? 'An error occurred', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _reFetchListings(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> listing) {
    final isForSale = listing['listingType'] == 'For Sale';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPropertyDetails(listing),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image carousel
            _buildImageCarousel(listing, isForSale),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing['title'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_reFormatPrice(listing['price'])}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen),
                          ),
                          if (listing['priceUnit'] == 'month')
                            Text('/month', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.square_foot, listing['area']),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.location_on, listing['location']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                    return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isLoggedIn)
                        Text('Posted by ${listing['postedBy']}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Posted by ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ClipRect(
                              child: ImageFiltered(
                                imageFilter: _nameBlurFilter,
                                child: Text(listing['postedBy'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ),
                            ),
                          ],
                        ),
                      Text(_reFormatDate(listing['postedDate']), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(Map<String, dynamic> listing, bool isForSale) {
    final imageUrls = _reGetImageUrls(listing);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          if (imageUrls.isNotEmpty)
            _ImageCarouselWidget(
              imageUrls: imageUrls,
              height: 180,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              fallbackIcon: listing['type'] == 'Land' ? Icons.landscape : Icons.home,
            )
          else
            Center(
              child: Icon(
                listing['type'] == 'Land' ? Icons.landscape : Icons.home,
                size: 64,
                color: Colors.grey[500],
              ),
            ),
          // Type badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isForSale ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                listing['listingType'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Property type badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                listing['type'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          // Photo count badge
          if (imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('${imageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  void _showPropertyDetails(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PropertyDetailsSheet(listing: listing),
    );
  }

  void _showPostPropertySheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PostPropertySheet(),
    );

    if (result != null && mounted) {
      _reCurrentPage = 0;
      _reListings.clear();
      _reHasMore = true;
      _reFetchListings();
    }
  }

  // ─── Tab 3: My Posts ───

  Widget _buildMyPostsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Please log in to see your posts', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('You haven\'t posted anything yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add),
              label: const Text('Sell Something'),
              style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white),
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
                  SizedBox(
                    width: 24,
                    height: 24,
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
                    _selectedForRenewal.isEmpty
                        ? 'Select expired posts to renew'
                        : '${_selectedForRenewal.length} selected',
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
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
    final imageUrl = post['imageUrl'];
    final price = post['price'];

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
        statusText = 'Sold';
        statusIcon = Icons.sell;
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
          // Image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180, color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180, color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price != null)
                      Text(_formatPrice(price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen)),
                  ],
                ),
                if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(post['description'], style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await _marketplaceService.markAsSold(post['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                              );
                              if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                            }
                          },
                          icon: const Icon(Icons.sell, size: 16),
                          label: const Text('Mark Sold'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showEditMarketplaceSheet(post),
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Post?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final result = await _marketplaceService.deletePost(post['id']);
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
        ],
      ),
    );
  }

  void _showEditMarketplaceSheet(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
    final priceController = TextEditingController(text: post['price']?.toString() ?? '');
    final phoneController = TextEditingController(text: post['sellerPhone'] ?? '');
    final categoryController = TextEditingController(text: post['category'] ?? '');
    final locationController = TextEditingController(text: post['location'] ?? '');
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
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      final updates = <String, dynamic>{};
                      if (titleController.text != (post['title'] ?? '')) updates['title'] = titleController.text;
                      if (descController.text != (post['description'] ?? '')) updates['description'] = descController.text;
                      if (priceController.text != (post['price']?.toString() ?? '')) updates['price'] = priceController.text;
                      if (phoneController.text != (post['sellerPhone'] ?? '')) updates['phone'] = phoneController.text;
                      if (categoryController.text != (post['category'] ?? '')) updates['category'] = categoryController.text;
                      if (locationController.text != (post['location'] ?? '')) updates['location'] = locationController.text;
                      if (updates.isEmpty) { Navigator.pop(ctx); return; }
                      final result = await _marketplaceService.editPost(post['id'], updates);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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
    final handler = RenewalPaymentHandler(context: context, postType: 'MARKETPLACE');
    handler.renewSingle(
      onTokenReceived: (paidTokenId) async {
        final result = await _marketplaceService.renewPost(postId, paidTokenId: paidTokenId);
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
    final handler = RenewalPaymentHandler(context: context, postType: 'MARKETPLACE');
    handler.renewBulk(
      count: count,
      onTokensReceived: (paidTokenIds) async {
        int successCount = 0;
        for (int i = 0; i < selectedIds.length && i < paidTokenIds.length; i++) {
          final result = await _marketplaceService.renewPost(selectedIds[i], paidTokenId: paidTokenIds[i]);
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

  void _navigateToCreatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    ).then((_) {
      _loadPosts();
      _myPostsLoaded = false;
      _loadMyPosts();
      // Switch to My Posts tab
      _tabController.animateTo(2);
    });
  }
}

// ─── Property Details Bottom Sheet ───

class _PropertyDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> listing;

  const _PropertyDetailsSheet({required this.listing});

  @override
  State<_PropertyDetailsSheet> createState() => _PropertyDetailsSheetState();
}

class _PropertyDetailsSheetState extends State<_PropertyDetailsSheet> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  Map<String, dynamic> get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getImageUrlsFromListing() {
    final images = listing['images'];
    final imageUrls = <String>[];
    if (images is List) {
      for (final img in images) {
        if (img != null && img.toString().trim().isNotEmpty) {
          final url = ImageUrlHelper.getFullImageUrl(img.toString().trim());
          if (url.isNotEmpty && url.startsWith('http')) {
            imageUrls.add(url);
          }
        }
      }
    }
    return imageUrls;
  }

  Widget _buildDetailGallery(BuildContext context) {
    final imageUrls = _getImageUrlsFromListing();
    if (imageUrls.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            listing['type'] == 'Land' ? Icons.landscape : Icons.home,
            size: 80,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openFullScreenGallery(context, imageUrls, _currentImageIndex),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrls[index],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey[500])),
                        ),
                      ),
                    );
                  },
                ),
                if (imageUrls.length > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${imageUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              return Container(
                width: _currentImageIndex == index ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentImageIndex == index ? VillageTheme.primaryGreen : Colors.grey[350],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentImageIndex == index ? VillageTheme.primaryGreen : Colors.grey[300]!,
                        width: _currentImageIndex == index ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, size: 20, color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailGallery(context),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing['title'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: listing['listingType'] == 'For Sale' ? Colors.green : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          listing['listingType'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${listing['price']}${listing['priceUnit'] == 'month' ? '/month' : ''}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.square_foot, 'Area', listing['area']),
                  _buildDetailRow(Icons.location_on, 'Location', listing['location']),
                  _buildDetailRow(Icons.category, 'Type', listing['type']),
                  Builder(builder: (ctx) {
                    final isLoggedIn = Provider.of<AuthProvider>(ctx, listen: false).isAuthenticated;
                    if (isLoggedIn) {
                      return _buildDetailRow(Icons.person, 'Posted by', listing['postedBy']);
                    }
                    return Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        const Text('Posted by  ', style: TextStyle(fontSize: 15, color: Colors.black87)),
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: _nameBlurFilter,
                            child: Text(listing['postedBy'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(listing['description'], style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 30),
                  Builder(builder: (ctx) {
                    final isLoggedIn = Provider.of<AuthProvider>(ctx, listen: false).isAuthenticated;
                    return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!isLoggedIn) {
                              context.go('/login');
                              return;
                            }
                            final phone = listing['phone']?.toString() ?? '';
                            if (phone.isNotEmpty) {
                              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                              final uri = Uri.parse('tel:$cleanPhone');
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open phone dialer')),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(isLoggedIn ? Icons.call : Icons.login),
                          label: Text(isLoggedIn ? 'Call' : 'Login to Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VillageTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (!isLoggedIn) {
                              context.go('/login');
                              return;
                            }
                            final phone = listing['phone']?.toString() ?? '';
                            if (phone.isNotEmpty) {
                              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                              final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                              final message = Uri.encodeComponent('Hi, I am interested in the property: ${listing['title']}');
                              final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp')),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(isLoggedIn ? Icons.chat : Icons.login),
                          label: Text(isLoggedIn ? 'WhatsApp' : 'Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VillageTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: VillageTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Post Property Bottom Sheet ───

class _PostPropertySheet extends StatefulWidget {
  const _PostPropertySheet();

  @override
  State<_PostPropertySheet> createState() => _PostPropertySheetState();
}

class _PostPropertySheetState extends State<_PostPropertySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  String _propertyType = 'Land';
  String _listingType = 'For Sale';
  final List<XFile> _images = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final RealEstateService _realEstateService = RealEstateService();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final toAdd = images.take(5 - _images.length).toList();
      final compressed = await ImageCompressor.compressMultiple(toAdd);
      setState(() {
        _images.addAll(compressed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VillageTheme.primaryGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Post Property',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Property Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Land', 'House', 'Apartment', 'Commercial'].map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          selected: _propertyType == type,
                          onSelected: (selected) {
                            setState(() => _propertyType = type);
                          },
                          selectedColor: VillageTheme.primaryGreen.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Listing Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['For Sale', 'For Rent'].map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: _listingType == type,
                            onSelected: (selected) {
                              setState(() => _listingType = type);
                            },
                            selectedColor: _listingType == 'For Sale'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / தலைப்பு *',
                        hintText: 'e.g., Sofa for Sale / சோபா விற்பனைக்கு',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price *',
                              prefixText: '₹ ',
                              suffixText: _listingType == 'For Rent' ? '/month' : '',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Area *',
                              hintText: 'e.g., 1200 sq.ft',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'e.g., Thiruvannamalai',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your property...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text('Photos (up to 5)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.map((img) => _buildImageTile(img)),
                          if (_images.length < 5)
                            _buildAddMediaTile(Icons.add_photo_alternate, 'Add Photos', _pickImages),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VillageTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('Post Property', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(XFile image) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(File(image.path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => setState(() => _images.remove(image)),
        ),
      ),
    );
  }

  Widget _buildAddMediaTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      try {
        final areaStr = _areaController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final areaSqft = int.tryParse(areaStr);

        final result = await _realEstateService.createPost(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          propertyType: _propertyType,
          listingType: _listingType,
          price: double.tryParse(_priceController.text.replaceAll(',', '')),
          areaSqft: areaSqft,
          bedrooms: int.tryParse(_bedroomsController.text),
          bathrooms: int.tryParse(_bathroomsController.text),
          location: _locationController.text.trim(),
          phone: _phoneController.text.trim(),
          imagePaths: _images.map((img) => img.path).toList(),
        );

        setState(() => _isSubmitting = false);

        if (result['success'] == true) {
          if (mounted) {
            _showPropertySuccessDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to post property'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPropertySuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: VillageTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            const Text('Property Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your property is submitted for approval. It will be visible to others once admin approves it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, 'success'); // Close bottom sheet
      }
    });
  }
}

// ─── Image Carousel Widget ───

class _ImageCarouselWidget extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;

  const _ImageCarouselWidget({
    required this.imageUrls,
    required this.height,
    required this.borderRadius,
    required this.fallbackIcon,
  });

  @override
  State<_ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<_ImageCarouselWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Center(child: Icon(widget.fallbackIcon, size: 64, color: Colors.grey[500]));
    }

    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openFullScreen(0),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.network(
            widget.imageUrls.first,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(widget.fallbackIcon, size: 64, color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreen(_currentIndex),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: Image.network(
                    widget.imageUrls[index],
                    height: widget.height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(widget.fallbackIcon, size: 64, color: Colors.grey[500]),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                return Container(
                  width: _currentIndex == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(imageUrls: widget.imageUrls, initialIndex: index),
      ),
    );
  }
}

// ─── Full Screen Gallery ───

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenGallery({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentIndex == index ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              widget.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.broken_image, size: 20, color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Marketplace Post Details Bottom Sheet ───

class MarketplacePostDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const MarketplacePostDetailsSheet({super.key, required this.post});

  @override
  State<MarketplacePostDetailsSheet> createState() => _MarketplacePostDetailsSheetState();
}

class _MarketplacePostDetailsSheetState extends State<MarketplacePostDetailsSheet> {
  Map<String, dynamic> get post => widget.post;

  String _getImageUrl() {
    final imageUrl = post['imageUrl'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return ImageUrlHelper.getFullImageUrl(imageUrl.toString());
    }
    return '';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    if (numPrice >= 100000) {
      return '\u20B9${(numPrice / 100000).toStringAsFixed(1)}L';
    } else if (numPrice >= 1000) {
      return '\u20B9${(numPrice / 1000).toStringAsFixed(numPrice % 1000 == 0 ? 0 : 1)}K';
    }
    return '\u20B9${numPrice.toStringAsFixed(0)}';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MarketplaceFullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final isSold = post['status'] == 'SOLD';
    print('DEBUG MarketplacePostDetailsSheet post keys: ${post.keys.toList()}');
    print('DEBUG sellerPhone: "${post['sellerPhone']}"');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (imageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _openFullScreenImage(context, imageUrl),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey[500])),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          if (isSold)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('SOLD OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Icon(Icons.storefront, size: 80, color: Colors.grey[400])),
                    ),
                  const SizedBox(height: 20),
                  // Title and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (post['price'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatPrice(post['price']),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Detail rows
                  if (post['category'] != null)
                    _buildDetailRow(Icons.category, 'Category', post['category']),
                  if (post['sellerName'] != null)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final sellerName = post['sellerName'] ?? 'Seller';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('Seller: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                            Expanded(
                              child: isLoggedIn
                                  ? Text(sellerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                                  : ClipRect(
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Text(sellerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (post['sellerPhone'] != null && post['sellerPhone'].toString().isNotEmpty)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final phone = post['sellerPhone'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('Phone: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                            Expanded(
                              child: isLoggedIn
                                  ? Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                                  : ClipRect(
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (post['location'] != null && post['location'].toString().isNotEmpty)
                    _buildDetailRow(Icons.location_on, 'Location', post['location']),
                  if (post['createdAt'] != null)
                    _buildDetailRow(Icons.access_time, 'Posted', _formatDate(post['createdAt'])),
                  // Description
                  if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      post['description'],
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 30),
                  // Contact buttons
                  if (!isSold)
                    Builder(builder: (ctx) {
                      final isLoggedIn = Provider.of<AuthProvider>(ctx, listen: false).isAuthenticated;
                      return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (!isLoggedIn) {
                                Navigator.of(context).pop();
                                GoRouter.of(context).go('/login');
                                return;
                              }
                              final phone = post['sellerPhone']?.toString() ?? '';
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number not available')),
                                );
                                return;
                              }
                              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                              final uri = Uri.parse('tel:$cleanPhone');
                              launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open phone dialer')),
                                  );
                                }
                                return false;
                              });
                            },
                            icon: Icon(isLoggedIn ? Icons.call : Icons.login),
                            label: Text(isLoggedIn ? 'Call' : 'Login to Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VillageTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (!isLoggedIn) {
                                Navigator.of(context).pop();
                                GoRouter.of(context).go('/login');
                                return;
                              }
                              final phone = post['sellerPhone']?.toString() ?? '';
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number not available')),
                                );
                                return;
                              }
                              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                              final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                              final message = Uri.encodeComponent('Hi, I am interested in: ${post['title']}');
                              final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
                              launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp')),
                                  );
                                }
                                return false;
                              });
                            },
                            icon: Icon(isLoggedIn ? Icons.chat : Icons.login),
                            label: Text(isLoggedIn ? 'WhatsApp' : 'Login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VillageTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: VillageTheme.primaryGreen),
                            ),
                          ),
                        ),
                      ],
                    );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─── Marketplace Full Screen Image Viewer ───

class _MarketplaceFullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _MarketplaceFullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Image', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('Failed to load image', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
