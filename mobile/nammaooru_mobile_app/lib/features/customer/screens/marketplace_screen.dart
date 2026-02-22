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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_myPostsLoaded) {
        _loadMyPosts();
      }
      setState(() {}); // Update FAB icon
    });
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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
            Tab(text: '${langProvider.getText('My Posts', 'என் பதிவுகள்')}${_myPosts.isNotEmpty ? ' (${_myPosts.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Approved Marketplace Posts
          _buildMarketplaceTab(),
          // Tab 2: My Posts
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToCreatePost();
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

  // ─── Tab 2: My Posts ───

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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
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
                    if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
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
      _tabController.animateTo(1);
    });
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
