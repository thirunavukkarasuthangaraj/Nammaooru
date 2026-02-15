import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/village_theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/config/env_config.dart';
import '../services/real_estate_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For Sale', 'For Rent', 'Land', 'House', 'Apartment'];

  final RealEstateService _realEstateService = RealEstateService();
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchListings();
    _scrollController.addListener(_onScroll);
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
        onPressed: () => _showPostPropertySheet(),
        backgroundColor: VillageTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      _fetchListings(refresh: true);
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
          child: _isLoading && _listings.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _listings.isEmpty
                  ? _buildErrorState()
                  : _filteredListings.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _fetchListings(refresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredListings.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredListings.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _buildPropertyCard(_filteredListings[index]);
                            },
                          ),
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

    return RefreshIndicator(
      onRefresh: () async {
        _myPostsLoaded = false;
        await _fetchMyPosts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myPosts.length,
        itemBuilder: (context, index) {
          final post = _myPosts[index];
          final status = post['status'] ?? 'PENDING_APPROVAL';
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

  Widget _buildSavedTab() {
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
                icon: const Icon(Icons.favorite_border, size: 18),
                color: Colors.grey[600],
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to favorites')),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final phone = listing['phone']?.toString() ?? '';
                            if (phone.isNotEmpty) {
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
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
                          onPressed: () async {
                            final phone = listing['phone']?.toString() ?? '';
                            if (phone.isNotEmpty) {
                              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                              final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                              final message = Uri.encodeComponent('Hi, I am interested in the property: ${listing['title']}');
                              final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
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
                  ),
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
      setState(() {
        _images.addAll(images.take(5 - _images.length));
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

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g., 2 BHK House for Sale',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'e.g., Thiruvannamalai',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
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
                          if (_images.length < 5)
                            _buildAddMediaTile(Icons.add_photo_alternate, 'Add Photos', _pickImages),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
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
        );

        setState(() => _isSubmitting = false);

        if (result['success'] == true) {
          if (mounted) {
            _showPropertySuccessDialog();
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
