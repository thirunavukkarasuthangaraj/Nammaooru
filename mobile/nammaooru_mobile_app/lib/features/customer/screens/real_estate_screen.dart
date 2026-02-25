import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/utils/image_compressor.dart';
import '../services/real_estate_service.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/post_payment_handler.dart';
import '../../../shared/widgets/post_filter_bar.dart';
import '../../../core/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For Sale', 'For Rent', 'Land', 'House', 'Apartment', 'Agriculture'];

  final RealEstateService _realEstateService = RealEstateService();
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _searchText = '';

  double _selectedRadius = 50.0;
  double? _userLatitude;
  double? _userLongitude;

  // Saved/favorites
  Set<int> _savedIds = {};
  List<Map<String, dynamic>> _savedListings = [];
  bool _isSavedLoading = false;
  static const String _savedPrefsKey = 'real_estate_saved_ids';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _savedListings.isEmpty && _savedIds.isNotEmpty) {
        _fetchSavedListings();
      }
    });
    _loadSavedIds();
    _loadLocation();
    _fetchListings();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await LocationService.instance.getCurrentPosition();
      if (loc != null && mounted) {
        setState(() {
          _userLatitude = loc.latitude;
          _userLongitude = loc.longitude;
        });
      }
    } catch (_) {}
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
        _loadMore();
      }
    }
  }

  Future<void> _fetchListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _listings = [];
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? propertyType;
      String? listingType;

      if (_selectedFilter == 'For Sale') {
        listingType = 'FOR_SALE';
      } else if (_selectedFilter == 'For Rent') {
        listingType = 'FOR_RENT';
      } else if (_selectedFilter != 'All') {
        propertyType = _selectedFilter.toUpperCase();
      }

      final response = await _realEstateService.getApprovedPosts(
        page: _currentPage,
        size: 20,
        propertyType: propertyType,
        listingType: listingType,
        search: _searchText.isNotEmpty ? _searchText : null,
      );

      if (response['success'] == true || response['data'] != null) {
        final content = response['data']?['content'] as List? ?? [];
        final newListings = content.map<Map<String, dynamic>>((item) => _mapApiToLocal(item)).toList();

        setState(() {
          if (refresh || _currentPage == 0) {
            _listings = newListings;
          } else {
            _listings.addAll(newListings);
          }
          _hasMore = newListings.length >= 20;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch listings');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _fetchListings();
  }

  Future<void> _loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_savedPrefsKey) ?? [];
    setState(() {
      _savedIds = ids.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
    });
  }

  Future<void> _saveSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedPrefsKey, _savedIds.map((e) => e.toString()).toList());
  }

  void _toggleSaved(int postId) {
    setState(() {
      if (_savedIds.contains(postId)) {
        _savedIds.remove(postId);
        _savedListings.removeWhere((l) => l['id'] == postId);
      } else {
        _savedIds.add(postId);
        // Add from browse listings if available
        final listing = _listings.firstWhere((l) => l['id'] == postId, orElse: () => <String, dynamic>{});
        if (listing.isNotEmpty) {
          _savedListings.add(listing);
        }
      }
    });
    _saveSavedIds();
  }

  bool _isSaved(int postId) => _savedIds.contains(postId);

  Future<void> _fetchSavedListings() async {
    if (_savedIds.isEmpty) return;
    setState(() => _isSavedLoading = true);
    try {
      final List<Map<String, dynamic>> results = [];
      for (final id in _savedIds) {
        try {
          final response = await _realEstateService.getPostById(id);
          if (response['success'] == true && response['data'] != null) {
            results.add(_mapApiToLocal(response['data']));
          }
        } catch (_) {
          // Post may have been deleted, skip
        }
      }
      setState(() {
        _savedListings = results;
        _isSavedLoading = false;
      });
    } catch (e) {
      setState(() => _isSavedLoading = false);
    }
  }

  Map<String, dynamic> _mapApiToLocal(Map<String, dynamic> api) {
    final listingType = api['listingType']?.toString() ?? 'FOR_SALE';
    final propertyType = api['propertyType']?.toString() ?? 'LAND';

    return {
      'id': api['id'],
      'title': api['title'] ?? '',
      'type': _formatPropertyType(propertyType),
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
      'featured': api['featured'] ?? api['isFeatured'] ?? false,
      'imageUrls': api['imageUrls'] ?? '',
    };
  }

  String _formatPropertyType(String type) {
    switch (type.toUpperCase()) {
      case 'LAND':
        return 'Land';
      case 'HOUSE':
        return 'House';
      case 'APARTMENT':
        return 'Apartment';
      case 'VILLA':
        return 'Villa';
      case 'COMMERCIAL':
        return 'Commercial';
      case 'PLOT':
        return 'Plot';
      case 'FARM_LAND':
        return 'Farm Land';
      case 'PG_HOSTEL':
        return 'PG/Hostel';
      default:
        return type;
    }
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    return ImageUrlHelper.getFullImageUrl(path.trim());
  }

  List<String> _getImageUrls(Map<String, dynamic> listing) {
    final images = listing['images'];
    if (images == null) return [];
    if (images is List) {
      return images.where((img) => img != null && img.toString().trim().isNotEmpty)
          .map<String>((img) => _getFullImageUrl(img.toString().trim()))
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _filteredListings {
    return _listings; // Already filtered from API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Real Estate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Browse'),
            Tab(icon: Icon(Icons.history), text: 'My Posts'),
            Tab(icon: Icon(Icons.favorite_border), text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyPostsTab(),
          _buildSavedTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            GoRouter.of(context).go('/login');
            return;
          }
          _showPostPropertySheet();
        },
        backgroundColor: VillageTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  List<Map<String, dynamic>> _buildCarouselPosts() {
    return _listings
        .where((post) => post['featured'] == true || post['isFeatured'] == true)
        .take(8)
        .toList();
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        PostFilterBar(
          categories: _filters,
          selectedCategory: _selectedFilter,
          onCategoryChanged: (cat) {
            setState(() => _selectedFilter = cat ?? 'All');
            _fetchListings(refresh: true);
          },
          selectedRadius: _selectedRadius,
          onRadiusChanged: (radius) {
            setState(() => _selectedRadius = radius ?? 50.0);
            _fetchListings(refresh: true);
          },
          searchText: _searchText,
          onSearchSubmitted: (text) {
            setState(() => _searchText = text);
            _fetchListings(refresh: true);
          },
          accentColor: const Color(0xFF5C6BC0),
        ),
        // Listings
        Expanded(
          child: _isLoading && _listings.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _listings.isEmpty
                  ? _buildErrorState()
                  : _filteredListings.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _fetchListings(refresh: true),
                          child: Builder(builder: (context) {
                            final carouselPosts = _buildCarouselPosts();
                            final hasCarousel = carouselPosts.isNotEmpty;
                            final offset = hasCarousel ? 1 : 0;
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredListings.length + offset + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (hasCarousel && index == 0) {
                                  return _FeaturedBannerCarousel(
                                    posts: carouselPosts,
                                    onPostTap: (post) => _showPropertyDetails(post),
                                    accentColor: const Color(0xFFAD1457),
                                  );
                                }
                                final listIndex = index - offset;
                                if (listIndex == _filteredListings.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return _buildPropertyCard(_filteredListings[listIndex]);
                              },
                            );
                          }),
                        ),
        ),
      ],
    );
  }

  // My Posts state
  List<Map<String, dynamic>> _myPosts = [];
  bool _myPostsLoading = false;
  String? _myPostsError;
  bool _myPostsLoaded = false;
  Set<int> _selectedForRenewal = {};
  bool _isRenewing = false;

  Future<void> _fetchMyPosts() async {
    setState(() {
      _myPostsLoading = true;
      _myPostsError = null;
    });

    try {
      final response = await _realEstateService.getMyPosts();

      if (response['success'] == true || response['data'] != null) {
        final data = response['data'];
        List content;
        if (data is List) {
          content = data;
        } else if (data is Map && data['content'] is List) {
          content = data['content'] as List;
        } else {
          content = [];
        }
        final posts = content.map<Map<String, dynamic>>((item) {
          final mapped = _mapApiToLocal(item as Map<String, dynamic>);
          mapped['status'] = item['status'] ?? 'PENDING_APPROVAL';
          mapped['validFrom'] = item['validFrom'];
          mapped['validTo'] = item['validTo'];
          return mapped;
        }).toList();

        setState(() {
          _myPosts = posts;
          _myPostsLoading = false;
          _myPostsLoaded = true;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch my posts');
      }
    } catch (e) {
      setState(() {
        _myPostsLoading = false;
        _myPostsError = e.toString();
        _myPostsLoaded = true;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending Approval';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Sold';
      case 'RENTED': return 'Rented';
      case 'FLAGGED': return 'Flagged';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING_APPROVAL': return Colors.orange;
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'SOLD': return Colors.purple;
      case 'RENTED': return Colors.teal;
      case 'FLAGGED': return Colors.red[800]!;
      case 'HOLD': return Colors.amber.shade700;
      case 'HIDDEN': return Colors.grey;
      case 'CORRECTION_REQUIRED': return Colors.deepOrange;
      case 'REMOVED': return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  Widget _buildMyPostsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Login to view your posts', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen),
            ),
          ],
        ),
      );
    }
    if (!_myPostsLoaded) {
      _fetchMyPosts();
    }

    if (_myPostsLoading && _myPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPostsError != null && _myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Failed to load your posts', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(_myPostsError ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _myPostsLoaded = false;
                _fetchMyPosts();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Your property listings will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    final expiredPostIds = _myPosts.where((p) {
      final vTo = p['validTo'] != null ? DateTime.tryParse(p['validTo'].toString()) : null;
      if (vTo == null) return false;
      final now = DateTime.now();
      return vTo.isBefore(now) || (vTo.isAfter(now) && vTo.difference(now).inDays <= 3);
    }).map((p) => p['id'] as int).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _myPostsLoaded = false;
        await _fetchMyPosts();
      },
      child: Column(
        children: [
          if (expiredPostIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedForRenewal.length == expiredPostIds.length && expiredPostIds.isNotEmpty,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedForRenewal = expiredPostIds.toSet();
                          } else {
                            _selectedForRenewal.clear();
                          }
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Select All (${expiredPostIds.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  if (_selectedForRenewal.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isRenewing ? null : _renewSelectedPosts,
                      icon: _isRenewing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text('Renew All (${_selectedForRenewal.length})'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myPosts.length,
        itemBuilder: (context, index) {
          final post = _myPosts[index];
          final status = post['status'] ?? 'PENDING_APPROVAL';
          // Validity dates and expiry status
          final validFrom = post['validFrom'] != null ? DateTime.tryParse(post['validFrom'].toString()) : null;
          final validTo = post['validTo'] != null ? DateTime.tryParse(post['validTo'].toString()) : null;
          final now = DateTime.now();
          final bool isExpiringSoon = validTo != null && validTo.isAfter(now) && validTo.difference(now).inDays <= 3;
          final bool isExpired = validTo != null && validTo.isBefore(now);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => _showPropertyDetails(post),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Validity & expiry info
                    if (validTo != null) ...[
                      const SizedBox(height: 6),
                      Row(
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
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(post['type'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post['location'] ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_formatPrice(post['price'] ?? 0)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen),
                        ),
                        Text(
                          _formatDate(post['postedDate'] ?? DateTime.now()),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
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
                    // Action buttons: Mark Sold/Rented, Delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'APPROVED') ...[
                          _buildActionChip('Mark Sold', Icons.sell, Colors.purple, () => _markAsSold(post)),
                          const SizedBox(width: 8),
                          _buildActionChip('Mark Rented', Icons.home, Colors.teal, () => _markAsRented(post)),
                          const SizedBox(width: 8),
                        ],
                        _buildActionChip('Edit', Icons.edit, Colors.blue, () => _showEditRealEstateSheet(post)),
                        const SizedBox(width: 8),
                        _buildActionChip('Delete', Icons.delete, Colors.red, () => _deleteMyPost(post)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsSold(Map<String, dynamic> post) async {
    final postId = post['id'];
    if (postId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Sold'),
        content: Text('Mark "${post['title']}" as sold?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark Sold')),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _realEstateService.markAsSold(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Updated'), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
        );
        if (result['success'] == true) { _myPostsLoaded = false; _fetchMyPosts(); }
      }
    }
  }

  Future<void> _markAsRented(Map<String, dynamic> post) async {
    final postId = post['id'];
    if (postId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Rented'),
        content: Text('Mark "${post['title']}" as rented?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark Rented')),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _realEstateService.markAsRented(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Updated'), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
        );
        if (result['success'] == true) { _myPostsLoaded = false; _fetchMyPosts(); }
      }
    }
  }

  Future<void> _deleteMyPost(Map<String, dynamic> post) async {
    final postId = post['id'];
    if (postId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Delete "${post['title']}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _realEstateService.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Deleted'), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
        );
        if (result['success'] == true) { _myPostsLoaded = false; _fetchMyPosts(); }
      }
    }
  }

  void _showEditRealEstateSheet(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
    final priceController = TextEditingController(text: post['price']?.toString() ?? '');
    final phoneController = TextEditingController(text: post['ownerPhone'] ?? '');
    final locationController = TextEditingController(text: post['location'] ?? '');
    final areaController = TextEditingController(text: post['areaSqft']?.toString() ?? '');
    final bedroomsController = TextEditingController(text: post['bedrooms']?.toString() ?? '');
    final bathroomsController = TextEditingController(text: post['bathrooms']?.toString() ?? '');
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
                    const Text('Edit Property', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title', border: const OutlineInputBorder(), suffixIcon: VoiceInputButton(controller: titleController))),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: InputDecoration(labelText: 'Description', border: const OutlineInputBorder(), suffixIcon: VoiceInputButton(controller: descController)), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location', border: const OutlineInputBorder(), suffixIcon: VoiceInputButton(controller: locationController))),
                const SizedBox(height: 12),
                TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Area (sq.ft)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: bedroomsController, decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: bathroomsController, decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()), keyboardType: TextInputType.number),
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
                      if (phoneController.text != (post['ownerPhone'] ?? '')) updates['phone'] = phoneController.text;
                      if (locationController.text != (post['location'] ?? '')) updates['location'] = locationController.text;
                      if (areaController.text != (post['areaSqft']?.toString() ?? '')) {
                        updates['areaSqft'] = int.tryParse(areaController.text);
                      }
                      if (bedroomsController.text != (post['bedrooms']?.toString() ?? '')) {
                        updates['bedrooms'] = int.tryParse(bedroomsController.text);
                      }
                      if (bathroomsController.text != (post['bathrooms']?.toString() ?? '')) {
                        updates['bathrooms'] = int.tryParse(bathroomsController.text);
                      }
                      if (updates.isEmpty) { Navigator.pop(ctx); return; }
                      final result = await _realEstateService.editPost(post['id'], updates);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) { _myPostsLoaded = false; _fetchMyPosts(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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

  void _renewSinglePost(int postId) async {
    final result = await _realEstateService.renewPost(postId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
      );
      if (result['success'] == true) {
        setState(() { _myPostsLoaded = false; _selectedForRenewal.remove(postId); });
        _fetchMyPosts();
      }
    }
  }

  void _renewSelectedPosts() async {
    if (_selectedForRenewal.isEmpty) return;
    final selectedIds = _selectedForRenewal.toList();
    final count = selectedIds.length;

    setState(() => _isRenewing = true);
    int successCount = 0;
    for (final id in selectedIds) {
      final result = await _realEstateService.renewPost(id);
      if (result['success'] == true) successCount++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount of $count posts renewed successfully'), backgroundColor: successCount > 0 ? Colors.green : Colors.red),
      );
      setState(() { _isRenewing = false; _selectedForRenewal.clear(); _myPostsLoaded = false; });
      _fetchMyPosts();
    }
  }

  Widget _buildSavedTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Login to view saved properties', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen),
            ),
          ],
        ),
      );
    }
    if (_isSavedLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_savedIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No saved properties',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon to save properties',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    if (_savedListings.isEmpty && _savedIds.isNotEmpty) {
      _fetchSavedListings();
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _fetchSavedListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedListings.length,
        itemBuilder: (context, index) {
          return _buildPropertyCard(_savedListings[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post a property!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load properties',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An error occurred',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _fetchListings(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VillageTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (listing['titleTamil'] != null)
                              Text(
                                listing['titleTamil'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_formatPrice(listing['price'])}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                            ),
                          ),
                          if (listing['priceUnit'] == 'month')
                            Text(
                              '/month',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Posted by ${listing['postedBy']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDate(listing['postedDate']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(Map<String, dynamic> listing, bool isForSale) {
    final imageUrls = _getImageUrls(listing);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          // Image carousel or placeholder
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
          // Save button
          Positioned(
            bottom: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: IconButton(
                icon: Icon(
                  _isSaved(listing['id']) ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                color: _isSaved(listing['id']) ? Colors.red : Colors.grey[600],
                onPressed: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  if (!auth.isAuthenticated) {
                    GoRouter.of(context).go('/login');
                    return;
                  }
                  _toggleSaved(listing['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isSaved(listing['id']) ? 'Saved to favorites' : 'Removed from favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
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

  String _formatPrice(int price) {
    if (price >= 10000000) {
      return '${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(2)} L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} K';
    }
    return price.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPropertyDetails(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertyDetailsSheet(listing: listing),
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
      // Refresh listings and my posts
      _currentPage = 0;
      _listings.clear();
      _hasMore = true;
      _fetchListings();
      _myPostsLoaded = false;
      _fetchMyPosts();
      // Switch to My Posts tab
      _tabController.animateTo(1);
    }
  }
}

class PropertyDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> listing;

  const PropertyDetailsSheet({super.key, required this.listing});

  @override
  State<PropertyDetailsSheet> createState() => _PropertyDetailsSheetState();
}

class _PropertyDetailsSheetState extends State<PropertyDetailsSheet> {
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
        // Main image with PageView
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
                // Image counter
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
                // Tap to expand hint
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
        // Page indicators
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
        ],
        // Thumbnail strip
        if (imageUrls.length > 1) ...[
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
                  // Property images gallery
                  _buildDetailGallery(context),
                  const SizedBox(height: 20),
                  // Title and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (listing['titleTamil'] != null)
                              Text(
                                listing['titleTamil'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: listing['listingType'] == 'For Sale'
                              ? Colors.green
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          listing['listingType'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${listing['price']}${listing['priceUnit'] == 'month' ? '/month' : ''}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Details
                  _buildDetailRow(Icons.square_foot, 'Area', listing['area']),
                  _buildDetailRow(Icons.location_on, 'Location', listing['location']),
                  _buildDetailRow(Icons.category, 'Type', listing['type']),
                  _buildDetailRow(Icons.person, 'Posted by', listing['postedBy']),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing['description'],
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  // Contact buttons
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
                            final phone = listing['phone']?.toString() ?? '';
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            final phone = listing['phone']?.toString() ?? '';
                            if (phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Phone number not available')),
                              );
                              return;
                            }
                            final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                            final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                            final message = Uri.encodeComponent('Hi, I am interested in the property: ${listing['title']}');
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
          Text(
            '$label: ',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

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
  XFile? _video;
  bool _isSubmitting = false;
  int? _paidTokenId;

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
    final remaining = 5 - _images.length;
    if (remaining <= 0) return;

    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final toAdd = images.take(remaining).toList();
      // Compress images before adding
      final compressed = await ImageCompressor.compressMultiple(toAdd);
      setState(() {
        _images.addAll(compressed);
      });
    }
  }

  Future<void> _captureImage() async {
    if (_images.length >= 5) return;

    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final compressed = await ImageCompressor.compressXFile(image);
      setState(() {
        _images.add(compressed);
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _video = video;
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
          // Header
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Type
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

                    // Listing Type
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

                    // Title (English or Tamil)
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title / தலைப்பு *',
                        hintText: 'e.g., 2 BHK House for Sale / 2 BHK வீடு விற்பனைக்கு',
                        border: const OutlineInputBorder(),
                        suffixIcon: VoiceInputButton(controller: _titleController),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (v!.trim().split(RegExp(r'\s+')).length > 3) return 'Title max 3 words / தலைப்பு அதிகபட்சம் 3 வார்த்தைகள்';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Area
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

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location *',
                        hintText: 'e.g., Thiruvannamalai',
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                        suffixIcon: VoiceInputButton(controller: _locationController),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your property...',
                        border: const OutlineInputBorder(),
                        suffixIcon: VoiceInputButton(controller: _descriptionController),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
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

                    // Images
                    const Text('Photos (up to 5)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.map((img) => _buildImageTile(img)),
                          if (_images.length < 5) ...[
                            _buildAddMediaTile(Icons.add_photo_alternate, 'Gallery', _pickImages),
                            _buildAddMediaTile(Icons.camera_alt, 'Camera', _captureImage),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Video
                    const Text('Video (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: _video != null
                          ? _buildVideoTile()
                          : _buildAddMediaTile(Icons.videocam, 'Add Video', _pickVideo),
                    ),
                    const SizedBox(height: 30),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VillageTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Post Property',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildVideoTile() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.play_circle, size: 40, color: Colors.white)),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _video = null),
            ),
          ),
        ],
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

  Future<void> _submitForm({int? paidTokenId}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final tokenToUse = paidTokenId ?? _paidTokenId;

    setState(() => _isSubmitting = true);

    try {
      // Parse area to integer (remove non-numeric characters)
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
        videoPath: _video?.path,
        paidTokenId: tokenToUse,
      );

      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        _paidTokenId = null;
        if (mounted) {
          _showPropertySuccessDialog();
        }
      } else if (PostPaymentHandler.isLimitReached(result)) {
        if (mounted) {
          _handleLimitReached();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to post property'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLimitReached() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'REAL_ESTATE',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId;
        _submitForm(paidTokenId: tokenId);
      },
      onPaymentCancelled: () { if (mounted) setState(() { _isSubmitting = false; }); },
    );
    handler.startPayment();
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
            const Text(
              'Property Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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

    // Auto-close after 3 seconds and go back
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, 'success'); // Close bottom sheet (triggers refresh)
      }
    });
  }
}

// Reusable image carousel for property cards
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
          // Page indicator dots
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

// Full-screen image gallery viewer
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
          // Main image
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
          // Thumbnail strip at bottom
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

// ─── Featured Banner Carousel (Real Estate) ───

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
    // Try imageUrls (raw API string), then images (parsed list)
    final rawUrls = post['imageUrls'];
    if (rawUrls is String && rawUrls.isNotEmpty) {
      return rawUrls.split(',').where((s) => s.trim().isNotEmpty).toList();
    }
    final images = post['images'];
    if (images is List) {
      return images.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
          child: Row(
            children: [
              Icon(Icons.star, color: widget.accentColor, size: 20),
              const SizedBox(width: 6),
              Text(
                'Featured Properties',
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
              final firstImage = imageUrls.isNotEmpty ? imageUrls.first.trim() : null;
              final fullImageUrl = firstImage != null && firstImage.isNotEmpty
                  ? ImageUrlHelper.getFullImageUrl(firstImage)
                  : null;

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
                        if (fullImageUrl != null)
                          CachedNetworkImage(
                            imageUrl: fullImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.home, size: 40, color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.home, size: 40, color: Colors.grey),
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
                        // Content overlay
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (post['price'] != null && post['price'] != 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '\u20B9${post['price']}${post['priceUnit'] == 'month' ? '/mo' : ''}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Listing type badge
                        if (post['listingType'] != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: post['listingType'] == 'For Sale' ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post['listingType'],
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
